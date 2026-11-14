# Fills TestFlight Test Information from appstore/listing.json ("testflight") and the App Review contact:
# beta app description, feedback email, marketing/privacy URLs, beta review contact, and "What to Test"
# on the build attached to the editable version. Idempotent. Usage: ruby testflight.rb [--dry-run]
require_relative "asc_client"
require "json"
APP = ASC.app_id
DRY = ARGV.include?("--dry-run")
L = JSON.parse(File.read(File.expand_path("../listing.json", __dir__)))
T = L["testflight"] or abort "listing.json has no testflight section"
def write(m, path, body)
  return puts("DRY #{m.upcase} #{path} #{body.to_json[0, 240]}") if DRY
  ASC.req(m, path, body, raise_on_error: true)
end
def changed(cur, want); want.reject { |k, v| cur[k] == v }; end

T["betaAppLocalization"].each do |locale, want|
  cur = ASC.get("/v1/apps/#{APP}/betaAppLocalizations")["data"].find { |l| l["attributes"]["locale"] == locale }
  if cur
    d = changed(cur["attributes"], want)
    d.empty? ? puts("same betaAppLocalization #{locale}") :
      (write(:patch, "/v1/betaAppLocalizations/#{cur['id']}", { data: { type: "betaAppLocalizations", id: cur["id"], attributes: d } }); puts("ok   betaAppLocalization #{locale}: #{d.keys.join(',')}"))
  else
    write(:post, "/v1/betaAppLocalizations", { data: { type: "betaAppLocalizations", attributes: want.merge("locale" => locale),
      relationships: { app: { data: { type: "apps", id: APP } } } } })
    puts "ok   created betaAppLocalization #{locale}"
  end
end

v = ASC.get("/v1/apps/#{APP}/appStoreVersions?filter[platform]=IOS&filter[appStoreState]=PREPARE_FOR_SUBMISSION")["data"].first
rd = ASC.get("/v1/appStoreVersions/#{v['id']}/appStoreReviewDetail")["data"]["attributes"]
brd = ASC.get("/v1/apps/#{APP}/betaAppReviewDetail")["data"]
want = { "contactFirstName" => rd["contactFirstName"], "contactLastName" => rd["contactLastName"], "contactEmail" => rd["contactEmail"],
         "contactPhone" => rd["contactPhone"], "demoAccountRequired" => false, "notes" => "No account or login is needed. " + T["whatToTest"] }
d = changed(brd["attributes"], want)
d.empty? ? puts("same betaAppReviewDetail") :
  (write(:patch, "/v1/betaAppReviewDetails/#{brd['id']}", { data: { type: "betaAppReviewDetails", id: brd["id"], attributes: d } }); puts("ok   betaAppReviewDetail: #{d.keys.join(',')}"))

build = ASC.get("/v1/appStoreVersions/#{v['id']}/build")["data"]
if build
  bl = ASC.get("/v1/builds/#{build['id']}/betaBuildLocalizations")["data"].find { |l| l["attributes"]["locale"] == "en-US" }
  if bl.nil?
    write(:post, "/v1/betaBuildLocalizations", { data: { type: "betaBuildLocalizations", attributes: { locale: "en-US", whatsNew: T["whatToTest"] },
      relationships: { build: { data: { type: "builds", id: build["id"] } } } } })
    puts "ok   What to Test on build #{build['attributes']['version']} (created)"
  elsif bl["attributes"]["whatsNew"] != T["whatToTest"]
    write(:patch, "/v1/betaBuildLocalizations/#{bl['id']}", { data: { type: "betaBuildLocalizations", id: bl["id"], attributes: { whatsNew: T["whatToTest"] } } })
    puts "ok   What to Test on build #{build['attributes']['version']}"
  else
    puts "same What to Test on build #{build['attributes']['version']}"
  end
else
  puts "warn no build attached to #{v['attributes']['versionString']}"
end
