import SwiftUI
import UserNotifications

class DashboardViewModel: ObservableObject {
    // Shared medication list
    static let commonMedsList = ["Ibuprofen", "Tylenol", "Mucinex", "Zyrtec", "Amoxicillin", "Prednisone"]

    @Published var entries: [Entry] = []
    @Published var selectedMed: String = DashboardViewModel.commonMedsList.first!
    let commonMeds = DashboardViewModel.commonMedsList
    let hydrationGoal = 950.0
    let nourishmentGoal = 1065.0

    var hydrationTotal: Double { entries.reduce(0) { $0 + $1.hydration } }
    var nourishmentTotal: Double { entries.reduce(0) { $0 + $1.nourishment } }

    func logFeed(volume: Double) {
        entries.append(Entry(date: Date(), hydration: volume, nourishment: 0))
    }

    func logWater(volume: Double) {
        entries.append(Entry(date: Date(), hydration: volume, nourishment: 0))
    }

    func logMedication(dose: Double) {
        // TODO: schedule medication reminders
    }

    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
