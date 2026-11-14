# Replaces the App Store screenshots for the editable version's en-US localization.
# Usage: ruby screenshots.rb <dir> [--dry-run]
#   <dir>/<DISPLAY_TYPE>/*.png  e.g. APP_IPHONE_67/01.png, APP_IPAD_PRO_3GEN_129/01.png
# Files upload in name order. A display type folder that is absent is left untouched.
require_relative "asc_client"
APP = ASC.app_id
dir = ARGV[0] or abort "usage: ruby screenshots.rb <dir> [--dry-run]"
DRY = ARGV.include?("--dry-run")

def put_chunk(op, bytes)
  uri = URI(op["url"])
  r = Net::HTTP.const_get(op["method"].capitalize).new(uri)
  (op["requestHeaders"] || []).each { |h| r[h["name"]] = h["value"] }
  r.body = bytes[op["offset"], op["length"]]
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(r) }
  raise "chunk upload #{res.code}" unless res.code.to_i < 300
end

vers = ASC.get("/v1/apps/#{APP}/appStoreVersions?filter[platform]=IOS&filter[appStoreState]=PREPARE_FOR_SUBMISSION,DEVELOPER_REJECTED")["data"]
v = vers.first or abort "no version in PREPARE_FOR_SUBMISSION"
loc = ASC.get("/v1/appStoreVersions/#{v['id']}/appStoreVersionLocalizations")["data"].find { |l| l["attributes"]["locale"] == "en-US" }
sets = ASC.get("/v1/appStoreVersionLocalizations/#{loc['id']}/appScreenshotSets?limit=50")["data"]
puts "existing sets: " + sets.map { |s| s["attributes"]["screenshotDisplayType"] }.join(", ")

Dir.children(dir).sort.each do |dtype|
  files = Dir.glob(File.join(dir, dtype, "*.png")).sort
  next if files.empty?
  set = sets.find { |s| s["attributes"]["screenshotDisplayType"] == dtype }
  if DRY
    puts "DRY #{dtype}: replace #{set ? 'existing' : 'new'} set with #{files.size} files: #{files.map { |f| File.basename(f) }.join(' ')}"
    next
  end
  unless set
    set = ASC.post("/v1/appScreenshotSets", { "data" => { "type" => "appScreenshotSets", "attributes" => { "screenshotDisplayType" => dtype },
      "relationships" => { "appStoreVersionLocalization" => { "data" => { "type" => "appStoreVersionLocalizations", "id" => loc["id"] } } } } })["data"]
  end
  ASC.get("/v1/appScreenshotSets/#{set['id']}/appScreenshots?limit=50")["data"].each { |s| ASC.delete("/v1/appScreenshots/#{s['id']}") }
  files.each do |f|
    bytes = File.binread(f)
    shot = ASC.post("/v1/appScreenshots", { "data" => { "type" => "appScreenshots", "attributes" => { "fileName" => File.basename(f), "fileSize" => bytes.bytesize },
      "relationships" => { "appScreenshotSet" => { "data" => { "type" => "appScreenshotSets", "id" => set["id"] } } } } })["data"]
    shot["attributes"]["uploadOperations"].each { |op| put_chunk(op, bytes) }
    ASC.patch("/v1/appScreenshots/#{shot['id']}", { "data" => { "type" => "appScreenshots", "id" => shot["id"],
      "attributes" => { "uploaded" => true, "sourceFileChecksum" => Digest::MD5.hexdigest(bytes) } } })
    puts "ok   #{dtype} #{File.basename(f)}"
  end
end
sleep 10 unless DRY
ASC.get("/v1/appStoreVersionLocalizations/#{loc['id']}/appScreenshotSets?include=appScreenshots&limit=50")["data"].each do |s|
  shots = ASC.get("/v1/appScreenshotSets/#{s['id']}/appScreenshots?limit=50")["data"]
  states = shots.map { |x| (x["attributes"]["assetDeliveryState"] || {})["state"] }
  puts "#{s['attributes']['screenshotDisplayType']}: #{shots.size} shots, states #{states.uniq.join(',')}"
end
