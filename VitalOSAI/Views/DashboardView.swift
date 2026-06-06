import SwiftData
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appState: AppState
    @Query(sort: \VitalScore.date, order: .reverse) private var vitalScores: [VitalScore]
    @Query(sort: \RecoveryScore.date, order: .reverse) private var recoveryScores: [RecoveryScore]

    private var vitalScore: Int { vitalScores.first?.score ?? 72 }
    private var recoveryScore: Int { recoveryScores.first?.score ?? 68 }

    var body: some View {
        ZStack {
            ObsidianBackground()
            ScrollView {
                VStack(spacing: 18) {
                    VitalScoreRing(score: vitalScore)
                        .padding(.top, 16)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        RecoveryCard(score: recoveryScore)
                        SleepCard(score: 76)
                        MetricCard(metric: .init(title: "Energy", value: 81, tintName: "blue"))
                        MetricCard(metric: .init(title: "Stress", value: 34, tintName: "emerald"))
                    }
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("AI Insight")
                                .font(.headline)
                            Text(appState.latestInsight)
                                .font(.subheadline)
                                .foregroundStyle(Color.softText)
                            Text("Wellness guidance only. Not medical advice.")
                                .font(.caption)
                                .foregroundStyle(Color.vitalEmerald)
                        }
                    }
                    UpgradeBanner()
                    quickActions
                    VStack(spacing: 12) {
                        ForEach(appState.latestProtocol) { item in
                            ProtocolCard(item: item)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Today")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text(appState.subscriptionPlan.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vitalEmerald)
            }
        }
    }

    private var quickActions: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            NavigationLink(value: "checkin") { actionLabel("Daily Check-In", "slider.horizontal.3") }
            NavigationLink(value: "voice") { actionLabel("Voice Coach", "waveform") }
            NavigationLink(value: "recovery") { actionLabel("Recovery Plan", "heart.text.square") }
            NavigationLink(value: "sleep") { actionLabel("Sleep Review", "moon.zzz") }
            NavigationLink(value: "stress") { actionLabel("Stress Plan", "wind") }
            NavigationLink(value: "planner") { actionLabel("Focus Plan", "calendar.badge.clock") }
        }
        .navigationDestination(for: String.self) { route in
            switch route {
            case "checkin": DailyCheckInView()
            case "voice": VoiceCoachView()
            case "recovery": RecoveryIntelligenceView()
            case "sleep": SleepIntelligenceView()
            case "stress": StressIntelligenceView()
            case "planner": AdaptivePlannerView()
            default: WellnessAnalyticsDashboardView()
            }
        }
    }

    private func actionLabel(_ title: String, _ image: String) -> some View {
        Label(title, systemImage: image)
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
    }
}
