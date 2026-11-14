# Creative assets from the App Asset Library: the product page header and the search results card.
# They are optional and reviewed with the version they are placed on (nothing here submits).
#
#   ruby creative_assets.rb specs
#       Prints the creative placement types (HEADER / SEARCH), their groups and accepted image specs.
#   ruby creative_assets.rb list
#       Library images and the creative placements on the editable version (en-US).
#   ruby creative_assets.rb upload <file.png> [--name "Reference name"]
#       Uploads to the library only (category CREATIVE_ASSETS) and waits for processing.
#   ruby creative_assets.rb place <PLACEMENT_TYPE> <file.png|image-id> [--group GROUP] [--name "..."] [--dry-run]
#       Uploads if given a file, removes an existing placement of that type on the en-US
#       localization, then places the image. PLACEMENT_TYPE comes from `specs`:
#       PRODUCT_PAGE_HEADER_ASSET (3840x1646 png) or APP_STORE_SEARCH_RESULTS_ASSET (3:2, up to 3840x2560).
#   ruby creative_assets.rb unplace <PLACEMENT_TYPE>
#
# Reference data ids are read at run time, never hard-coded (Apple adds groups as devices ship).
require_relative "asc_client"
APP = ASC.app_id
cmd = ARGV[0]
DRY = ARGV.include?("--dry-run")

def opt(flag)
  i = ARGV.index(flag)
  i ? ARGV[i + 1] : nil
end

def refdata
  @ref ||= begin
    d = ASC.get("/v1/appAssetLibraryRefData")["data"]
    (d.is_a?(Array) ? d.first : d)["attributes"]
  end
end

def library_id
  @lib ||= ASC.get("/v1/apps/#{APP}/assetLibrary")["data"]["id"]
end

def localization
  @loc ||= begin
    v = ASC.get("/v1/apps/#{APP}/appStoreVersions?filter[platform]=IOS&filter[appStoreState]=PREPARE_FOR_SUBMISSION,DEVELOPER_REJECTED")["data"].first or abort "no editable version"
    ASC.get("/v1/appStoreVersions/#{v['id']}/appStoreVersionLocalizations")["data"].find { |l| l["attributes"]["locale"] == "en-US" } or abort "no en-US localization"
  end
end

def type_entry(type)
  (refdata["placementTypes"] || []).find { |t| t["placementTypeId"] == type || t.values.any? { |v| v == type } }
end

def mapping_group(m)
  m["placementGroupId"] || m["placementGroup"] || m.values.find { |v| v.is_a?(String) }
end

def mapping_specs(m)
  (m["specs"] || m["specIds"] || []).map { |s| s.is_a?(Hash) ? (s["specId"] || s["id"]) : s }
end

def spec(id)
  (refdata["imageSpecs"] || []).find { |s| s["specId"] == id }
end

def put_chunk(op, bytes)
  uri = URI(op["url"])
  r = Net::HTTP.const_get(op["method"].capitalize).new(uri)
  (op["requestHeaders"] || []).each { |h| r[h["name"]] = h["value"] }
  r.body = bytes[op["offset"], op["length"]]
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(r) }
  raise "chunk upload #{res.code}" unless res.code.to_i < 300
end

def upload(file, name)
  bytes = File.binread(file)
  img = ASC.post("/v1/appAssetLibraryImages", { "data" => { "type" => "appAssetLibraryImages",
    "attributes" => { "fileName" => File.basename(file), "fileSize" => bytes.bytesize, "category" => "CREATIVE_ASSETS",
                      "referenceName" => name || File.basename(file, ".*") },
    "relationships" => { "assetLibrary" => { "data" => { "type" => "appAssetLibraries", "id" => library_id } } } } })["data"]
  img["attributes"]["uploadOperations"].each { |op| put_chunk(op, bytes) }
  # asset library commits take `uploaded` alone (no checksum)
  ASC.patch("/v1/appAssetLibraryImages/#{img['id']}", { "data" => { "type" => "appAssetLibraryImages", "id" => img["id"], "attributes" => { "uploaded" => true } } })
  40.times do
    a = ASC.get("/v1/appAssetLibraryImages/#{img['id']}")["data"]["attributes"]
    case a["state"]
    when "PREPARE_FOR_SUBMISSION"
      s = spec(a["specId"])
      puts "ok   #{File.basename(file)} -> image #{img['id']} spec #{s ? s['shortName'] : a['specId']} (#{a.dig('imageAsset', 'width')}x#{a.dig('imageAsset', 'height')})"
      return [img["id"], a["specId"]]
    when "FAILED"
      abort "FAILED #{File.basename(file)}: #{a['stateDetails'].inspect} (delete image #{img['id']} and retry)"
    end
    puts "-- #{File.basename(file)} #{a['state']}"
    sleep 10
  end
  abort "still processing after 400 s: image #{img['id']}"
end

def placements(type = nil)
  q = type ? "?filter[placementType]=#{type}&limit=50" : "?limit=200"
  ASC.get("/v1/appStoreVersionLocalizations/#{localization['id']}/placements#{q}")["data"]
end

case cmd
when "specs"
  puts "asset library #{library_id}"
  types = (refdata["placementTypes"] || []).select { |t| t.to_json =~ /HEADER|SEARCH/ }
  types.each do |t|
    puts JSON.pretty_generate(t.reject { |k, _| k == "specMappings" })
    (t["specMappings"] || []).each do |m|
      puts "  group #{mapping_group(m)}"
      mapping_specs(m).each do |id|
        s = spec(id) or next
        dm = s["dimensions"] || {}
        puts "    #{s['shortName']} #{dm['minWidth']}x#{dm['minHeight']}..#{dm['maxWidth']}x#{dm['maxHeight']} #{s['aspectRatio']} #{(s['fileExtensions'] || []).join(',')} universal=#{s['universalAsset']} alpha=#{s['alphaAllowed']} types=#{(s['compatiblePlacementTypes'] || []).join(',')}"
      end
    end
  end
  (refdata["features"] || []).each do |f|
    next unless f.to_json =~ /HEADER|SEARCH/
    puts "feature #{f.values.find { |v| v.is_a?(String) }}: #{(f['placementPolicies'] || []).select { |p| p.to_json =~ /HEADER|SEARCH/ }.to_json}"
  end
when "list"
  ASC.all("/v1/appAssetLibraries/#{library_id}/images?limit=100").each do |i|
    a = i["attributes"]
    puts "image #{i['id']} #{a['category']} #{a['state']} #{a['fileName']} (#{a['referenceName']}) #{a.dig('imageAsset', 'width')}x#{a.dig('imageAsset', 'height')}"
  end
  placements.each do |p|
    a = p["attributes"]
    next unless a["placementType"].to_s =~ /HEADER|SEARCH/
    puts "placement #{p['id']} #{a['placementType']} #{a['placementGroup']} #{a['state']}"
  end
when "upload"
  file = ARGV[1]
  abort "usage: ruby creative_assets.rb upload <file.png> [--name NAME]" unless file && File.file?(file)
  upload(file, opt("--name"))
when "place"
  type, src = ARGV[1], ARGV[2]
  abort "usage: ruby creative_assets.rb place <PLACEMENT_TYPE> <file.png|image-id> [--group GROUP] [--dry-run]" unless type && src
  entry = type_entry(type) or abort "unknown placement type #{type}; run `specs`"
  abort "#{type} does not accept CREATIVE_ASSETS" unless (entry["acceptsAssetCategories"] || ["CREATIVE_ASSETS"]).include?("CREATIVE_ASSETS")
  if DRY
    puts "DRY #{File.file?(src) ? 'upload ' + File.basename(src) + ', ' : ''}replace #{placements(type).size} existing #{type} placement(s) on #{localization['id']}"
    exit
  end
  image_id, spec_id = File.file?(src) ? upload(src, opt("--name")) : [src, ASC.get("/v1/appAssetLibraryImages/#{src}")["data"]["attributes"]["specId"]]
  group = opt("--group")
  unless group
    fits = (entry["specMappings"] || []).select { |m| mapping_specs(m).include?(spec_id) }.map { |m| mapping_group(m) }
    abort "no group of #{type} accepts spec #{spec_id}; groups: #{(entry['specMappings'] || []).map { |m| mapping_group(m) }.join(', ')}" if fits.empty?
    abort "several groups fit, pass --group: #{fits.join(', ')}" if fits.size > 1
    group = fits.first
  end
  placements(type).select { |p| p["attributes"]["placementGroup"] == group }.each do |p|
    ASC.delete("/v1/appAssetLibraryPlacements/#{p['id']}")
    puts "ok   removed old placement #{p['id']}"
  end
  pl = ASC.post("/v1/appAssetLibraryPlacements", { "data" => { "type" => "appAssetLibraryPlacements",
    "attributes" => { "placementType" => type, "placementGroup" => group },
    "relationships" => { "image" => { "data" => { "type" => "appAssetLibraryImages", "id" => image_id } },
                         "appStoreVersionLocalization" => { "data" => { "type" => "appStoreVersionLocalizations", "id" => localization["id"] } } } } })["data"]
  puts "ok   placed #{type} #{group}: placement #{pl['id']} #{pl['attributes']['state']}"
when "unplace"
  type = ARGV[1] or abort "usage: ruby creative_assets.rb unplace <PLACEMENT_TYPE>"
  placements(type).each do |p|
    ASC.delete("/v1/appAssetLibraryPlacements/#{p['id']}")
    puts "ok   removed placement #{p['id']} (the image stays in the library)"
  end
else
  abort "usage: ruby creative_assets.rb specs | list | upload <file> | place <TYPE> <file|image-id> | unplace <TYPE>"
end
