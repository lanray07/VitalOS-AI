import Foundation
import SwiftData

enum CoachingStyle: String, CaseIterable, Identifiable, Codable {
    case supportive = "Supportive"
    case direct = "Direct"
    case scientific = "Scientific"
    case calm = "Calm"

    var id: String { rawValue }
}

enum SubscriptionPlan: String, CaseIterable, Identifiable, Codable {
    case free = "Free"
    case premium = "Vital Premium"
    case elite = "Vital Elite"

    var id: String { rawValue }
}

struct WellnessMetric: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var value: Int
    var tintName: String
}

struct ProtocolRecommendation: Identifiable, Hashable, Codable {
    let id = UUID()
    var title: String
    var detail: String
    var category: String
}

struct ProjectionScenario: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var currentValue: Int
    var projectedValue: Int
    var caption: String
}

@Model
final class UserProfile {
    var id: UUID
    var ageRange: String
    var activityLevel: String
    var goals: String
    var coachingStyle: String
    var createdAt: Date

    init(ageRange: String, activityLevel: String, goals: String, coachingStyle: String, createdAt: Date = .now) {
        self.id = UUID()
        self.ageRange = ageRange
        self.activityLevel = activityLevel
        self.goals = goals
        self.coachingStyle = coachingStyle
        self.createdAt = createdAt
    }
}

@Model
final class DailyCheckIn {
    var id: UUID
    var mood: Int
    var stress: Int
    var focus: Int
    var energy: Int
    var sleepQuality: Int
    var motivation: Int
    var aiReflection: String
    var createdAt: Date

    init(mood: Int, stress: Int, focus: Int, energy: Int, sleepQuality: Int, motivation: Int, aiReflection: String = "", createdAt: Date = .now) {
        self.id = UUID()
        self.mood = mood
        self.stress = stress
        self.focus = focus
        self.energy = energy
        self.sleepQuality = sleepQuality
        self.motivation = motivation
        self.aiReflection = aiReflection
        self.createdAt = createdAt
    }
}

@Model
final class VitalScore {
    var id: UUID
    var score: Int
    var date: Date

    init(score: Int, date: Date = .now) {
        self.id = UUID()
        self.score = score
        self.date = date
    }
}

@Model
final class RecoveryScore {
    var id: UUID
    var score: Int
    var date: Date

    init(score: Int, date: Date = .now) {
        self.id = UUID()
        self.score = score
        self.date = date
    }
}

@Model
final class SleepRecord {
    var id: UUID
    var duration: Double
    var quality: Int
    var date: Date

    init(duration: Double, quality: Int, date: Date = .now) {
        self.id = UUID()
        self.duration = duration
        self.quality = quality
        self.date = date
    }
}

@Model
final class Habit {
    var id: UUID
    var title: String
    var completed: Bool
    var streak: Int

    init(title: String, completed: Bool = false, streak: Int = 0) {
        self.id = UUID()
        self.title = title
        self.completed = completed
        self.streak = streak
    }
}

@Model
final class VoiceTranscript {
    var id: UUID
    var transcript: String
    var aiResponse: String
    var createdAt: Date

    init(transcript: String, aiResponse: String, createdAt: Date = .now) {
        self.id = UUID()
        self.transcript = transcript
        self.aiResponse = aiResponse
        self.createdAt = createdAt
    }
}

@Model
final class DailyProtocol {
    var id: UUID
    var recommendations: String
    var createdAt: Date

    init(recommendations: String, createdAt: Date = .now) {
        self.id = UUID()
        self.recommendations = recommendations
        self.createdAt = createdAt
    }
}

@Model
final class SubscriptionState {
    var id: UUID
    var plan: String
    var isActive: Bool

    init(plan: SubscriptionPlan = .free, isActive: Bool = false) {
        self.id = UUID()
        self.plan = plan.rawValue
        self.isActive = isActive
    }
}
