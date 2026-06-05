import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case coach = "Coach"
    case insights = "Insights"
    case habits = "Habits"
    case settings = "Settings"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .dashboard: "gauge.with.dots.needle.67percent"
        case .coach: "waveform"
        case .insights: "chart.xyaxis.line"
        case .habits: "checklist"
        case .settings: "gearshape"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    switch tab {
                    case .dashboard:
                        DashboardView()
                    case .coach:
                        VoiceCoachView()
                    case .insights:
                        WellnessAnalyticsDashboardView()
                    case .habits:
                        HabitSystemView()
                    case .settings:
                        SettingsView()
                    }
                }
                .tabItem { Label(tab.rawValue, systemImage: tab.icon) }
            }
        }
        .tint(.electricBlue)
    }
}
