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

def request(method, path, body = nil, allow_conflict: false)
  uri = URI(path.start_with?("http") ? path : "#{API_BASE}#{path}")
  req = Object.const_get("Net::HTTP::#{method.capitalize}").new(uri)
  req["Authorization"] = "Bearer #{token}"
  req["Accept"] = "application/json"
  req["Content-Type"] = "application/json" if body
  req.body = JSON.generate(body) if body
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
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

def post(type, relationships)
  request("post", "/#{type}", {
    data: {
      type: type,
      relationships: relationships
    }
  }, allow_conflict: true)
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

def patch_review_submission(id, attributes, version_id)
  request("patch", "/reviewSubmissions/#{id}", {
    data: {
      type: "reviewSubmissions",
      id: id,
      attributes: attributes,
      relationships: {
        appStoreVersionForReview: { data: { type: "appStoreVersions", id: version_id } }
      }
    }
  })
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
versions = []
each_page("/apps/#{app_id}/appStoreVersions?filter[platform]=IOS&limit=50") { |version| versions << version }
version = versions.find { |item| item.dig("attributes", "versionString") == "1.0" && item.dig("attributes", "appVersionState") == "PREPARE_FOR_SUBMISSION" } ||
          versions.find { |item| item.dig("attributes", "appVersionState") == "PREPARE_FOR_SUBMISSION" } ||
          versions.find { |item| %w[READY_FOR_REVIEW WAITING_FOR_REVIEW IN_REVIEW].include?(item.dig("attributes", "appVersionState")) }

unless version
  warn "No iOS app version is ready for submission."
  warn versions.map { |item| "#{item.dig("attributes", "versionString")}: #{item.dig("attributes", "appVersionState")}" }.join("\n")
  exit 1
end

puts "Selected iOS version #{version.dig("attributes", "versionString")} (#{version.dig("attributes", "appVersionState")})."
if %w[READY_FOR_REVIEW WAITING_FOR_REVIEW IN_REVIEW].include?(version.dig("attributes", "appVersionState"))
  puts "App version is already submitted or in review."
  exit 0
end

subscription_groups = []
each_page("/apps/#{app_id}/subscriptionGroups?limit=50") { |group| subscription_groups << group }
subscriptions = []
subscription_groups.each do |group|
  each_page("/subscriptionGroups/#{group["id"]}/subscriptions?limit=100") { |subscription| subscriptions << subscription }
end

subscriptions.each do |subscription|
  state = subscription.dig("attributes", "state")
  product_id = subscription.dig("attributes", "productId")
  next unless %w[PREPARE_FOR_SUBMISSION DEVELOPER_ACTION_NEEDED REJECTED].include?(state)

  result = post("subscriptionSubmissions", {
    subscription: { data: { type: "subscriptions", id: subscription["id"] } }
  })
  if result["conflict"]
    puts "Subscription #{product_id} already has a submission or is not currently submittable."
  else
    puts "Submitted subscription #{product_id}."
  end
end

review_submission = request("post", "/reviewSubmissions", {
  data: {
    type: "reviewSubmissions",
    attributes: { platform: "IOS" },
    relationships: {
      app: { data: { type: "apps", id: app_id } },
      appStoreVersionForReview: { data: { type: "appStoreVersions", id: version["id"] } }
    }
  }
}, allow_conflict: true)

if review_submission["conflict"]
  existing = []
  each_page("/apps/#{app_id}/reviewSubmissions?limit=20") { |submission| existing << submission }
  review_submission_data = existing.find { |submission| submission.dig("attributes", "state") == "READY_FOR_REVIEW" }
  unless review_submission_data
    warn "Could not create or find a ready review submission."
    warn review_submission["body"]
    exit 1
  end
else
  review_submission_data = review_submission["data"]
end

puts "Using review submission #{review_submission_data["id"]}."
item = request("post", "/reviewSubmissionItems", {
  data: {
    type: "reviewSubmissionItems",
    relationships: {
      reviewSubmission: { data: { type: "reviewSubmissions", id: review_submission_data["id"] } },
      appStoreVersion: { data: { type: "appStoreVersions", id: version["id"] } }
    }
  }
}, allow_conflict: true)

if item["conflict"]
  puts "Review submission item already exists or cannot be recreated."
else
  puts "Added app version to review submission."
end

patch_review_submission(review_submission_data["id"], { submitted: true }, version["id"])
puts "Submitted VitalOS AI for App Review."
