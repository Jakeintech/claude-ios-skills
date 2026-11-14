# Replaces the App Store app previews (video) for the editable version's en-US localization.
# Usage: ruby previews.rb <dir> [--dry-run] [--poster=HH:MM:SS:FF]
#   <dir>/<PREVIEW_TYPE>/*.mp4  e.g. IPHONE_67/01.mp4 (886x1920), IPAD_PRO_3GEN_129/01.mp4 (1200x1600)
# Up to 3 previews per type, uploaded in name order. Absent type folders are left untouched.
# Apple Watch has no app previews. Encode with scripts/make-app-preview.sh first.
require_relative "asc_client"
APP = ASC.app_id
if ARGV[0] == "--set-poster"
  # ruby previews.rb --set-poster IPHONE_67=00:00:10:00 IPAD_PRO_3GEN_129=00:00:13:00
  # Changes the poster frame of the previews already uploaded, without re-uploading the video.
  want = ARGV[1..-1].map { |a| a.split("=", 2) }.to_h
  v = ASC.get("/v1/apps/#{APP}/appStoreVersions?filter[platform]=IOS&filter[appStoreState]=PREPARE_FOR_SUBMISSION,DEVELOPER_REJECTED")["data"].first
  loc = ASC.get("/v1/appStoreVersions/#{v['id']}/appStoreVersionLocalizations")["data"].find { |l| l["attributes"]["locale"] == "en-US" }
  ASC.get("/v1/appStoreVersionLocalizations/#{loc['id']}/appPreviewSets?limit=50")["data"].each do |s|
    tc = want[s["attributes"]["previewType"]] or next
    ASC.get("/v1/appPreviewSets/#{s['id']}/appPreviews?limit=50")["data"].each do |p|
      ASC.patch("/v1/appPreviews/#{p['id']}", { "data" => { "type" => "appPreviews", "id" => p["id"], "attributes" => { "previewFrameTimeCode" => tc } } })
      puts "ok   #{s['attributes']['previewType']} #{p['attributes']['fileName']} poster #{tc}"
    end
  end
  exit
end
dir = ARGV[0] or abort "usage: ruby previews.rb <dir> [--dry-run] [--poster=00:00:05:00]"
DRY = ARGV.include?("--dry-run")
POSTER = (ARGV.find { |a| a.start_with?("--poster=") } || "--poster=00:00:05:00").split("=", 2)[1]

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
sets = ASC.get("/v1/appStoreVersionLocalizations/#{loc['id']}/appPreviewSets?limit=50")["data"]
puts "existing preview sets: " + sets.map { |s| s["attributes"]["previewType"] }.join(", ")

Dir.children(dir).sort.each do |ptype|
  files = Dir.glob(File.join(dir, ptype, "*.{mp4,mov,m4v}")).sort
  next if files.empty?
  abort "#{ptype}: at most 3 previews" if files.size > 3
  set = sets.find { |s| s["attributes"]["previewType"] == ptype }
  if DRY
    puts "DRY #{ptype}: replace #{set ? 'existing' : 'new'} set with #{files.map { |f| File.basename(f) }.join(' ')} (poster #{POSTER})"
    next
  end
  unless set
    set = ASC.post("/v1/appPreviewSets", { "data" => { "type" => "appPreviewSets", "attributes" => { "previewType" => ptype },
      "relationships" => { "appStoreVersionLocalization" => { "data" => { "type" => "appStoreVersionLocalizations", "id" => loc["id"] } } } } })["data"]
  end
  ASC.get("/v1/appPreviewSets/#{set['id']}/appPreviews?limit=50")["data"].each { |p| ASC.delete("/v1/appPreviews/#{p['id']}") }
  files.each do |f|
    bytes = File.binread(f)
    mime = f.end_with?(".mov") ? "video/quicktime" : "video/mp4"
    pv = ASC.post("/v1/appPreviews", { "data" => { "type" => "appPreviews",
      "attributes" => { "fileName" => File.basename(f), "fileSize" => bytes.bytesize, "mimeType" => mime, "previewFrameTimeCode" => POSTER },
      "relationships" => { "appPreviewSet" => { "data" => { "type" => "appPreviewSets", "id" => set["id"] } } } } })["data"]
    pv["attributes"]["uploadOperations"].each { |op| put_chunk(op, bytes) }
    ASC.patch("/v1/appPreviews/#{pv['id']}", { "data" => { "type" => "appPreviews", "id" => pv["id"],
      "attributes" => { "uploaded" => true, "sourceFileChecksum" => Digest::MD5.hexdigest(bytes) } } })
    puts "ok   #{ptype} #{File.basename(f)}"
  end
end
exit if DRY
# Video processing takes minutes; poll up to ~10 min for COMPLETE or FAILED.
40.times do
  states = ASC.get("/v1/appStoreVersionLocalizations/#{loc['id']}/appPreviewSets?limit=50")["data"].flat_map do |s|
    ASC.get("/v1/appPreviewSets/#{s['id']}/appPreviews?limit=50")["data"].map do |p|
      st = p["attributes"]["assetDeliveryState"] || {}
      ["#{s['attributes']['previewType']}/#{p['attributes']['fileName']}", st["state"], (st["errors"] || []).map { |e| e["description"] }.join("; ")]
    end
  end
  states.each { |n, s, e| puts "#{n}: #{s} #{e}" }
  break if states.all? { |_, s, _| %w[COMPLETE FAILED].include?(s) }
  puts "-- waiting"
  sleep 15
end
