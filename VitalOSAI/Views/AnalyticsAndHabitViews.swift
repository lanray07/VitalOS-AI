import SwiftData
import SwiftUI

struct HabitSystemView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @State private var customHabit = ""

    private let starterHabits = ["Hydration", "Movement", "Exercise", "Sleep", "Mindfulness", "Nutrition placeholder"]

    var body: some View {
        ZStack {
            ObsidianBackground()
            ScrollView {
                VStack(spacing: 14) {
                    if habits.isEmpty {
                        starterHabitsPanel
                    }

                    ForEach(habits) { habit in
                        habitRow(habit)
                    }

                    customHabitPanel
                }
                .padding(20)
            }
        }
        .navigationTitle("Habits")
    }

    private var starterHabitsPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("Build your consistency layer")
                    .font(.headline)
                Text("Track small wellness habits locally and use them to personalize protocols.")
                    .foregroundStyle(Color.softText)
                PrimaryButton(title: "Add Starter Habits", systemImage: "plus") {
                    starterHabits.forEach { modelContext.insert(Habit(title: $0)) }
                }
            }
        }
    }

    private func habitRow(_ habit: Habit) -> some View {
        GlassPanel {
            HStack {
                Button {
                    habit.completed.toggle()
                    habit.streak = habit.completed ? habit.streak + 1 : max(0, habit.streak - 1)
                } label: {
                    Image(systemName: habit.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(habit.completed ? Color.vitalEmerald : Color.softText)
                }
                VStack(alignment: .leading) {
                    Text(habit.title)
                    Text("\(habit.streak) day streak")
                        .font(.caption)
                        .foregroundStyle(Color.softText)
                }
                Spacer()
            }
        }
    }

    private var customHabitPanel: some View {
        GlassPanel {
            HStack {
                TextField("Custom habit", text: $customHabit)
                Button {
                    guard !customHabit.isEmpty else { return }
                    modelContext.insert(Habit(title: customHabit))
                    customHabit = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
    }
}

struct WellnessAnalyticsDashboardView: View {
    @State private var showingShare = false
    private let report = "Vital Score: 78\nRecovery: 68\nSleep: 76\nConsistency: 82\n\nAll content is educational wellness information and is not medical advice."

    var body: some View {
        ZStack {
            ObsidianBackground()
            ScrollView {
                VStack(spacing: 16) {
                    AnalyticsChartCard(title: "Vital Score", values: [68, 70, 73, 72, 78, 76, 80])
                    AnalyticsChartCard(title: "Sleep", values: [66, 70, 72, 76, 74, 78, 76], tint: Color.vitalEmerald)
                    AnalyticsChartCard(title: "Recovery", values: [62, 64, 67, 68, 70, 66, 68], tint: Color.vitalEmerald)
                    AnalyticsChartCard(title: "Stress", values: [48, 43, 51, 40, 39, 37, 34])
                    MetricCard(metric: .init(title: "Consistency", value: 82, tintName: "emerald"))
                    NavigationLink {
                        FutureProjectionEngineView()
                    } label: {
                        actionLabel("View Projections", "chart.line.uptrend.xyaxis")
                    }
                    NavigationLink {
                        VitalScoreEngineView()
                    } label: {
                        actionLabel("Vital Score Engine", "gauge.with.dots.needle.67percent")
                    }
                    NavigationLink {
                        AIWellnessAssistantView()
                    } label: {
                        actionLabel("AI Wellness Assistant", "sparkles")
                    }
                    NavigationLink {
                        HormonalInsightsPlaceholderView()
                    } label: {
                        actionLabel("Hormonal Insights", "calendar")
                    }
                    NavigationLink {
                        ShareableHealthCardsView()
                    } label: {
                        actionLabel("Shareable Cards", "square.and.arrow.up")
                    }
                    PrimaryButton(title: "Export Wellness PDF", systemImage: "doc.richtext") {
                        showingShare = true
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Insights")
        .sheet(isPresented: $showingShare) {
            if let url = WellnessReportExporter.makePDF(summary: report) {
                ShareSheet(items: [url])
            }
        }
    }

    private func actionLabel(_ title: String, _ image: String) -> some View {
        Label(title, systemImage: image)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct AIWellnessAssistantView: View {
    var body: some View {
        FeatureScaffold(title: "AI Assistant") {
            ProtocolCard(item: .init(title: "Daily reflection", detail: "Your habits suggest a steady day. Keep your recovery anchors visible and adjust intensity based on energy.", category: "Reflection"))
            ProtocolCard(item: .init(title: "Weekly review", detail: "Consistency is trending up. Sleep timing remains the highest-leverage wellness behavior.", category: "Review"))
            ProtocolCard(item: .init(title: "Habit insight", detail: "Hydration and movement completion correlate with stronger afternoon focus in your local data.", category: "Insight"))
        }
    }
}

struct ShareableHealthCardsView: View {
    var body: some View {
        FeatureScaffold(title: "Share Cards") {
            ShareCardPreview(title: "Recovery Milestone", value: "68", caption: "A steady recovery day powered by better consistency.")
            ShareCardPreview(title: "Sleep Win", value: "7.4h", caption: "Consistent sleep timing supported a stronger morning.")
            ShareCardPreview(title: "Consistency Streak", value: "12", caption: "Small habits, repeated daily.")
        }
    }
}
