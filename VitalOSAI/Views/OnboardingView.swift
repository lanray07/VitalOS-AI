import SwiftData
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @State private var ageRange = "25-34"
    @State private var activityLevel = "Moderate"
    @State private var sleepGoal = true
    @State private var productivityGoal = true
    @State private var stressGoal = true
    @State private var fitnessGoal = false
    @State private var coachingStyle: CoachingStyle = .supportive
    @State private var connectHealth = false
    @State private var connectWatch = false
    @State private var connectSleep = false

    private let ageRanges = ["18-24", "25-34", "35-44", "45-54", "55+"]
    private let activityLevels = ["Low", "Moderate", "High", "Athlete"]

    var body: some View {
        ZStack {
            ObsidianBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("VitalOS AI")
                            .font(.system(size: 42, weight: .semibold, design: .rounded))
                        Text("The operating system for your health.")
                            .font(.title3)
                            .foregroundStyle(Color.softText)
                        Text("Your body changes every day. Your plan should too.")
                            .font(.subheadline)
                            .foregroundStyle(Color.vitalEmerald)
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 16) {
                            Picker("Age range", selection: $ageRange) {
                                ForEach(ageRanges, id: \.self, content: Text.init)
                            }
                            Picker("Activity level", selection: $activityLevel) {
                                ForEach(activityLevels, id: \.self, content: Text.init)
                            }
                            Picker("Coaching style", selection: $coachingStyle) {
                                ForEach(CoachingStyle.allCases) { style in
                                    Text(style.rawValue).tag(style)
                                }
                            }
                        }
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Goals")
                                .font(.headline)
                            Toggle("Improve sleep quality", isOn: $sleepGoal)
                            Toggle("Optimize daily performance", isOn: $productivityGoal)
                            Toggle("Reduce burnout risk", isOn: $stressGoal)
                            Toggle("Personalize fitness guidance", isOn: $fitnessGoal)
                        }
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Optional Connections")
                                .font(.headline)
                            Toggle("Apple Health", isOn: $connectHealth)
                            Toggle("Apple Watch placeholder", isOn: $connectWatch)
                            Toggle("Sleep tracking placeholder", isOn: $connectSleep)
                        }
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Wellness guidance only", systemImage: "checkmark.seal")
                            Text("VitalOS AI is not medical advice, not a diagnostic tool, and does not replace healthcare professionals. Consult a qualified professional when appropriate.")
                                .font(.footnote)
                                .foregroundStyle(Color.softText)
                        }
                    }

                    PrimaryButton(title: "Generate Vital Profile", systemImage: "sparkles") {
                        saveProfile()
                    }
                }
                .padding(20)
            }
        }
    }

    private func saveProfile() {
        let selectedGoals = [
            sleepGoal ? "Sleep" : nil,
            productivityGoal ? "Productivity" : nil,
            stressGoal ? "Stress Management" : nil,
            fitnessGoal ? "Fitness" : nil
        ].compactMap { $0 }.joined(separator: ", ")
        modelContext.insert(UserProfile(ageRange: ageRange, activityLevel: activityLevel, goals: selectedGoals, coachingStyle: coachingStyle.rawValue))
        modelContext.insert(VitalScore(score: 72))
        modelContext.insert(RecoveryScore(score: 68))
        modelContext.insert(SubscriptionState())
        appState.completeOnboarding()
    }
}
