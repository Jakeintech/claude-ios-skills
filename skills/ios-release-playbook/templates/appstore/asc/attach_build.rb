# Attaches a processed build to the editable App Store version (the version in listing.json).
# Usage: ruby attach_build.rb [BUILD_NUMBER] [--dry-run]   (default: the highest VALID build of that version)
# Nothing is submitted.
require_relative "asc_client"
require "json"
APP = ASC.app_id
DRY = ARGV.include?("--dry-run")
want = ARGV.find { |a| a =~ /\A\d+\z/ }
L = JSON.parse(File.read(File.expand_path("../listing.json", __dir__)))
vs = L["version"]["versionString"]

ver = ASC.get("/v1/apps/#{APP}/appStoreVersions?filter[platform]=IOS&filter[versionString]=#{vs}")["data"].first
abort "no App Store version #{vs}" unless ver
state = ver["attributes"]["appStoreState"] || ver["attributes"]["appVersionState"]

builds = ASC.get("/v1/builds?filter[app]=#{APP}&filter[preReleaseVersion.version]=#{vs}&limit=50")["data"]
valid = builds.select { |b| b["attributes"]["processingState"] == "VALID" && !b["attributes"]["expired"] }
build = want ? valid.find { |b| b["attributes"]["version"] == want } : valid.max_by { |b| b["attributes"]["version"].to_i }
abort "no VALID build #{want || ''} for #{vs} (have: #{builds.map { |b| "#{b['attributes']['version']}:#{b['attributes']['processingState']}" }.join(', ')})" unless build

cur = ASC.get("/v1/appStoreVersions/#{ver['id']}/build")["data"]
num = build["attributes"]["version"]
if cur && cur["id"] == build["id"]
  puts "ok   build #{num} already attached to #{vs} (#{state})"
elsif DRY
  puts "DRY  attach build #{num} to #{vs} (#{state}); currently #{cur ? cur['attributes']['version'] : 'none'}"
else
  ASC.req(:patch, "/v1/appStoreVersions/#{ver['id']}/relationships/build", { data: { type: "builds", id: build["id"] } }, raise_on_error: true)
  puts "ok   attached build #{num} to #{vs} (#{state})"
end
