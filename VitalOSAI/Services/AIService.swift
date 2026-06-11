import Foundation

protocol AIService {
    func generateInsight(module: String, context: String) async throws -> String
    func generateProtocol(from checkIn: DailyCheckIn?) -> [ProtocolRecommendation]
    func generateVoiceResponse(transcript: String) async throws -> String
    func defaultProtocol() -> [ProtocolRecommendation]
}

final class MockAIService: AIService {
    private let systemPrompt = "You are VitalOS AI, a wellness optimization assistant. Help users improve sleep, recovery, consistency, and daily performance through educational wellness insights. Do not provide medical advice, diagnosis, treatment, or emergency health guidance."

    func generateInsight(module: String, context: String) async throws -> String {
        try await Task.sleep(nanoseconds: 350_000_000)
        return "\(module): Based on your recent wellness signals, consider one small adjustment today. These are educational wellness suggestions, not medical advice."
    }

    func generateProtocol(from checkIn: DailyCheckIn?) -> [ProtocolRecommendation] {
        guard let checkIn else { return defaultProtocol() }
        var protocolItems = defaultProtocol()
        if checkIn.energy < 45 || checkIn.sleepQuality < 45 {
            protocolItems.insert(.init(title: "Lower intensity", detail: "Recovery looks lower today. Consider lighter movement and an earlier wind-down window.", category: "Recovery"), at: 0)
        }
        if checkIn.stress > 65 {
            protocolItems.append(.init(title: "Breathing reset", detail: "Try two 3-minute breathing breaks between demanding tasks to support steadier focus.", category: "Stress"))
        }
        return protocolItems
    }

    func generateVoiceResponse(transcript: String) async throws -> String {
        try await Task.sleep(nanoseconds: 450_000_000)
        let lower = transcript.lowercased()
        if lower.contains("exhausted") || lower.contains("slept badly") {
            return "It sounds like your system may benefit from a gentler day. Consider reducing optional intensity, hydrating early, taking daylight exposure, and protecting tonight's sleep window. This is wellness guidance only."
        }
        if lower.contains("stress") {
            return "That sounds heavy. Consider a short breathing reset, a narrowed priority list, and a recovery block later today. If stress feels unmanageable or persistent, consider speaking with a qualified professional."
        }
        return "I hear you. A useful next step may be to choose one stabilizing habit for the next hour: water, movement, daylight, or a focused pause. This is informational wellness guidance."
    }

    func defaultProtocol() -> [ProtocolRecommendation] {
        [
            .init(title: "Morning calibration", detail: "Get daylight and log your energy before planning high-focus work.", category: "Focus"),
            .init(title: "Hydration anchor", detail: "Pair water with your first two transitions of the day.", category: "Hydration"),
            .init(title: "Movement pulse", detail: "Add a low-friction movement break between long sitting blocks.", category: "Activity"),
            .init(title: "Sleep target", detail: "Aim for a consistent wind-down window and reduce late stimulation.", category: "Sleep")
        ]
    }
}

final class WellnessInsightService {
    private let aiService: AIService
    init(aiService: AIService) { self.aiService = aiService }

    func dailyReflection(for checkIn: DailyCheckIn?) async -> String {
        (try? await aiService.generateInsight(module: "Daily Reflection", context: checkIn.map { "Energy \($0.energy), stress \($0.stress)" } ?? "Baseline")) ?? "Log a check-in to unlock more personalized wellness guidance."
    }
}

final class ProtocolGenerationService {
    private let aiService: AIService
    init(aiService: AIService) { self.aiService = aiService }

    func generateBaselineProtocol() -> [ProtocolRecommendation] {
        aiService.defaultProtocol()
    }

    func generateDailyProtocol(checkIn: DailyCheckIn?) -> [ProtocolRecommendation] {
        aiService.generateProtocol(from: checkIn)
    }
}

final class RecoveryAnalysisService {
    private let aiService: AIService
    init(aiService: AIService) { self.aiService = aiService }

    func recoveryScore(sleepQuality: Int, stress: Int, activityLoad: Int) -> Int {
        max(1, min(100, Int(Double(sleepQuality) * 0.45 + Double(100 - stress) * 0.35 + Double(100 - activityLoad) * 0.2)))
    }
}

final class SleepAnalysisService {
    private let aiService: AIService
    init(aiService: AIService) { self.aiService = aiService }

    func sleepDebtEstimate(hours: Double, target: Double = 8) -> Double {
        max(0, target - hours)
    }
}

final class ProjectionEngineService {
    private let aiService: AIService
    init(aiService: AIService) { self.aiService = aiService }

    func scenarios() -> [ProjectionScenario] {
        [
            .init(title: "If current habits continue", currentValue: 72, projectedValue: 74, caption: "Estimated trend from current consistency."),
            .init(title: "If sleep improves", currentValue: 72, projectedValue: 84, caption: "Estimate assumes a steadier wind-down and sleep window."),
            .init(title: "If stress resets improve", currentValue: 58, projectedValue: 70, caption: "Estimate assumes short daily recovery pauses.")
        ]
    }
}
