import SwiftData
import SwiftUI

@main
struct VitalOSAIApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [
            UserProfile.self,
            DailyCheckIn.self,
            VitalScore.self,
            RecoveryScore.self,
            SleepRecord.self,
            Habit.self,
            VoiceTranscript.self,
            DailyProtocol.self,
            SubscriptionState.self
        ])
    }
}
