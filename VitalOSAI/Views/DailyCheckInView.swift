import SwiftData
import SwiftUI

struct DailyCheckInView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @State private var mood = 70.0
    @State private var stress = 35.0
    @State private var focus = 72.0
    @State private var energy = 68.0
    @State private var sleepQuality = 74.0
    @State private var motivation = 66.0
    @State private var reflection = ""
    @State private var isGenerating = false

    var body: some View {
        ZStack {
            ObsidianBackground()
            ScrollView {
                VStack(spacing: 16) {
                    sliderCard("Mood", value: $mood)
                    sliderCard("Stress", value: $stress)
                    sliderCard("Focus", value: $focus)
                    sliderCard("Energy", value: $energy)
                    sliderCard("Sleep Quality", value: $sleepQuality)
                    sliderCard("Motivation", value: $motivation)

                    if isGenerating {
                        ProgressView("Generating adaptive reflection...")
                            .tint(Color.electricBlue)
                    } else if !reflection.isEmpty {
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("AI Reflection")
                                    .font(.headline)
                                Text(reflection)
                                    .foregroundStyle(Color.softText)
                            }
                        }
                    }

                    PrimaryButton(title: "Save Check-In", systemImage: "checkmark.circle") {
                        Task { await save() }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Daily Check-In")
    }

    private func sliderCard(_ title: String, value: Binding<Double>) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                    Spacer()
                    Text("\(Int(value.wrappedValue))")
                        .foregroundStyle(Color.vitalEmerald)
                }
                Slider(value: value, in: 1...100)
                    .tint(Color.electricBlue)
            }
        }
    }

    private func save() async {
        isGenerating = true
        let checkIn = DailyCheckIn(mood: Int(mood), stress: Int(stress), focus: Int(focus), energy: Int(energy), sleepQuality: Int(sleepQuality), motivation: Int(motivation))
        reflection = await appState.wellnessInsightService.dailyReflection(for: checkIn)
        checkIn.aiReflection = reflection
        modelContext.insert(checkIn)
        modelContext.insert(VitalScore(score: Int((mood + focus + energy + sleepQuality + (100 - stress)) / 5)))
        modelContext.insert(RecoveryScore(score: appState.recoveryService.recoveryScore(sleepQuality: Int(sleepQuality), stress: Int(stress), activityLoad: 42)))
        appState.latestProtocol = appState.protocolService.generateDailyProtocol(checkIn: checkIn)
        appState.latestInsight = reflection
        isGenerating = false
    }
}
