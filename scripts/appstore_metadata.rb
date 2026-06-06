require "base64"
require "json"
require "net/http"
require "openssl"
require "uri"

API_BASE = "https://api.appstoreconnect.apple.com/v1"

def b64url(value)
  Base64.urlsafe_encode64(value).delete("=")
end

def token
  @token ||= begin
    header = { alg: "ES256", kid: ENV.fetch("ASC_KEY_ID"), typ: "JWT" }
    payload = { iss: ENV.fetch("ASC_ISSUER_ID"), exp: Time.now.to_i + 1200, aud: "appstoreconnect-v1" }
    signing_input = [b64url(header.to_json), b64url(payload.to_json)].join(".")
    key = OpenSSL::PKey.read(File.read(ENV.fetch("ASC_KEY_PATH")))
    der_signature = key.sign(OpenSSL::Digest.new("SHA256"), signing_input)
    asn1 = OpenSSL::ASN1.decode(der_signature)
    signature = asn1.value.map { |integer| [integer.value.to_i.to_s(16).rjust(64, "0")[-64, 64]].pack("H*") }.join
    "#{signing_input}.#{b64url(signature)}"
  end
end

def request(method, path, body = nil, retry_not_found: false, allow_conflict: false)
  uri = URI(path.start_with?("http") ? path : "#{API_BASE}#{path}")
  req = Object.const_get("Net::HTTP::#{method.capitalize}").new(uri)
  req["Authorization"] = "Bearer #{token}"
  req["Accept"] = "application/json"
  req["Content-Type"] = "application/json" if body
  req.body = JSON.generate(body) if body
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  return nil if retry_not_found && response.code.to_i == 404
  return { "conflict" => true, "body" => response.body } if allow_conflict && response.code.to_i == 409
  unless response.code.to_i.between?(200, 299)
    warn "#{method.upcase} #{uri} failed with HTTP #{response.code}"
    warn response.body
    exit 1
  end
  response.body.nil? || response.body.empty? ? {} : JSON.parse(response.body)
end

def get(path)
  request("get", path)
end

def patch(type, id, attributes)
  request("patch", "/#{type}/#{id}", {
    data: {
      type: type,
      id: id,
      attributes: attributes
    }
  })
end

def post(type, attributes, relationships = {})
  request("post", "/#{type}", {
    data: {
      type: type,
      attributes: attributes,
      relationships: relationships
    }
  })
end

def post_allow_conflict(type, attributes, relationships = {})
  request("post", "/#{type}", {
    data: {
      type: type,
      attributes: attributes,
      relationships: relationships
    }
  }, allow_conflict: true)
end

def each_page(path)
  next_path = path
  loop do
    page = get(next_path)
    Array(page["data"]).each { |item| yield item }
    next_link = page.dig("links", "next")
    break unless next_link
    next_path = next_link
  end
end

app_id = ENV.fetch("APP_STORE_CONNECT_APP_ID")
privacy_url = ENV.fetch("PRIVACY_POLICY_URL")
support_url = ENV.fetch("SUPPORT_URL")
marketing_url = ENV.fetch("MARKETING_URL")

app = get("/apps/#{app_id}")
puts "Updating metadata for #{app.dig("data", "attributes", "name")}."

app_infos = []
each_page("/apps/#{app_id}/appInfos?limit=10") { |info| app_infos << info }
app_infos.each do |info|
  localizations = []
  each_page("/appInfos/#{info["id"]}/appInfoLocalizations?limit=50") { |loc| localizations << loc }
  localizations.each do |loc|
    patch("appInfoLocalizations", loc["id"], {
      privacyPolicyUrl: privacy_url
    })
    puts "Updated privacy URLs for #{loc.dig("attributes", "locale")}."
  end
end

versions = []
each_page("/apps/#{app_id}/appStoreVersions?filter[platform]=IOS&limit=50") { |version| versions << version }
editable_versions = versions.select do |version|
  %w[PREPARE_FOR_SUBMISSION DEVELOPER_REJECTED REJECTED READY_FOR_REVIEW WAITING_FOR_REVIEW].include?(version.dig("attributes", "appVersionState"))
end
editable_versions = versions if editable_versions.empty?

editable_versions.each do |version|
  localizations = []
  each_page("/appStoreVersions/#{version["id"]}/appStoreVersionLocalizations?limit=50") { |loc| localizations << loc }
  localizations.each do |loc|
    patch("appStoreVersionLocalizations", loc["id"], {
      supportUrl: support_url,
      marketingUrl: marketing_url
    })
    puts "Updated version URLs for #{loc.dig("attributes", "locale")}."
  end
end

subscription_groups = []
each_page("/apps/#{app_id}/subscriptionGroups?limit=50") { |group| subscription_groups << group }
group = subscription_groups.find { |item| item.dig("attributes", "referenceName") == "VitalOS AI Subscriptions" }
unless group
  group = post("subscriptionGroups", { referenceName: "VitalOS AI Subscriptions" }, {
    app: { data: { type: "apps", id: app_id } }
  })["data"]
  subscription_groups << group
  puts "Created subscription group."
end

group_localizations = []
each_page("/subscriptionGroups/#{group["id"]}/subscriptionGroupLocalizations?limit=50") { |loc| group_localizations << loc }
unless group_localizations.any? { |loc| loc.dig("attributes", "locale") == "en-US" }
  post("subscriptionGroupLocalizations", {
    name: "VitalOS AI Subscriptions",
    locale: "en-US",
    customAppName: "VitalOS AI"
  }, {
    subscriptionGroup: { data: { type: "subscriptionGroups", id: group["id"] } }
  })
  puts "Created subscription group localization."
end

plans = [
  {
    product_id: "vitalos.premium.monthly",
    name: "Vital Premium Monthly",
    period: "ONE_MONTH",
    level: 2,
    description: "Adaptive protocols, AI coach, voice coaching, advanced analytics, and future projections."
  },
  {
    product_id: "vitalos.premium.yearly",
    name: "Vital Premium Yearly",
    period: "ONE_YEAR",
    level: 2,
    description: "One year of adaptive protocols, AI coach, voice coaching, advanced analytics, and future projections."
  },
  {
    product_id: "vitalos.elite.monthly",
    name: "Vital Elite Monthly",
    period: "ONE_MONTH",
    level: 1,
    description: "Premium AI models, deep analytics, advanced personalization, and premium themes."
  }
]

existing_subscriptions = []
subscription_groups.each do |existing_group|
  each_page("/subscriptionGroups/#{existing_group["id"]}/subscriptions?limit=100") { |subscription| existing_subscriptions << subscription }
end

plans.each do |plan|
  subscription = existing_subscriptions.find { |item| item.dig("attributes", "productId") == plan[:product_id] }
  unless subscription
    created = post_allow_conflict("subscriptions", {
      name: plan[:name],
      productId: plan[:product_id],
      familySharable: false,
      subscriptionPeriod: plan[:period],
      reviewNote: "VitalOS AI is a wellness and lifestyle app. It provides educational guidance only and does not provide medical advice.",
      groupLevel: plan[:level]
    }, {
      group: { data: { type: "subscriptionGroups", id: group["id"] } }
    })
    if created["conflict"]
      puts "Subscription #{plan[:product_id]} already exists in App Store Connect."
      next
    end
    subscription = created["data"]
    existing_subscriptions << subscription
    puts "Created subscription #{plan[:product_id]}."
  end

  localizations = []
  each_page("/subscriptions/#{subscription["id"]}/subscriptionLocalizations?limit=50") { |loc| localizations << loc }
  unless localizations.any? { |loc| loc.dig("attributes", "locale") == "en-US" }
    post("subscriptionLocalizations", {
      name: plan[:name],
      locale: "en-US",
      description: plan[:description]
    }, {
      subscription: { data: { type: "subscriptions", id: subscription["id"] } }
    })
    puts "Created localization for #{plan[:product_id]}."
  end
end

puts "Metadata automation complete."
