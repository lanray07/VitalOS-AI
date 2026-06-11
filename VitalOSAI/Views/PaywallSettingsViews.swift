import SwiftData
import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            ObsidianBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Unlock VitalOS")
                        .font(.system(size: 38, weight: .semibold, design: .rounded))
                    Text("Adaptive AI protocols, deeper analytics, voice coaching, and advanced personalization.")
                        .foregroundStyle(Color.softText)

                    if appState.storeService.isLoadingProducts {
                        ProgressView("Loading subscription options...")
                            .tint(Color.electricBlue)
                    }

                    if let purchaseError = appState.storeService.purchaseError {
                        Text(purchaseError)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.orange)
                    }

                    freePlanCard()
                    subscriptionCard(
                        title: "Vital Premium",
                        subtitle: "Adaptive protocols, voice coaching, advanced analytics, and future projections.",
                        features: ["Adaptive protocols", "AI coach", "Voice coaching", "Advanced analytics", "Future projections"],
                        productIDs: [
                            StoreKitSubscriptionService.premiumMonthlyProductID,
                            StoreKitSubscriptionService.premiumYearlyProductID
                        ],
                        plan: .premium
                    )
                    subscriptionCard(
                        title: "Vital Elite",
                        subtitle: "Premium AI models, deep analytics, advanced personalization, and elevated themes.",
                        features: ["Premium AI models", "Deep analytics", "Advanced personalization", "Premium themes"],
                        productIDs: [StoreKitSubscriptionService.eliteMonthlyProductID],
                        plan: .elite
                    )

                    Button {
                        Task { await appState.storeService.restorePurchases() }
                    } label: {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(20)
            }
        }
        .navigationTitle("Subscription")
        .task { await appState.storeService.loadProducts() }
    }

    private func freePlanCard() -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Free")
                            .font(.title3.weight(.semibold))
                        Text("Included")
                            .foregroundStyle(Color.vitalEmerald)
                    }
                    Spacer()
                    if appState.subscriptionPlan == .free {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.vitalEmerald)
                    }
                }
                ForEach(["Basic tracking", "Limited insights", "Limited AI interactions"], id: \.self) { feature in
                    Label(feature, systemImage: "checkmark")
                        .font(.subheadline)
                        .foregroundStyle(Color.softText)
                }
                Text("No purchase required.")
                    .font(.footnote)
                    .foregroundStyle(Color.softText)
            }
        }
    }

    private func subscriptionCard(title: String, subtitle: String, features: [String], productIDs: [String], plan: SubscriptionPlan) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.title3.weight(.semibold))
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.softText)
                    }
                    Spacer()
                    if appState.subscriptionPlan == plan {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.vitalEmerald)
                    }
                }
                ForEach(features, id: \.self) { feature in
                    Label(feature, systemImage: "checkmark")
                        .font(.subheadline)
                        .foregroundStyle(Color.softText)
                }
                VStack(spacing: 10) {
                    ForEach(productIDs, id: \.self) { productID in
                        purchaseButton(for: productID, plan: plan)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func purchaseButton(for productID: String, plan: SubscriptionPlan) -> some View {
        if let product = appState.storeService.product(for: productID) {
            Button {
                Task { await appState.storeService.purchase(product) }
            } label: {
                HStack {
                    Text(product.displayName)
                    Spacer()
                    Text(product.displayPrice)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(appState.storeService.isPurchasing)
            .buttonStyle(.borderedProminent)
            .tint(plan == .elite ? Color.vitalEmerald : Color.electricBlue)
        } else {
            Button {
                Task { await appState.storeService.loadProducts() }
            } label: {
                HStack {
                    Text("Subscription unavailable")
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(appState.storeService.isLoadingProducts || appState.storeService.isPurchasing)
            .buttonStyle(.borderedProminent)
            .tint(.gray)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var checkIns: [DailyCheckIn]
    @Query private var vitalScores: [VitalScore]
    @Query private var recoveryScores: [RecoveryScore]
    @Query private var sleepRecords: [SleepRecord]
    @Query private var habits: [Habit]
    @Query private var transcripts: [VoiceTranscript]
    @Query private var protocols: [DailyProtocol]
    @Query private var subscriptions: [SubscriptionState]
    @State private var healthEnabled = false
    @State private var voiceEnabled = true
    @State private var notificationsEnabled = false
    @State private var coachingStyle: CoachingStyle = .supportive
    @State private var showingDisclaimer = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTerms = false

    var body: some View {
        ZStack {
            ObsidianBackground()
            List {
                Section("Account") {
                    NavigationLink("Subscription") { PaywallView() }
                    Text("Current plan: \(appState.subscriptionPlan.rawValue)")
                }
                Section("Integrations") {
                    Toggle("HealthKit permissions", isOn: $healthEnabled)
                    Toggle("Voice settings", isOn: $voiceEnabled)
                    Toggle("Notifications", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            if enabled {
                                Task { await appState.requestNotificationPermission() }
                            }
                        }
                    NavigationLink("Widgets placeholder") { PlaceholderListView(title: "Widgets", items: WidgetPlaceholder().widgets) }
                    NavigationLink("Apple Watch placeholder") { PlaceholderListView(title: "Apple Watch", items: AppleWatchIntegrationPlaceholder().supportedFeatures) }
                }
                Section("Personalization") {
                    Picker("Coaching style", selection: $coachingStyle) {
                        ForEach(CoachingStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                }
                Section("AI & Privacy") {
                    AIPrivacyDisclosureView()
                }
                Section("Legal & Safety") {
                    Button("Privacy Policy") { showingPrivacyPolicy = true }
                    Button("Terms of Use") { showingTerms = true }
                    Button("Health Disclaimer") { showingDisclaimer = true }
                }
                Section {
                    Button(role: .destructive) {
                        deleteAllData()
                        appState.hasCompletedOnboarding = false
                    } label: {
                        Text("Delete all data")
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .alert("Health Disclaimer", isPresented: $showingDisclaimer) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("VitalOS AI provides wellness guidance, educational insights, and informational suggestions only. It is not medical advice, diagnosis, treatment, or emergency support.")
        }
        .alert("Privacy Policy", isPresented: $showingPrivacyPolicy) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("VitalOS AI stores profile preferences, check-ins, habits, voice transcripts, and subscription status in the app. Version 1.0 does not send personal wellness data to a third-party AI service. HealthKit, microphone, speech recognition, and notifications are only used after Apple system permission prompts.")
        }
        .alert("Terms of Use", isPresented: $showingTerms) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("VitalOS AI is for educational wellness guidance only. It is not medical advice, diagnosis, treatment, emergency support, or clinical monitoring. Subscription purchases are managed by Apple through StoreKit.")
        }
    }

    private func deleteAllData() {
        profiles.forEach(modelContext.delete)
        checkIns.forEach(modelContext.delete)
        vitalScores.forEach(modelContext.delete)
        recoveryScores.forEach(modelContext.delete)
        sleepRecords.forEach(modelContext.delete)
        habits.forEach(modelContext.delete)
        transcripts.forEach(modelContext.delete)
        protocols.forEach(modelContext.delete)
        subscriptions.forEach(modelContext.delete)
        appState.subscriptionPlan = .free
    }
}

struct AIPrivacyDisclosureView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("No third-party AI sharing in version 1.0", systemImage: "lock.shield")
                .font(.headline)
            Text("VitalOS AI generates wellness suggestions in this app using local educational rules. Check-ins, HealthKit data, voice transcripts, and profile details are not sent to a third-party AI provider in this version.")
                .font(.footnote)
                .foregroundStyle(Color.softText)
            Text("If remote AI is added in a future version, VitalOS will identify the provider, disclose the data categories first, and ask for permission before sending personal data.")
                .font(.caption)
                .foregroundStyle(Color.softText)
        }
        .padding(.vertical, 6)
    }
}

struct PlaceholderListView: View {
    var title: String
    var items: [String]

    var body: some View {
        FeatureScaffold(title: title) {
            ForEach(items, id: \.self) { item in
                GlassPanel {
                    HStack {
                        Image(systemName: "sparkle")
                            .foregroundStyle(Color.electricBlue)
                        Text(item)
                        Spacer()
                    }
                }
            }
        }
    }
}
