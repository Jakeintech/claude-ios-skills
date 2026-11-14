# Minimal App Store Connect API client (no gems). ES256 JWT from the .p8 key.
require "openssl"; require "base64"; require "json"; require "net/http"; require "uri"; require "digest"

module ASC
  BASE = "https://api.appstoreconnect.apple.com"
  module_function

  def b64u(s)

    Base64.urlsafe_encode64(s, padding: false)

  end

  def key_pem
    if (k = ENV["APP_STORE_CONNECT_API_KEY_KEY"]) && !k.empty?
      k.include?("-----BEGIN") ? k : Base64.decode64(k)
    else
      kid = ENV["APP_STORE_CONNECT_API_KEY_ID"] || ENV["ASC_KEY_ID"]
      path = ENV["ASC_PRIVATE_KEY_PATH"] || File.expand_path("~/.appstoreconnect/private_keys/AuthKey_#{kid}.p8")
      File.read(path)
    end
  end

  def token
    return @tok if @tok && @tok_exp > Time.now.to_i + 60
    kid = ENV["APP_STORE_CONNECT_API_KEY_ID"] || ENV["ASC_KEY_ID"]
    iss = ENV["APP_STORE_CONNECT_API_KEY_ISSUER_ID"] || ENV["ASC_ISSUER_ID"]
    abort "missing ASC key env vars" unless kid && iss
    @tok_exp = Time.now.to_i + 1100
    h = b64u({ alg: "ES256", kid: kid, typ: "JWT" }.to_json)
    p = b64u({ iss: iss, iat: Time.now.to_i, exp: @tok_exp, aud: "appstoreconnect-v1" }.to_json)
    key = OpenSSL::PKey::EC.new(key_pem)
    der = key.sign(OpenSSL::Digest::SHA256.new, "#{h}.#{p}")
    seq = OpenSSL::ASN1.decode(der)
    raw = seq.value.map { |i| i.value.to_s(2).rjust(32, "\x00".b)[-32..] }.join
    @tok = "#{h}.#{p}.#{b64u(raw)}"
  end

  def req(method, path, body = nil, raise_on_error: true)
    uri = URI(path.start_with?("http") ? path : BASE + path)
    cls = { get: Net::HTTP::Get, post: Net::HTTP::Post, patch: Net::HTTP::Patch, delete: Net::HTTP::Delete }[method]
    r = cls.new(uri)
    r["Authorization"] = "Bearer #{token}"
    r["Content-Type"] = "application/json"
    r.body = body.to_json if body
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(r) }
    data = res.body && !res.body.empty? ? (JSON.parse(res.body) rescue res.body) : nil
    if res.code.to_i >= 400
      msg = "#{method.upcase} #{path} -> #{res.code}: #{data.is_a?(Hash) ? (data['errors'] || []).map { |e| "#{e['title']}: #{e['detail']}" }.join(' | ') : data}"
      raise msg if raise_on_error
      warn msg
    end
    data
  end

  def get(p)

    req(:get, p)

  end
  # The App Store Connect app id: $ASC_APP_ID, else appstore/app-info.json "app_id",
  # else looked up once by bundle id (the app record must exist; create it in App Store Connect).
  def app_id
    return @app_id if @app_id
    env = ENV["ASC_APP_ID"].to_s
    return @app_id = env unless env.empty?
    info = JSON.parse(File.read(File.expand_path("../app-info.json", __dir__)))
    return @app_id = info["app_id"].to_s unless info["app_id"].to_s.empty?
    found = get("/v1/apps?filter[bundleId]=#{info['bundleId']}")["data"].first
    abort "no App Store Connect app record for #{info['bundleId']} yet: create it in App Store Connect, then put its id in appstore/app-info.json" unless found
    @app_id = found["id"]
  end
  def all(p)
    out = []; d = get(p)
    loop { out.concat(d["data"]); nxt = d.dig("links", "next"); break unless nxt; d = get(nxt) }
    out
  end
  def post(p, b)
    req(:post, p, b)
  end
  def patch(p, b)
    req(:patch, p, b)
  end
  def delete(p)
    req(:delete, p)
  end
end
