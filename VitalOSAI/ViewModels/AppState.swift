import Foundation
import UserNotifications

@MainActor
final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding = false
    @Published var subscriptionPlan: SubscriptionPlan = .free
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var latestProtocol: [ProtocolRecommendation] = []
    @Published var latestInsight = "Your plan adapts as your recovery, sleep, stress, and daily inputs change."

    let aiService: AIService = MockAIService()
    let protocolService: ProtocolGenerationService
    let recoveryService: RecoveryAnalysisService
    let sleepService: SleepAnalysisService
    let projectionService: ProjectionEngineService
    let wellnessInsightService: WellnessInsightService
    let storeService = StoreKitSubscriptionService()
    let notificationService = LocalNotificationService()

    init() {
        let mock = MockAIService()
        self.protocolService = ProtocolGenerationService(aiService: mock)
        self.recoveryService = RecoveryAnalysisService(aiService: mock)
        self.sleepService = SleepAnalysisService(aiService: mock)
        self.projectionService = ProjectionEngineService(aiService: mock)
        self.wellnessInsightService = WellnessInsightService(aiService: mock)
        self.latestProtocol = mock.defaultProtocol()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        latestProtocol = protocolService.generateBaselineProtocol()
    }

    func requestNotificationPermission() async {
        do {
            try await notificationService.requestAuthorization()
        } catch {
            errorMessage = "Notifications could not be enabled right now."
        }
    }
}
