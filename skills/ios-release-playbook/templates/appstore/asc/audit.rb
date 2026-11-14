# Dumps the current App Store Connect state for MyApp to audit.json (read-only).
require_relative "asc_client"
APP = ASC.app_id
out = {}
safe = ->(k, &b) { begin out[k] = b.call; rescue => e; out[k] = { "error" => e.message }; end }
safe.("app") { ASC.get("/v1/apps/#{APP}")["data"]["attributes"] }
safe.("appInfos") { ASC.get("/v1/apps/#{APP}/appInfos?include=primaryCategory,secondaryCategory,ageRatingDeclaration,appInfoLocalizations") }
safe.("versions") { ASC.get("/v1/apps/#{APP}/appStoreVersions?limit=5") }
vers = (out["versions"]["data"] rescue []) || []
vers.each do |v|
  id = v["id"]
  safe.("ver_#{id}_locs") { ASC.get("/v1/appStoreVersions/#{id}/appStoreVersionLocalizations") }
  safe.("ver_#{id}_review") { ASC.req(:get, "/v1/appStoreVersions/#{id}/appStoreReviewDetail", nil, raise_on_error: false) }
  safe.("ver_#{id}_build") { ASC.req(:get, "/v1/appStoreVersions/#{id}/build", nil, raise_on_error: false) }
  locs = (out["ver_#{id}_locs"]["data"] rescue []) || []
  locs.each do |l|
    safe.("loc_#{l['id']}_sets") do
      ASC.get("/v1/appStoreVersionLocalizations/#{l['id']}/appScreenshotSets?include=appScreenshots")
    end
  end
end
safe.("builds") { ASC.get("/v1/builds?filter[app]=#{APP}&sort=-uploadedDate&limit=5&fields[builds]=version,processingState,uploadedDate,usesNonExemptEncryption,expired") }
safe.("price") { ASC.req(:get, "/v1/apps/#{APP}/appPriceSchedule?include=manualPrices,baseTerritory", nil, raise_on_error: false) }
safe.("availability") { ASC.req(:get, "/v2/appAvailabilities/#{APP}", nil, raise_on_error: false) }
safe.("availability_v1") { ASC.req(:get, "/v1/apps/#{APP}/appAvailabilityV2", nil, raise_on_error: false) }
safe.("subGroups") { ASC.get("/v1/apps/#{APP}/subscriptionGroups?include=subscriptions,subscriptionGroupLocalizations") }
((out["subGroups"]["included"] rescue []) || []).select { |i| i["type"] == "subscriptions" }.each do |s|
  safe.("sub_#{s['id']}_locs") { ASC.get("/v1/subscriptions/#{s['id']}/subscriptionLocalizations") }
  safe.("sub_#{s['id']}_shot") { ASC.req(:get, "/v1/subscriptions/#{s['id']}/appStoreReviewScreenshot", nil, raise_on_error: false) }
  safe.("sub_#{s['id']}_avail") { ASC.req(:get, "/v1/subscriptions/#{s['id']}/subscriptionAvailability", nil, raise_on_error: false) }
end
safe.("eula") { ASC.req(:get, "/v1/apps/#{APP}/endUserLicenseAgreement", nil, raise_on_error: false) }
File.write(File.join(__dir__, "audit.json"), JSON.pretty_generate(out))
puts "wrote audit.json (#{out.keys.size} keys)"
out.each { |k, v| puts "ERR #{k}: #{v['error']}" if v.is_a?(Hash) && v["error"] }
