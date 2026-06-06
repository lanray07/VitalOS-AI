import SwiftUI

struct VitalScoreEngineView: View {
    var body: some View {
        FeatureScaffold(title: "Vital Score Engine") {
            VitalScoreRing(score: 78, title: "Adaptive")
            AnalyticsChartCard(title: "Score Trend", values: [68, 70, 71, 76, 73, 78, 80], tint: Color.vitalEmerald)
            ProtocolCard(item: .init(title: "Consistency lift", detail: "Your score improves when sleep timing, movement, and check-ins stay consistent.", category: "Score"))
        }
    }
}

struct RecoveryIntelligenceView: View {
    var body: some View {
        FeatureScaffold(title: "Recovery Intelligence") {
            VitalScoreRing(score: 68, title: "Recovery", tint: Color.vitalEmerald)
            ProtocolCard(item: .init(title: "Recovery adjustment", detail: "Consider lighter activity today and prioritize an earlier recovery window.", category: "Recovery"))
            AnalyticsChartCard(title: "Recovery Trend", values: [62, 65, 60, 68, 71, 66, 68], tint: Color.vitalEmerald)
        }
    }
}

struct SleepIntelligenceView: View {
    var body: some View {
        FeatureScaffold(title: "Sleep Intelligence") {
            SleepCard(score: 76)
            ProtocolCard(item: .init(title: "Bedtime recommendation", detail: "A consistent wind-down may support better sleep quality. Estimated sleep debt: 0.9 hours.", category: "Sleep"))
            AnalyticsChartCard(title: "Sleep Quality", values: [70, 74, 72, 76, 78, 73, 76])
        }
    }
}

struct StressIntelligenceView: View {
    var body: some View {
        FeatureScaffold(title: "Stress Intelligence") {
            MetricCard(metric: .init(title: "Stress Load", value: 34, tintName: "emerald"))
            ProtocolCard(item: .init(title: "Breathing recommendation", detail: "Try a short breathing reset before your next high-demand block.", category: "Stress"))
            AnalyticsChartCard(title: "Stress Trend", values: [48, 44, 51, 39, 36, 42, 34], tint: Color.vitalEmerald)
        }
    }
}

struct HormonalInsightsPlaceholderView: View {
    @State private var cyclePhase = "Optional"
    @State private var symptoms = ""
    @State private var notes = ""

    var body: some View {
        FeatureScaffold(title: "Hormonal Insights") {
            GlassPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Cycle phase", selection: $cyclePhase) {
                        ForEach(["Optional", "Menstrual", "Follicular", "Ovulatory", "Luteal"], id: \.self, content: Text.init)
                    }
                    TextField("Symptoms placeholder", text: $symptoms)
                    TextField("Wellness notes", text: $notes)
                    Text("Educational wellness insights only. This module does not diagnose, treat, or make medical claims.")
                        .font(.caption)
                        .foregroundStyle(Color.softText)
                }
            }
        }
    }
}

struct AdaptivePlannerView: View {
    var body: some View {
        FeatureScaffold(title: "Adaptive Planner") {
            ProtocolCard(item: .init(title: "Morning plan", detail: "Check energy, get daylight, and schedule the most demanding task during your strongest focus window.", category: "Morning"))
            ProtocolCard(item: .init(title: "Afternoon adjustment", detail: "Add movement and hydration after long focus blocks to support steadier energy.", category: "Afternoon"))
            ProtocolCard(item: .init(title: "Evening recovery", detail: "Protect a wind-down period and reduce optional stimulation before sleep.", category: "Evening"))
        }
    }
}

struct FutureProjectionEngineView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        FeatureScaffold(title: "Future Projections") {
            ForEach(appState.projectionService.scenarios()) { scenario in
                ProjectionCard(scenario: scenario)
            }
            Text("Projection visuals are estimates based on wellness inputs and habit assumptions.")
                .font(.caption)
                .foregroundStyle(Color.softText)
        }
    }
}

struct FeatureScaffold<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            ObsidianBackground()
            ScrollView {
                VStack(spacing: 16) {
                    content
                }
                .padding(20)
            }
        }
        .navigationTitle(title)
    }
}
