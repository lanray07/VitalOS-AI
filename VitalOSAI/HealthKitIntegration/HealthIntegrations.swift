import Foundation
import HealthKit

struct WearableSnapshot {
    var sleepHours: Double
    var activeEnergy: Double
    var restingHeartRate: Double?
    var recoveryIndicator: Int?
}

final class HealthKitIntegrationService {
    private let store = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)
        ].compactMap { $0 }.reduce(into: Set<HKObjectType>()) { $0.insert($1) }

        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    func latestSnapshotPlaceholder() -> WearableSnapshot {
        WearableSnapshot(sleepHours: 7.1, activeEnergy: 420, restingHeartRate: nil, recoveryIndicator: nil)
    }
}
