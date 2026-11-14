# Read-only: lists the capabilities enabled on each MyApp bundle ID and compares with what the app uses.
require_relative "asc_client"
want = {
  "com.example.myapp"         => %w[APP_GROUPS IN_APP_PURCHASE WEATHERKIT],
  "com.example.myapp.widgets" => %w[APP_GROUPS],
  "com.example.myapp.watchkitapp" => %w[APP_GROUPS],
  "com.example.myapp.watchkitapp.widgets" => %w[APP_GROUPS],
}
ASC.all("/v1/bundleIds?filter[identifier]=#{want.keys.join(',')}&limit=50").each do |b|
  idf = b["attributes"]["identifier"]
  next unless want.key?(idf)
  caps = ASC.all("/v1/bundleIds/#{b['id']}/bundleIdCapabilities").map { |c| [c["attributes"]["capabilityType"], c["attributes"]["settings"]] }
  types = caps.map(&:first)
  puts "#{idf} (#{b['attributes']['platform']}, id #{b['id']})"
  puts "  enabled: #{types.sort.join(', ')}"
  miss = want[idf] - types
  puts "  MISSING: #{miss.join(', ')}" unless miss.empty?
  caps.each { |t, s| puts "  #{t} settings: #{s.to_json[0, 300]}" if s && !s.empty? }
  prof = ASC.all("/v1/bundleIds/#{b['id']}/profiles").map { |p| "#{p['attributes']['name']} [#{p['attributes']['profileState']}, exp #{p['attributes']['expirationDate']}]" }
  puts "  profiles: #{prof.join('; ')}"
end
