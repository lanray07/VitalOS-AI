import SwiftData
import SwiftUI

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

                    planCard(title: "Free", price: "Included", features: ["Basic tracking", "Limited insights", "Limited AI interactions"], plan: .free)
                    planCard(title: "Vital Premium", price: "£12.99/mo or £99.99/yr", features: ["Adaptive protocols", "AI coach", "Voice coaching", "Advanced analytics", "Future projections"], plan: .premium)
                    planCard(title: "Vital Elite", price: "£24.99/mo", features: ["Premium AI models", "Deep analytics", "Advanced personalization", "Premium themes"], plan: .elite)
                }
                .padding(20)
            }
        }
        .navigationTitle("Subscription")
        .task { await appState.storeService.loadProducts() }
    }

    private func planCard(title: String, price: String, features: [String], plan: SubscriptionPlan) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.title3.weight(.semibold))
                        Text(price)
                            .foregroundStyle(Color.vitalEmerald)
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
                Button("Select \(title)") {
                    appState.subscriptionPlan = plan
                    appState.storeService.purchasePlaceholder(plan: plan)
                }
                .buttonStyle(.borderedProminent)
                .tint(plan == .elite ? .vitalEmerald : .electricBlue)
            }
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
                Section("Legal & Safety") {
                    Button("Privacy Policy") {}
                    Button("Terms of Use") {}
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
