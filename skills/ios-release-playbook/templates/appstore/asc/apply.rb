# Applies appstore/listing.json to App Store Connect. Idempotent; never submits for review.
# Ruby 2.6-compatible (macOS system Ruby). Usage: ruby apply.rb [--dry-run]
require_relative "asc_client"
APP = ASC.app_id
DRY = ARGV.include?("--dry-run")
L = JSON.parse(File.read(File.expand_path("../listing.json", __dir__)))
$log = []
def say(s) puts(s); $log << s end
def write(method, path, body)
  if DRY then say("DRY #{method.upcase} #{path} #{body.to_json[0, 300]}"); return nil end
  ASC.req(method, path, body, raise_on_error: true)
end
def step(name)
  yield
  say("ok   #{name}")
rescue => e
  say("FAIL #{name}: #{e.message}")
end
# PATCH a resource; if the batch fails, retry attribute-by-attribute so one bad field doesn't block the rest.
def patch_attrs(type, id, attrs, label)
  return say("same #{label}") if attrs.empty?
  begin
    write(:patch, "/v1/#{type}/#{id}", { data: { type: type, id: id, attributes: attrs } })
    say("ok   #{label}: #{attrs.keys.join(',')}")
  rescue => e
    say("warn #{label} batch failed (#{e.message[0, 200]}); retrying per attribute")
    attrs.each do |k, v|
      begin
        write(:patch, "/v1/#{type}/#{id}", { data: { type: type, id: id, attributes: { k => v } } })
        say("ok   #{label}.#{k}")
      rescue => e2
        say("FAIL #{label}.#{k}: #{e2.message[0, 300]}")
      end
    end
  end
end
def diff(current, wanted)
  out = {}
  wanted.each { |k, v| out[k] = v unless current[k] == v }
  out
end


# Price every territory at Apple's equalized equivalent of the USA price, give each the same
# free trial the USA has, then make the subscription available everywhere it has a price.
def sub_territories(sid, pid)
  prices = ASC.all("/v1/subscriptions/#{sid}/prices?include=territory,subscriptionPricePoint&limit=200")
  priced = {}
  prices.each do |pr|
    t = pr.dig("relationships", "territory", "data", "id")
    pp = pr.dig("relationships", "subscriptionPricePoint", "data", "id")
    priced[t] = pp if t
  end
  usa_pp = priced["USA"] or return say("FAIL #{pid}: no USA price to equalize from")
  eq = []
  d = ASC.get("/v1/subscriptionPricePoints/#{usa_pp}/equalizations?include=territory&limit=200")
  loop do
    eq.concat(d["data"].map { |x| [x.dig("relationships", "territory", "data", "id"), x["id"]] })
    nxt = d.dig("links", "next"); break unless nxt
    d = ASC.get(nxt)
  end
  missing = eq.reject { |t, _| t.nil? || priced.key?(t) }
  say("info #{pid}: #{priced.size} territories priced, #{missing.size} to add")
  added = 0
  missing.each do |t, ppid|
    begin
      write(:post, "/v1/subscriptionPrices", { data: { type: "subscriptionPrices", attributes: { preserveCurrentPrice: false },
        relationships: { subscription: { data: { type: "subscriptions", id: sid } },
          subscriptionPricePoint: { data: { type: "subscriptionPricePoints", id: ppid } },
          territory: { data: { type: "territories", id: t } } } } })
      priced[t] = ppid; added += 1
    rescue => e
      say("FAIL #{pid} price #{t}: #{e.message[0, 200]}")
    end
  end
  say("ok   #{pid}: added #{added} territory prices")
  # Introductory offers: copy the USA offer to every other priced territory.
  offers = ASC.all("/v1/subscriptions/#{sid}/introductoryOffers?include=territory&limit=200")
  usa = offers.find { |o| o.dig("relationships", "territory", "data", "id") == "USA" }
  if usa
    have = offers.map { |o| o.dig("relationships", "territory", "data", "id") }
    a = usa["attributes"]
    n = 0
    (priced.keys - have).each do |t|
      begin
        write(:post, "/v1/subscriptionIntroductoryOffers", { data: { type: "subscriptionIntroductoryOffers",
          attributes: { duration: a["duration"], offerMode: a["offerMode"], numberOfPeriods: a["numberOfPeriods"] },
          relationships: { subscription: { data: { type: "subscriptions", id: sid } },
            territory: { data: { type: "territories", id: t } } } } })
        n += 1
      rescue => e
        say("FAIL #{pid} intro offer #{t}: #{e.message[0, 200]}")
      end
    end
    say("ok   #{pid}: intro offer (#{a['offerMode']} #{a['duration']}) added in #{n} territories")
  else
    say("info #{pid}: no USA introductory offer")
  end
  av = ASC.req(:get, "/v1/subscriptions/#{sid}/subscriptionAvailability", nil, raise_on_error: false)
  cur = av && av["data"] ? ASC.all("/v1/subscriptionAvailabilities/#{av['data']['id']}/availableTerritories?limit=200").map { |t| t["id"] } : []
  want = (cur | priced.keys).sort
  if want.empty?
    say("FAIL #{pid}: no territories, availability left unchanged")
  elsif want.size == cur.size && av["data"]["attributes"]["availableInNewTerritories"]
    say("same #{pid} available in #{cur.size} territories")
  else
    write(:post, "/v1/subscriptionAvailabilities", { data: { type: "subscriptionAvailabilities", attributes: { availableInNewTerritories: true },
      relationships: { subscription: { data: { type: "subscriptions", id: sid } },
        availableTerritories: { data: want.map { |t| { type: "territories", id: t } } } } } })
    say("ok   #{pid} available in #{want.size} territories (was #{cur.size})")
  end
end

# ---- App
step("app") do
  a = ASC.get("/v1/apps/#{APP}")["data"]["attributes"]
  patch_attrs("apps", APP, diff(a, L["app"]), "app")
end

# ---- App info (the editable one), categories, localization, age rating
step("appInfo") do
  infos = ASC.get("/v1/apps/#{APP}/appInfos")["data"]
  info = infos.find { |i| %w[READY_FOR_DISTRIBUTION REPLACED_WITH_NEW_INFO].include?(i["attributes"]["appStoreState"]) == false } || infos.first
  iid = info["id"]
  say("appInfo #{iid} state=#{info['attributes']['appStoreState'] || info['attributes']['state']}")
  rel = {
    primaryCategory: { data: { type: "appCategories", id: L["appInfo"]["primaryCategory"] } },
    secondaryCategory: { data: { type: "appCategories", id: L["appInfo"]["secondaryCategory"] } }
  }
  write(:patch, "/v1/appInfos/#{iid}", { data: { type: "appInfos", id: iid, relationships: rel } })
  say("ok   categories")
  locs = ASC.get("/v1/appInfos/#{iid}/appInfoLocalizations")["data"]
  L["appInfoLocalization"].each do |locale, want|
    cur = locs.find { |l| l["attributes"]["locale"] == locale }
    if cur
      patch_attrs("appInfoLocalizations", cur["id"], diff(cur["attributes"], want), "appInfoLocalization #{locale}")
    else
      write(:post, "/v1/appInfoLocalizations", { data: { type: "appInfoLocalizations", attributes: want.merge("locale" => locale),
        relationships: { appInfo: { data: { type: "appInfos", id: iid } } } } })
      say("ok   created appInfoLocalization #{locale}")
    end
  end
  ar = ASC.req(:get, "/v1/appInfos/#{iid}/ageRatingDeclaration", nil, raise_on_error: false)
  if ar && ar["data"]
    patch_attrs("ageRatingDeclarations", ar["data"]["id"], diff(ar["data"]["attributes"], L["ageRating"]), "ageRating")
    after = ASC.get("/v1/appInfos/#{iid}/ageRatingDeclaration")["data"]["attributes"]
    # Follow-ups that stay empty for this app: Kids category band, the social-media age gate (asked only
    # when socialMedia is true), Korea's GRAC number (games) and an optional developer info URL.
    optional = %w[kidsAgeBand socialMediaAgeRestricted gracRatingClassificationNumber developerAgeRatingInfoUrl]
    unanswered = after.select { |k, v| v.nil? && !optional.include?(k) }.keys
    say("info ageRating unanswered after patch: #{unanswered.join(',')}") unless unanswered.empty?
  else
    say("FAIL ageRating: no declaration found")
  end
end

# ---- Version (the one being prepared)
vid = nil
step("version") do
  vers = ASC.get("/v1/apps/#{APP}/appStoreVersions?filter[platform]=IOS&limit=10")["data"]
  v = vers.find { |x| %w[PREPARE_FOR_SUBMISSION DEVELOPER_REJECTED REJECTED METADATA_REJECTED].include?(x["attributes"]["appStoreState"]) }
  raise "no editable iOS version" unless v
  vid = v["id"]
  patch_attrs("appStoreVersions", vid, diff(v["attributes"], L["version"]), "version")
  locs = ASC.get("/v1/appStoreVersions/#{vid}/appStoreVersionLocalizations")["data"]
  L["versionLocalization"].each do |locale, want|
    cur = locs.find { |l| l["attributes"]["locale"] == locale }
    if cur
      patch_attrs("appStoreVersionLocalizations", cur["id"], diff(cur["attributes"], want), "versionLocalization #{locale}")
    else
      write(:post, "/v1/appStoreVersionLocalizations", { data: { type: "appStoreVersionLocalizations", attributes: want.merge("locale" => locale),
        relationships: { appStoreVersion: { data: { type: "appStoreVersions", id: vid } } } } })
      say("ok   created versionLocalization #{locale}")
    end
  end
end

# ---- App Review details
step("reviewDetail") do
  raise "no version" unless vid
  want = L["reviewDetail"]
  cur = ASC.req(:get, "/v1/appStoreVersions/#{vid}/appStoreReviewDetail", nil, raise_on_error: false)
  if cur && cur["data"]
    a = cur["data"]["attributes"]
    # keep any contact details the owner already entered
    w = want.reject { |k, _| k.start_with?("contact") && a[k] && !a[k].to_s.empty? }
    patch_attrs("appStoreReviewDetails", cur["data"]["id"], diff(a, w), "reviewDetail")
    say("info review contact phone #{a['contactPhone'].to_s.empty? ? 'MISSING' : 'present'}")
  else
    write(:post, "/v1/appStoreReviewDetails", { data: { type: "appStoreReviewDetails", attributes: want,
      relationships: { appStoreVersion: { data: { type: "appStoreVersions", id: vid } } } } })
    say("ok   created reviewDetail (contact phone MISSING)")
  end
end

# ---- Price: free
step("price") do
  cur = ASC.req(:get, "/v1/appPriceSchedules/#{APP}/manualPrices?limit=10", nil, raise_on_error: false)
  if cur && cur["data"] && !cur["data"].empty?
    say("same price set (#{cur['data'].size} manual price(s))")
  else
    pts = ASC.get("/v1/apps/#{APP}/appPricePoints?filter[territory]=USA&limit=200")["data"]
    free = pts.find { |p| p["attributes"]["customerPrice"].to_f == 0.0 } or raise "no free price point"
    write(:post, "/v1/appPriceSchedules", {
      data: { type: "appPriceSchedules", relationships: {
        app: { data: { type: "apps", id: APP } },
        baseTerritory: { data: { type: "territories", id: "USA" } },
        manualPrices: { data: [{ type: "appPrices", id: "${p1}" }] } } },
      included: [{ type: "appPrices", id: "${p1}", attributes: { startDate: nil },
        relationships: { appPricePoint: { data: { type: "appPricePoints", id: free["id"] } } } }] })
    say("ok   price set to Free")
  end
end

# ---- Availability: every territory, plus new ones
step("availability") do
  cur = ASC.req(:get, "/v1/apps/#{APP}/appAvailabilityV2", nil, raise_on_error: false)
  if cur && cur["data"]
    say("same availability exists (#{cur['data']['id']})")
  else
    terr = ASC.all("/v1/territories?limit=200").map { |t| t["id"] }
    inc = terr.each_with_index.map { |t, i| { type: "territoryAvailabilities", id: "${t#{i}}", attributes: { available: true },
      relationships: { territory: { data: { type: "territories", id: t } } } } }
    write(:post, "/v2/appAvailabilities", {
      data: { type: "appAvailabilities", attributes: { availableInNewTerritories: true }, relationships: {
        app: { data: { type: "apps", id: APP } },
        territoryAvailabilities: { data: inc.map { |x| { type: x[:type], id: x[:id] } } } } },
      included: inc })
    say("ok   available in #{terr.size} territories")
  end
end

# ---- Subscriptions: group + per-product localizations, review notes
step("subscriptions") do
  groups = ASC.get("/v1/apps/#{APP}/subscriptionGroups")["data"]
  g = groups.find { |x| x["attributes"]["referenceName"] == L["subscriptionGroup"]["name"] } || groups.first
  raise "no subscription group" unless g
  glocs = ASC.get("/v1/subscriptionGroups/#{g['id']}/subscriptionGroupLocalizations")["data"]
  L["subscriptionGroup"]["localizations"].each do |locale, want|
    want = want.reject { |_, v| v.nil? }
    cur = glocs.find { |l| l["attributes"]["locale"] == locale }
    if cur
      patch_attrs("subscriptionGroupLocalizations", cur["id"], diff(cur["attributes"], want), "groupLocalization #{locale}")
    else
      write(:post, "/v1/subscriptionGroupLocalizations", { data: { type: "subscriptionGroupLocalizations", attributes: want.merge("locale" => locale),
        relationships: { subscriptionGroup: { data: { type: "subscriptionGroups", id: g["id"] } } } } })
      say("ok   created groupLocalization #{locale}")
    end
  end
  subs = ASC.get("/v1/subscriptionGroups/#{g['id']}/subscriptions")["data"]
  subs.each do |s|
    pid = s["attributes"]["productId"]
    want = L["subscriptions"][pid] or next
    say("info #{pid} state=#{s['attributes']['state']}")
    patch_attrs("subscriptions", s["id"], diff(s["attributes"], { "reviewNote" => want["reviewNote"] }), "sub #{pid}")
    slocs = ASC.get("/v1/subscriptions/#{s['id']}/subscriptionLocalizations")["data"]
    want["localizations"].each do |locale, w|
      cur = slocs.find { |l| l["attributes"]["locale"] == locale }
      if cur
        patch_attrs("subscriptionLocalizations", cur["id"], diff(cur["attributes"], w), "sub #{pid} #{locale}")
      else
        write(:post, "/v1/subscriptionLocalizations", { data: { type: "subscriptionLocalizations", attributes: w.merge("locale" => locale),
          relationships: { subscription: { data: { type: "subscriptions", id: s["id"] } } } } })
        say("ok   created sub #{pid} #{locale}")
      end
    end
    sub_territories(s["id"], pid)
    shot = ASC.req(:get, "/v1/subscriptions/#{s['id']}/appStoreReviewScreenshot", nil, raise_on_error: false)
    say("info #{pid} review screenshot #{shot && shot['data'] ? 'present' : 'MISSING'}")
  end
end

say("info DRY RUN, nothing written") if DRY
File.write(File.join(__dir__, "apply.log"), $log.join("\n") + "\n")
