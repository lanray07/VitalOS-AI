require "base64"
require "json"
require "net/http"
require "openssl"
require "uri"
require "digest"

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

def upload_asset(operation, file_path)
  uri = URI(operation.fetch("url"))
  method = operation.fetch("method", "PUT").capitalize
  req = Object.const_get("Net::HTTP::#{method}").new(uri)
  Array(operation["requestHeaders"]).each do |header|
    req[header.fetch("name")] = header.fetch("value")
  end
  offset = operation.fetch("offset", 0)
  length = operation["length"]
  File.open(file_path, "rb") do |file|
    file.seek(offset)
    req.body = length ? file.read(length) : file.read
  end
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  unless response.code.to_i.between?(200, 299)
    warn "Asset upload failed with HTTP #{response.code}"
    warn response.body
    exit 1
  end
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

def post_review_detail(attributes, version_id)
  request("post", "/appStoreReviewDetails", {
    data: {
      type: "appStoreReviewDetails",
      attributes: attributes,
      relationships: {
        appStoreVersion: { data: { type: "appStoreVersions", id: version_id } }
      }
    }
  }, allow_conflict: true)
end

def delete_resource(type, id)
  request("delete", "/#{type}/#{id}")
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

def related_resource(path)
  response = request("get", path, retry_not_found: true)
  response && response["data"]
end

def upload_reserved_asset(resource_type, resource_id, file_path)
  Array(related_resource("/#{resource_type}/#{resource_id}").dig("attributes", "uploadOperations")).each do |operation|
    upload_asset(operation, file_path)
  end
  patch(resource_type, resource_id, {
    sourceFileChecksum: Digest::MD5.file(file_path).base64digest,
    uploaded: true
  })
end

app_id = ENV.fetch("APP_STORE_CONNECT_APP_ID")
privacy_url = ENV.fetch("PRIVACY_POLICY_URL")
support_url = ENV.fetch("SUPPORT_URL")
marketing_url = ENV.fetch("MARKETING_URL")
terms_url = ENV.fetch("TERMS_OF_USE_URL", "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")

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

  age_rating = request("get", "/appInfos/#{info["id"]}/ageRatingDeclaration", retry_not_found: true)
  if age_rating && age_rating["data"]
    patch("ageRatingDeclarations", age_rating["data"]["id"], {
      healthOrWellnessTopics: true,
      medicalOrTreatmentInformation: "NONE"
    })
    puts "Updated wellness age-rating declaration."
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
    existing_description = loc.dig("attributes", "description").to_s.strip
    eula_line = "Terms of Use (EULA): #{terms_url}"
    description = existing_description.include?(terms_url) ? existing_description : [existing_description, eula_line].reject(&:empty?).join("\n\n")
    patch("appStoreVersionLocalizations", loc["id"], {
      supportUrl: support_url,
      marketingUrl: marketing_url,
      description: description
    })
    puts "Updated version URLs for #{loc.dig("attributes", "locale")}."
  end

  review_notes = "Review notes for 1.0 (3): Subscriptions use StoreKit 2 with product IDs vitalos.premium.monthly, vitalos.premium.yearly, and vitalos.elite.monthly. The paywall is available at Settings > Subscription. Purchase buttons call Product.purchase() and Restore Purchases calls AppStore.sync(). The paywall shows each subscription title, duration, price, and functional Privacy Policy and Terms of Use (EULA) links. Legal links are also available in Settings > Legal & Safety. HealthKit (Apple Health) functionality is identified in Onboarding and Settings, and the app requests permission before reading steps, active energy, sleep analysis, and resting heart rate. No sign-in is required. VitalOS AI version 1.0 does not send check-ins, HealthKit data, voice transcripts, profile details, or other personal wellness data to a third-party AI service. Responses are generated in the app from local educational wellness rules."
  review_detail = related_resource("/appStoreVersions/#{version["id"]}/appStoreReviewDetail")
  if review_detail
    patch("appStoreReviewDetails", review_detail["id"], {
      demoAccountRequired: false,
      notes: review_notes
    })
  else
    post_review_detail({
      demoAccountRequired: false,
      notes: review_notes
    }, version["id"])
  end
  puts "Updated App Review notes."
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
    description: "Adaptive protocols, AI coach, and analytics.",
    review_screenshot: "AppStoreAssets/SubscriptionReview/vital-premium-monthly-review.png",
    promo_image: "AppStoreAssets/PromotionalImages/vital-premium-monthly-promo.png"
  },
  {
    product_id: "vitalos.premium.yearly",
    name: "Vital Premium Yearly",
    period: "ONE_YEAR",
    level: 2,
    description: "Yearly adaptive protocols, AI coach, and analytics.",
    review_screenshot: "AppStoreAssets/SubscriptionReview/vital-premium-yearly-review.png",
    promo_image: "AppStoreAssets/PromotionalImages/vital-premium-yearly-promo.png"
  },
  {
    product_id: "vitalos.elite.monthly",
    name: "Vital Elite Monthly",
    period: "ONE_MONTH",
    level: 1,
    description: "Premium AI models and deeper personalization.",
    review_screenshot: "AppStoreAssets/SubscriptionReview/vital-elite-monthly-review.png",
    promo_image: "AppStoreAssets/PromotionalImages/vital-elite-monthly-promo.png"
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

  promo_path = plan[:promo_image]
  existing_images = []
  each_page("/subscriptions/#{subscription["id"]}/images?limit=10") { |image| existing_images << image }
  existing_images.each do |image|
    delete_resource("subscriptionImages", image["id"])
    puts "Deleted old promotional image for #{plan[:product_id]}."
  end
  if File.exist?(promo_path)
    created_image = post("subscriptionImages", {
      fileName: File.basename(promo_path),
      fileSize: File.size(promo_path)
    }, {
      subscription: { data: { type: "subscriptions", id: subscription["id"] } }
    })["data"]
    upload_reserved_asset("subscriptionImages", created_image["id"], promo_path)
    puts "Uploaded promotional image for #{plan[:product_id]}."
  else
    puts "Promotional image missing for #{plan[:product_id]} at #{promo_path}."
  end

  next if related_resource("/subscriptions/#{subscription["id"]}/appStoreReviewScreenshot")

  screenshot_path = plan[:review_screenshot]
  unless File.exist?(screenshot_path)
    puts "Review screenshot missing for #{plan[:product_id]} at #{screenshot_path}."
    next
  end

  created_screenshot = post("subscriptionAppStoreReviewScreenshots", {
    fileName: File.basename(screenshot_path),
    fileSize: File.size(screenshot_path)
  }, {
    subscription: { data: { type: "subscriptions", id: subscription["id"] } }
  })["data"]

  Array(created_screenshot.dig("attributes", "uploadOperations")).each do |operation|
    upload_asset(operation, screenshot_path)
  end

  checksum = Digest::MD5.file(screenshot_path).base64digest
  patch("subscriptionAppStoreReviewScreenshots", created_screenshot["id"], {
    sourceFileChecksum: checksum,
    uploaded: true
  })
  puts "Uploaded App Review screenshot for #{plan[:product_id]}."
end

puts "Metadata automation complete."
