import Foundation
import StoreKit
import SwiftUI
import UIKit
import UserNotifications

private enum StoreKitSubscriptionError: Error {
    case unverifiedTransaction
}

@MainActor
final class StoreKitSubscriptionService: ObservableObject {
    static let premiumMonthlyProductID = "vitalos.premium.monthly"
    static let premiumYearlyProductID = "vitalos.premium.yearly"
    static let eliteMonthlyProductID = "vitalos.elite.monthly"

    @Published var products: [Product] = []
    @Published var currentPlan: SubscriptionPlan = .free
    @Published var isLoadingProducts = false
    @Published var isPurchasing = false
    @Published var purchaseError: String?

    static let productIDs = [
        premiumMonthlyProductID,
        premiumYearlyProductID,
        eliteMonthlyProductID
    ]

    private var transactionUpdatesTask: Task<Void, Never>?

    init() {
        transactionUpdatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.updatePurchasedSubscriptions()
                }
            }
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let storeProducts = try await Product.products(for: Self.productIDs)
            products = storeProducts.sorted { lhs, rhs in
                let lhsIndex = Self.productIDs.firstIndex(of: lhs.id) ?? Self.productIDs.count
                let rhsIndex = Self.productIDs.firstIndex(of: rhs.id) ?? Self.productIDs.count
                return lhsIndex < rhsIndex
            }
            purchaseError = products.isEmpty ? "Subscriptions are not available yet. Confirm the products are configured and submitted in App Store Connect." : nil
            await updatePurchasedSubscriptions()
        } catch {
            products = []
            purchaseError = "Subscriptions could not be loaded. Please try again."
        }
    }

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                currentPlan = Self.plan(for: transaction.productID)
                await transaction.finish()
                await updatePurchasedSubscriptions()
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Purchase is pending approval."
            @unknown default:
                purchaseError = "Purchase could not be completed."
            }
        } catch {
            purchaseError = "Purchase could not be completed. Please try again."
        }
    }

    func restorePurchases() async {
        purchaseError = nil
        do {
            try await AppStore.sync()
            await updatePurchasedSubscriptions()
        } catch {
            purchaseError = "Purchases could not be restored right now."
        }
    }

    func updatePurchasedSubscriptions() async {
        var resolvedPlan: SubscriptionPlan = .free
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            let plan = Self.plan(for: transaction.productID)
            if plan == .elite {
                resolvedPlan = .elite
                break
            }
            if plan == .premium {
                resolvedPlan = .premium
            }
        }
        currentPlan = resolvedPlan
    }

    static func plan(for productID: String) -> SubscriptionPlan {
        switch productID {
        case eliteMonthlyProductID:
            return .elite
        case premiumMonthlyProductID, premiumYearlyProductID:
            return .premium
        default:
            return .free
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreKitSubscriptionError.unverifiedTransaction
        }
    }
}

final class LocalNotificationService {
    func requestAuthorization() async throws {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    }

    func scheduleWellnessReminder() {
        let content = UNMutableNotificationContent()
        content.title = "VitalOS check-in"
        content.body = "Log your wellness signals to adapt today's protocol."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "wellness-reminder", content: content, trigger: trigger))
    }
}

enum WellnessReportExporter {
    static func makePDF(summary: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appending(path: "VitalOS-Wellness-Report.pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                let title = "VitalOS AI Wellness Report"
                title.draw(at: CGPoint(x: 48, y: 52), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 24), .foregroundColor: UIColor.black])
                summary.draw(in: CGRect(x: 48, y: 96, width: 516, height: 560), withAttributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.darkGray])
            }
            return url
        } catch {
            return nil
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
