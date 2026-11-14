# Read-only: checks that version 1.2.0 has everything App Review needs, so the only step left is Submit.
# Usage: ruby ready_check.rb    (exit 1 if anything is missing). Never submits or changes anything.
require_relative "asc_client"
APP = ASC.app_id
$fail = 0
def check(ok, label, detail = "")
  puts "#{ok ? 'PASS' : 'FAIL'} #{label}#{detail.to_s.empty? ? '' : " — #{detail}"}"
  $fail += 1 unless ok
end
v = ASC.get("/v1/apps/#{APP}/appStoreVersions?filter[platform]=IOS&filter[appStoreState]=PREPARE_FOR_SUBMISSION")["data"].first
check(!v.nil?, "editable iOS version exists", v && "#{v['attributes']['versionString']} #{v['attributes']['appStoreState']}")
exit 1 unless v
a = v["attributes"]
check(!a["copyright"].to_s.empty?, "copyright", a["copyright"])
check(a["releaseType"] == "MANUAL", "release type MANUAL", a["releaseType"])

build = ASC.get("/v1/appStoreVersions/#{v['id']}/build")["data"]
if build
  b = build["attributes"]
  check(b["processingState"] == "VALID", "build attached and processed", "build #{b['version']} #{b['processingState']} uploaded #{b['uploadedDate']}")
  check(!b["usesNonExemptEncryption"].nil?, "export compliance answered", "usesNonExemptEncryption=#{b['usesNonExemptEncryption'].inspect}")
  check(b["expired"] != true, "build not expired")
  ib = ASC.get("/v1/builds/#{build['id']}?fields[builds]=iconAssetToken,version")["data"]["attributes"]["iconAssetToken"]
  if ib && ib["templateUrl"]
    url = ib["templateUrl"].sub("{w}", "512").sub("{h}", "512").sub("{f}", "png")
    png = Net::HTTP.get_response(URI(url))
    File.binwrite("build-icon.png", png.body) if png.code == "200"
    check(png.code == "200", "build icon (App Store icon)", "saved build-icon.png from build #{b['version']}: look at it")
  else
    check(false, "build icon (App Store icon)", "no iconAssetToken yet")
  end
  tf = ASC.get("/v1/builds/#{build['id']}/betaBuildLocalizations")["data"].find { |l| l["attributes"]["locale"] == "en-US" }
  check(tf && !tf["attributes"]["whatsNew"].to_s.empty?, "TestFlight What to Test on this build")
else
  check(false, "build attached")
end

loc = ASC.get("/v1/appStoreVersions/#{v['id']}/appStoreVersionLocalizations")["data"].find { |l| l["attributes"]["locale"] == "en-US" }
la = loc["attributes"]
check(la["description"].to_s.size.between?(10, 4000), "description", "#{la['description'].to_s.size} chars")
check(!la["keywords"].to_s.empty? && la["keywords"].size <= 100, "keywords", "#{la['keywords'].to_s.size} chars")
check(la["promotionalText"].to_s.size.between?(1, 170), "promotional text", "#{la['promotionalText'].to_s.size} chars")
check(la["supportUrl"].to_s.start_with?("https://"), "support URL", la["supportUrl"])
check(la["marketingUrl"].to_s.start_with?("https://"), "marketing URL", la["marketingUrl"])
puts "INFO What's New: #{la['whatsNew'].to_s.empty? ? '(empty: not allowed on a first release)' : la['whatsNew'].size.to_s + ' chars'}"
%w[supportUrl marketingUrl].each do |k|
  u = URI(la[k]); code = (Net::HTTP.get_response(u).code rescue "error")
  check(code == "200", "#{k} responds 200", code)
end

need = %w[APP_IPHONE_67 APP_IPAD_PRO_3GEN_129 APP_WATCH_SERIES_10]
sets = ASC.get("/v1/appStoreVersionLocalizations/#{loc['id']}/appScreenshotSets?limit=50")["data"]
need.each do |t|
  s = sets.find { |x| x["attributes"]["screenshotDisplayType"] == t }
  shots = s ? ASC.get("/v1/appScreenshotSets/#{s['id']}/appScreenshots?limit=50")["data"] : []
  states = shots.map { |x| (x["attributes"]["assetDeliveryState"] || {})["state"] }.uniq
  check(!shots.empty? && states == ["COMPLETE"], "screenshots #{t}", "#{shots.size} (#{states.join(',')})")
end
psets = ASC.get("/v1/appStoreVersionLocalizations/#{loc['id']}/appPreviewSets?limit=50")["data"]
%w[IPHONE_67 IPAD_PRO_3GEN_129].each do |t|
  s = psets.find { |x| x["attributes"]["previewType"] == t }
  pv = s ? ASC.get("/v1/appPreviewSets/#{s['id']}/appPreviews?limit=50")["data"] : []
  states = pv.map { |x| (x["attributes"]["assetDeliveryState"] || {})["state"] }.uniq
  check(!pv.empty? && states == ["COMPLETE"], "app preview #{t}", "#{pv.size} (#{states.join(',')})")
end

info = ASC.get("/v1/apps/#{APP}/appInfos")["data"].find { |i| i["attributes"]["appStoreState"] == "PREPARE_FOR_SUBMISSION" } ||
       ASC.get("/v1/apps/#{APP}/appInfos")["data"].first
il = ASC.get("/v1/appInfos/#{info['id']}/appInfoLocalizations")["data"].find { |l| l["attributes"]["locale"] == "en-US" }["attributes"]
check(!il["name"].to_s.empty?, "name", il["name"])
check(!il["subtitle"].to_s.empty?, "subtitle", il["subtitle"])
check(il["privacyPolicyUrl"].to_s.start_with?("https://"), "privacy policy URL", il["privacyPolicyUrl"])
cat = ASC.get("/v1/appInfos/#{info['id']}/primaryCategory")["data"]
check(!cat.nil?, "primary category", cat && cat["id"])
age = ASC.get("/v1/appInfos/#{info['id']}/ageRatingDeclaration")["data"]
check(!age.nil?, "age rating declaration present")
app = ASC.get("/v1/apps/#{APP}")["data"]["attributes"]
check(!app["contentRightsDeclaration"].nil?, "content rights", app["contentRightsDeclaration"])

rd = ASC.get("/v1/appStoreVersions/#{v['id']}/appStoreReviewDetail")["data"]
if rd
  r = rd["attributes"]
  check(%w[contactFirstName contactLastName contactEmail contactPhone].all? { |k| !r[k].to_s.empty? }, "review contact (name, email, phone)")
  check(!r["notes"].to_s.empty?, "review notes", "#{r['notes'].to_s.size} chars")
else
  check(false, "review details")
end

sched = ASC.req(:get, "/v1/appPriceSchedules/#{APP}/manualPrices?limit=10", nil, raise_on_error: false)
check(sched.is_a?(Hash) && !(sched["data"] || []).empty?, "price set")
avail = ASC.get("/v2/appAvailabilities/#{APP}") rescue ASC.get("/v1/apps/#{APP}/appAvailabilityV2") rescue nil
check(!avail.nil?, "availability set")

bal = ASC.get("/v1/apps/#{APP}/betaAppLocalizations")["data"].find { |l| l["attributes"]["locale"] == "en-US" }
check(bal && !bal["attributes"]["description"].to_s.empty? && !bal["attributes"]["feedbackEmail"].to_s.empty?, "TestFlight test information (description, feedback email)")
brd = ASC.get("/v1/apps/#{APP}/betaAppReviewDetail")["data"]["attributes"]
check(%w[contactFirstName contactLastName contactEmail contactPhone].all? { |k| !brd[k].to_s.empty? }, "TestFlight beta review contact")
groups = ASC.get("/v1/apps/#{APP}/subscriptionGroups")["data"]
groups.each do |g|
  ASC.get("/v1/subscriptionGroups/#{g['id']}/subscriptions")["data"].each do |s|
    st = s["attributes"]["state"]
    check(%w[READY_TO_SUBMIT WAITING_FOR_REVIEW APPROVED].include?(st), "subscription #{s['attributes']['productId']}", st)
    imgs = (ASC.req(:get, "/v1/subscriptions/#{s['id']}/images", nil, raise_on_error: false) || {})["data"]
    puts "INFO #{s['attributes']['productId']}: #{imgs ? imgs.size : 'n/a'} promotional image(s) (optional, used only for promoted purchases / offers)"
  end
end
ev = ASC.req(:get, "/v1/apps/#{APP}/appEvents?limit=5", nil, raise_on_error: false)
puts "INFO in-app events: #{ev && ev['data'] ? ev['data'].size : 'n/a'} (optional, left as is)"
puts "INFO App Privacy and Accessibility labels are not readable via the API: check them in the web UI"
puts($fail.zero? ? "\nREADY: only Submit for Review remains (subscriptions: add them on the submission page when you submit)." : "\n#{$fail} item(s) need attention.")
exit($fail.zero? ? 0 : 1)
