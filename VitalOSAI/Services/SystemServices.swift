import Foundation
import StoreKit
import SwiftUI
import UIKit
import UserNotifications

@MainActor
final class StoreKitSubscriptionService: ObservableObject {
    @Published var products: [Product] = []
    @Published var currentPlan: SubscriptionPlan = .free

    let productIDs = [
        "vitalos.premium.monthly",
        "vitalos.premium.yearly",
        "vitalos.elite.monthly"
    ]

    func loadProducts() async {
        products = (try? await Product.products(for: productIDs)) ?? []
    }

    func purchasePlaceholder(plan: SubscriptionPlan) {
        currentPlan = plan
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
