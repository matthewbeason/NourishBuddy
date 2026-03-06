import SwiftUI
import CoreData

struct EditBaselinePlanSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var feedsPerDay: Int = 6
    @State private var ouncesPerFeed: Double = 7.0
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Baseline Plan") {
                    Stepper(value: $feedsPerDay, in: 0...12) {
                        Text("Feeds per day: \(feedsPerDay)")
                    }
                    Stepper(value: $ouncesPerFeed, in: 0...16, step: 0.5) {
                        Text(String(format: "Ounces per feed: %.1f", ouncesPerFeed))
                    }
                }

                Section("Note (optional)") {
                    TextField("Note", text: $note)
                }
            }
            .navigationTitle("Edit Baseline Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { savePlan() }
                }
            }
            .onAppear { loadLatest() }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func loadLatest() {
        guard let model = viewContext.persistentStoreCoordinator?.managedObjectModel else { return }
        guard model.entitiesByName["FeedingGoalPlanEntity"] != nil else { return }
        let req = NSFetchRequest<NSManagedObject>(entityName: "FeedingGoalPlanEntity")
        req.fetchLimit = 1
        req.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        if let obj = try? viewContext.fetch(req).first {
            if let feeds = obj.value(forKey: "feedsPerDay") as? Int16 { feedsPerDay = Int(feeds) }
            if let oz = obj.value(forKey: "ouncesPerFeed") as? Double { ouncesPerFeed = oz }
            if let n = obj.value(forKey: "note") as? String { note = n }
        }
    }

    private func savePlan() {
        guard let model = viewContext.persistentStoreCoordinator?.managedObjectModel else { return }
        guard let entity = model.entitiesByName["FeedingGoalPlanEntity"] else { return }
        let obj = NSManagedObject(entity: entity, insertInto: viewContext)
        obj.setValue(UUID(), forKey: "id")
        obj.setValue(Date(), forKey: "startDate")
        obj.setValue(Int16(feedsPerDay), forKey: "feedsPerDay")
        obj.setValue(ouncesPerFeed, forKey: "ouncesPerFeed")
        obj.setValue(note.isEmpty ? nil : note, forKey: "note")
        try? viewContext.save()
        dismiss()
    }
}
