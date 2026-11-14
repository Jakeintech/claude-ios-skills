# Applies two optional App Store Connect settings via the API. Idempotent.
# Usage: ruby settings.rb [--dry-run]
#   1. Billing grace period ON (16 days, all renewals; sandbox too)
#   2. Accessibility Nutrition Label for iPhone and iPad: Dark Interface only, published
require_relative "asc_client"
APP = ASC.app_id
DRY = ARGV.include?("--dry-run")
def write(m, path, body)
  return puts("DRY #{m.upcase} #{path} #{body.to_json[0, 300]}") if DRY
  ASC.req(m, path, body, raise_on_error: true)
end

gp = ASC.req(:get, "/v1/apps/#{APP}/subscriptionGracePeriod", nil, raise_on_error: false)
if gp && gp["data"]
  a = gp["data"]["attributes"]; puts "grace period now: #{a.to_json}"
  want = { "optIn" => true, "sandboxOptIn" => true, "duration" => "SIXTEEN_DAYS", "renewalType" => "ALL_RENEWALS" }
  d = want.reject { |k, v| a[k] == v }
  if d.empty? then puts "same grace period"
  else write(:patch, "/v1/subscriptionGracePeriods/#{gp['data']['id']}", { data: { type: "subscriptionGracePeriods", id: gp["data"]["id"], attributes: d } }); puts "ok   grace period: #{d.keys.join(',')}" end
else
  puts "warn grace period not readable via API; set it in the web UI"
end

%w[IPHONE IPAD].each do |fam|
  list = ASC.req(:get, "/v1/apps/#{APP}/accessibilityDeclarations?filter[deviceFamily]=#{fam}", nil, raise_on_error: false)
  unless list.is_a?(Hash) && list["data"]
    puts "warn accessibility declarations not available via API (#{fam})"; next
  end
  cur = list["data"].find { |x| x["attributes"]["state"] == "DRAFT" } || list["data"].find { |x| x["attributes"]["state"] == "PUBLISHED" }
  attrs = { "supportsDarkInterface" => true }
  if cur && cur["attributes"]["state"] == "PUBLISHED" && cur["attributes"]["supportsDarkInterface"] == true
    puts "same accessibility #{fam} (published)"; next
  end
  unless cur && cur["attributes"]["state"] == "DRAFT"
    cur = write(:post, "/v1/accessibilityDeclarations", { data: { type: "accessibilityDeclarations", attributes: attrs.merge("deviceFamily" => fam),
      relationships: { app: { data: { type: "apps", id: APP } } } } })
    cur = cur && cur["data"]
    puts "ok   accessibility #{fam}: draft created"
  end
  next if DRY
  begin
    write(:patch, "/v1/accessibilityDeclarations/#{cur['id']}", { data: { type: "accessibilityDeclarations", id: cur["id"], attributes: attrs.merge("publish" => true) } })
    puts "ok   accessibility #{fam}: Dark Interface published"
  rescue RuntimeError => e
    raise unless e.message.include?("-> 409") && e.message.include?("must be available on the App Store")
    puts "wait accessibility #{fam}: draft saved; Apple only allows publishing once the app is live, rerun after release"
  end
end
puts "info Mac and Vision Pro availability have no public API: untick them on Pricing and Availability in the web UI"
