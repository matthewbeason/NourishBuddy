import SwiftUI
import CoreData

struct EditDailyGoalSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var feedsTarget: Int = 6
    @State private var ouncesPerFeedTarget: Double = 7.0
    @State private var reasonQuick: ReasonQuick = .none
    @State private var reasonText: String = ""

    enum ReasonQuick: String, CaseIterable, Identifiable {
        case none = "None"
        case sick = "Sick"
        case poorTolerance = "Poor tolerance"
        case trialingHigher = "Trialing higher"
        case other = "Other"
        var id: String { rawValue }
    }

    private var totalTarget: Double { Double(feedsTarget) * ouncesPerFeedTarget }
    private var todayStart: Date { Calendar.current.startOfDay(for: Date()) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Today") {
                    Stepper(value: $feedsTarget, in: 0...12) {
                        Text("Feeds: \(feedsTarget)")
                    }
                    Stepper(value: $ouncesPerFeedTarget, in: 0...16, step: 0.5) {
                        Text(String(format: "Ounces per feed: %.1f", ouncesPerFeedTarget))
                    }
                    HStack {
                        Text("Total target")
                        Spacer()
                        Text("\(Int(totalTarget)) oz")
                            .font(.headline)
                    }
                }

                Section("Reason (optional)") {
                    Picker("Reason", selection: $reasonQuick) {
                        ForEach(ReasonQuick.allCases) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("Details (optional)", text: $reasonText)
                }

                Section {
                    Button("Use Baseline") { useBaseline() }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                }
            }
            .navigationTitle("Edit Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveDailyOverride() }
                }
            }
            .onAppear { loadExisting() }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func loadExisting() {
        guard let model = viewContext.persistentStoreCoordinator?.managedObjectModel else { return }
        guard model.entitiesByName["FeedingDailyGoalEntity"] != nil else { return }
        let req = NSFetchRequest<NSManagedObject>(entityName: "FeedingDailyGoalEntity")
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "day == %@", todayStart as NSDate)
        let results = try? viewContext.fetch(req)
        if let obj = results?.first {
            if let feeds = obj.value(forKey: "feedsTarget") as? Int16 { feedsTarget = Int(feeds) }
            if let oz = obj.value(forKey: "ouncesPerFeedTarget") as? Double { ouncesPerFeedTarget = oz }
            if let reason = obj.value(forKey: "reason") as? String {
                reasonText = reason
                // Try to map back to quick reason
                if let match = ReasonQuick.allCases.first(where: { reason.lowercased().contains($0.rawValue.lowercased()) }) {
                    reasonQuick = match
                }
            }
        }
    }

    private func saveDailyOverride() {
        guard let model = viewContext.persistentStoreCoordinator?.managedObjectModel else { return }
        guard let entity = model.entitiesByName["FeedingDailyGoalEntity"] else { return }
        let req = NSFetchRequest<NSManagedObject>(entityName: entity.name!)
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "day == %@", todayStart as NSDate)
        let obj: NSManagedObject
        let existing = (try? viewContext.fetch(req))?.first
        if let e = existing {
            obj = e
        } else {
            obj = NSManagedObject(entity: entity, insertInto: viewContext)
            obj.setValue(UUID(), forKey: "id")
            obj.setValue(todayStart, forKey: "day")
        }
        obj.setValue(Int16(feedsTarget), forKey: "feedsTarget")
        obj.setValue(ouncesPerFeedTarget, forKey: "ouncesPerFeedTarget")
        let combinedReason = reasonQuick == .none ? reasonText : (reasonText.isEmpty ? reasonQuick.rawValue : "\(reasonQuick.rawValue): \(reasonText)")
        obj.setValue(combinedReason.isEmpty ? nil : combinedReason, forKey: "reason")
        try? viewContext.save()
        dismiss()
    }

    private func useBaseline() {
        guard let model = viewContext.persistentStoreCoordinator?.managedObjectModel else { return }
        guard model.entitiesByName["FeedingDailyGoalEntity"] != nil else { dismiss(); return }
        let req = NSFetchRequest<NSManagedObject>(entityName: "FeedingDailyGoalEntity")
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "day == %@", todayStart as NSDate)
        if let obj = (try? viewContext.fetch(req))?.first {
            viewContext.delete(obj)
            try? viewContext.save()
        }
        dismiss()
    }
}
