# Creates MyApp's in-app purchases from appstore/products.yml if they don't exist yet:
# the subscription group, each subscription (USA price, availability, USA introductory offer)
# and each non-consumable (localization, price schedule, availability in every territory).
# Idempotent; anything that already exists is left alone. Run apply.rb afterwards for
# localizations, review notes and equalized prices in every territory.
# Usage: ruby create_products.rb [--dry-run] [--review-shot path/to/paywall.png]
# Ruby 2.6-compatible (macOS system Ruby).
require_relative "asc_client"
require "yaml"
APP = ASC.app_id
DRY = ARGV.include?("--dry-run")
SHOT = (i = ARGV.index("--review-shot")) ? ARGV[i + 1] : nil
P = YAML.load_file(File.expand_path("../products.yml", __dir__))
L = JSON.parse(File.read(File.expand_path("../listing.json", __dir__)))
LOC = P["localizations"]["en-US"]
PERIOD = { "P1W" => "ONE_WEEK", "P1M" => "ONE_MONTH", "P2M" => "TWO_MONTHS", "P3M" => "THREE_MONTHS", "P6M" => "SIX_MONTHS", "P1Y" => "ONE_YEAR" }
OFFER = { "free_trial" => "FREE_TRIAL", "pay_as_you_go" => "PAY_AS_YOU_GO", "pay_up_front" => "PAY_UP_FRONT" }

def say(s) puts(s) end
def write(method, path, body)
  if DRY then say("DRY #{method.upcase} #{path}"); return { "data" => { "id" => "dry" } } end
  ASC.req(method, path, body, raise_on_error: true) # explicit keyword keeps Ruby 2.6 from reading body as kwargs
end
def rel(type, id) { data: { type: type, id: id } } end
def all_pages(path)
  out = []; d = ASC.get(path)
  loop { out.concat(d["data"]); nxt = d.dig("links", "next"); break unless nxt; d = ASC.get(nxt) }
  out
end
def price_point(path, price)
  all_pages(path).find { |p| p["attributes"]["customerPrice"].to_f == price.to_f } or raise "no #{price} price point at #{path}"
end

def put_chunk(op, bytes)
  uri = URI(op["url"])
  r = Net::HTTP.const_get(op["method"].capitalize).new(uri)
  (op["requestHeaders"] || []).each { |h| r[h["name"]] = h["value"] }
  r.body = bytes[op["offset"], op["length"]]
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(r) }
  raise "chunk upload #{res.code}" unless res.code.to_i < 300
end
# Review screenshot for a subscription or an in-app purchase (App Review needs one for each).
def review_shot(type, relname, reltype, id, label)
  return unless SHOT
  existing = ASC.req(:get, "/#{type == 'subscriptionAppStoreReviewScreenshots' ? 'v1/subscriptions' : 'v2/inAppPurchases'}/#{id}/appStoreReviewScreenshot", nil, raise_on_error: false)
  return say("same #{label} review screenshot") if existing && existing["data"]
  return say("DRY review screenshot #{label}") if DRY
  bytes = File.binread(SHOT)
  s = ASC.req(:post, "/v1/#{type}", { data: { type: type, attributes: { fileName: File.basename(SHOT), fileSize: bytes.bytesize },
    relationships: { relname => rel(reltype, id) } } }, raise_on_error: true)["data"]
  s["attributes"]["uploadOperations"].each { |op| put_chunk(op, bytes) }
  ASC.req(:patch, "/v1/#{type}/#{s['id']}", { data: { type: type, id: s["id"], attributes: { uploaded: true, sourceFileChecksum: Digest::MD5.hexdigest(bytes) } } }, raise_on_error: true)
  say("ok   #{label} review screenshot uploaded")
end

territories = ASC.all("/v1/territories?limit=200").map { |t| t["id"] }

# ---- Subscriptions
(P["subscription_groups"] || []).each do |g|
  groups = ASC.get("/v1/apps/#{APP}/subscriptionGroups")["data"]
  grp = groups.find { |x| x["attributes"]["referenceName"] == g["name"] }
  if grp
    say("same group #{g['name']}")
  else
    grp = write(:post, "/v1/subscriptionGroups", { data: { type: "subscriptionGroups", attributes: { referenceName: g["name"] },
      relationships: { app: rel("apps", APP) } } })["data"]
    say("ok   created group #{g['name']}")
  end
  g["products"].each_with_index do |pr, i|
    pid = pr["id"]
    subs = DRY && grp["id"] == "dry" ? [] : ASC.get("/v1/subscriptionGroups/#{grp['id']}/subscriptions")["data"]
    sub = subs.find { |s| s["attributes"]["productId"] == pid }
    if sub
      say("same subscription #{pid}")
    else
      note = (L.dig("subscriptions", pid, "reviewNote") || "")
      sub = write(:post, "/v1/subscriptions", { data: { type: "subscriptions", attributes: {
        name: LOC[pid]["name"], productId: pid, subscriptionPeriod: PERIOD.fetch(pr["duration"]),
        familySharable: false, groupLevel: i + 1, reviewNote: note },
        relationships: { group: rel("subscriptionGroups", grp["id"]) } } })["data"]
      say("ok   created subscription #{pid}")
    end
    next if DRY && sub["id"] == "dry"
    # Availability must exist before the first price.
    av = ASC.req(:get, "/v1/subscriptions/#{sub['id']}/subscriptionAvailability", nil, raise_on_error: false)
    unless av && av["data"]
      write(:post, "/v1/subscriptionAvailabilities", { data: { type: "subscriptionAvailabilities", attributes: { availableInNewTerritories: true },
        relationships: { subscription: rel("subscriptions", sub["id"]), availableTerritories: { data: [{ type: "territories", id: "USA" }] } } } })
      say("ok   #{pid} available in USA (apply.rb extends it everywhere)")
    end
    prices = ASC.get("/v1/subscriptions/#{sub['id']}/prices?include=territory&limit=200")["data"]
    if prices.any? { |x| x.dig("relationships", "territory", "data", "id") == "USA" }
      say("same #{pid} USA price")
    else
      pp = price_point("/v1/subscriptions/#{sub['id']}/pricePoints?filter[territory]=USA&limit=200", pr["base_price"])
      write(:post, "/v1/subscriptionPrices", { data: { type: "subscriptionPrices",
        relationships: { subscription: rel("subscriptions", sub["id"]), subscriptionPricePoint: rel("subscriptionPricePoints", pp["id"]),
          territory: rel("territories", "USA") } } })
      say("ok   #{pid} USA price $#{pr['base_price']}")
    end
    if (o = pr["introductory_offer"])
      offers = ASC.get("/v1/subscriptions/#{sub['id']}/introductoryOffers?include=territory&limit=200")["data"]
      if offers.any? { |x| x.dig("relationships", "territory", "data", "id") == "USA" }
        say("same #{pid} USA introductory offer")
      else
        write(:post, "/v1/subscriptionIntroductoryOffers", { data: { type: "subscriptionIntroductoryOffers",
          attributes: { duration: PERIOD.fetch(o["duration"]), offerMode: OFFER.fetch(o["type"]), numberOfPeriods: 1 },
          relationships: { subscription: rel("subscriptions", sub["id"]), territory: rel("territories", "USA") } } })
        say("ok   #{pid} USA introductory offer #{o['type']} #{o['duration']}")
      end
    end
    review_shot("subscriptionAppStoreReviewScreenshots", :subscription, "subscriptions", sub["id"], pid)
  end
end

# ---- Non-consumables
iaps = ASC.all("/v1/apps/#{APP}/inAppPurchasesV2?limit=200")
(P["non_consumables"] || []).each do |nc|
  pid = nc["id"]
  iap = iaps.find { |x| x["attributes"]["productId"] == pid }
  note = "<App> Pro, once: a one-time purchase that unlocks the same Pro features as the yearly plan (<the paywall list, word for word>). Buy it from the paywall, which opens from any Pro feature or Settings > <App> Pro. Restore Purchases is on the paywall. No account needed."
  if iap
    if iap["attributes"]["reviewNote"] != note
      write(:patch, "/v2/inAppPurchases/#{iap["id"]}", { data: { type: "inAppPurchases", id: iap["id"], attributes: { reviewNote: note } } })
      say("ok   updated review note for #{pid}")
    else
      say("same in-app purchase #{pid}")
    end
  else
    iap = write(:post, "/v2/inAppPurchases", { data: { type: "inAppPurchases", attributes: {
      name: LOC[pid]["name"], productId: pid, inAppPurchaseType: "NON_CONSUMABLE", reviewNote: note, familySharable: false },
      relationships: { app: rel("apps", APP) } } })["data"]
    say("ok   created in-app purchase #{pid}")
  end
  next if DRY && iap["id"] == "dry"
  locs = ASC.get("/v2/inAppPurchases/#{iap['id']}/inAppPurchaseLocalizations")["data"]
  if locs.any? { |l| l["attributes"]["locale"] == "en-US" }
    say("same #{pid} en-US localization")
  else
    write(:post, "/v1/inAppPurchaseLocalizations", { data: { type: "inAppPurchaseLocalizations",
      attributes: { locale: "en-US", name: LOC[pid]["name"], description: LOC[pid]["description"] },
      relationships: { inAppPurchaseV2: rel("inAppPurchases", iap["id"]) } } })
    say("ok   #{pid} en-US localization")
  end
  sched = ASC.req(:get, "/v2/inAppPurchases/#{iap['id']}/iapPriceSchedule", nil, raise_on_error: false)
  if sched && sched["data"]
    say("same #{pid} price schedule")
  else
    pp = price_point("/v2/inAppPurchases/#{iap['id']}/pricePoints?filter[territory]=USA&limit=200", nc["base_price"])
    write(:post, "/v1/inAppPurchasePriceSchedules", { data: { type: "inAppPurchasePriceSchedules", relationships: {
        inAppPurchase: rel("inAppPurchases", iap["id"]), baseTerritory: rel("territories", "USA"),
        manualPrices: { data: [{ type: "inAppPurchasePrices", id: "${p1}" }] } } },
      included: [{ type: "inAppPurchasePrices", id: "${p1}", attributes: { startDate: nil },
        relationships: { inAppPurchasePricePoint: rel("inAppPurchasePricePoints", pp["id"]) } }] })
    say("ok   #{pid} price $#{nc['base_price']} (USA base, equalized everywhere)")
  end
  av = ASC.req(:get, "/v2/inAppPurchases/#{iap['id']}/inAppPurchaseAvailability", nil, raise_on_error: false)
  if av && av["data"]
    say("same #{pid} availability")
  else
    write(:post, "/v1/inAppPurchaseAvailabilities", { data: { type: "inAppPurchaseAvailabilities", attributes: { availableInNewTerritories: true },
      relationships: { inAppPurchase: rel("inAppPurchases", iap["id"]),
        availableTerritories: { data: territories.map { |t| { type: "territories", id: t } } } } } })
    say("ok   #{pid} available in #{territories.size} territories")
  end
  review_shot("inAppPurchaseAppStoreReviewScreenshots", :inAppPurchaseV2, "inAppPurchases", iap["id"], pid)
end
say("info DRY RUN, nothing written") if DRY
