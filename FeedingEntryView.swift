import SwiftUI
import CoreData

struct FeedingEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FeedingEntryEntity.date, ascending: false)],
        animation: .default)
    private var feedings: FetchedResults<FeedingEntryEntity>
    
    private struct Kinds {
        static let formula = "formula"
        static let water = "water"
        static let flush = "flush"
        static let all = "all"
        static let kinds: [String] = [formula, water, flush]
    }
    
    private let kindDisplay: [String: String] = [
        Kinds.all: "All",
        Kinds.formula: "Formula",
        Kinds.water: "Water",
        Kinds.flush: "Flush"
    ]
    
    @State private var showingAdd = false
    @State private var newDate = Date()
    @State private var volumeText = ""
    @State private var selectedKind = Kinds.formula
    @State private var notesText = ""
    @State private var selectedFilter = Kinds.all
    @State private var showDuplicateAlert = false
    
    private var parsedVolume: Double? {
        let trimmed = volumeText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        let formatter = NumberFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.numberStyle = .decimal
        if let number = formatter.number(from: trimmed) {
            return number.doubleValue
        }
        return Double(trimmed)
    }
    
    private var filteredFeedings: [FeedingEntryEntity] {
        let items: [FeedingEntryEntity] = Array(feedings)
        let filter: String = selectedFilter
        if filter == Kinds.formula {
            return items.filter { entry in
                let kind: String = entry.kind ?? Kinds.formula
                 return kind == Kinds.formula
            }
        } else if filter == Kinds.water {
            return items.filter { entry in
                let kind: String = entry.kind ?? Kinds.formula
                return kind == Kinds.water
            }
        } else if filter == Kinds.flush {
            return items.filter { entry in
                let kind: String = entry.kind ?? Kinds.formula
                return kind == Kinds.flush
            }
        } else {
            return items
        }
    }

    var totalVolume: Double {
        filteredFeedings.reduce(0) { partialResult, entry in
            partialResult + entry.volume
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Step 5: ForEach over Array(feedings) with placeholder row
                ForEach(filteredFeedings, id: \.objectID) { entry in
                    FeedingEntryRow(entry: entry, kindDisplay: kindDisplay)
                }
                // Step 6: filter picker placeholder
                FeedingFilterPicker(selectedFilter: $selectedFilter, kindDisplay: kindDisplay)
                // Step 7: total section placeholder
                Section {
                    HStack {
                        Spacer()
                        Text("Total Volume: \(String(format: "%.0f", totalVolume)) oz")
                            .font(.headline)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Feeding Entries")
            // Step 3: toolbar with + button only
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            // Step 4: Add sheet with placeholder content
            .sheet(isPresented: $showingAdd) {
                AddFeedingSheet(
                    isPresented: $showingAdd,
                    newDate: $newDate,
                    volumeText: $volumeText,
                    selectedKind: $selectedKind,
                    notesText: $notesText,
                    kindDisplay: kindDisplay,
                    parsedVolume: parsedVolume,
                    saveAction: { saveNewEntry() },
                    showDuplicateAlert: $showDuplicateAlert
                )
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let entry = feedings[index]
            viewContext.delete(entry)
        }
        try? viewContext.save()
    }
    
    private func saveNewEntry() {
        guard let volume = parsedVolume, volume > 0 else { return }
        let isDuplicate = feedings.contains { existing in
            let existingKind = existing.kind ?? Kinds.formula
            let existingDate = existing.date ?? .distantPast
            return existingKind == selectedKind && abs(existingDate.timeIntervalSince(newDate)) < 60 && existing.volume == volume
        }
        if isDuplicate {
            showDuplicateAlert = true
            return
        }
        let entry = FeedingEntryEntity(context: viewContext)
        entry.id = UUID()
        entry.date = newDate
        entry.volume = volume
        entry.kind = selectedKind
        let trimmedNote = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.note = trimmedNote.isEmpty ? nil : trimmedNote
        try? viewContext.save()
        // Reset and dismiss
        volumeText = ""
        newDate = Date()
        selectedKind = Kinds.formula
        notesText = ""
        showingAdd = false
    }
    
    // MARK: - Subviews
    private struct FeedingFilterPicker: View {
        @Binding var selectedFilter: String
        let kindDisplay: [String: String]

        var body: some View {
            Picker("Filter", selection: $selectedFilter) {
                Text("All").tag(Kinds.all)
                Text("Formula").tag(Kinds.formula)
                Text("Water").tag(Kinds.water)
                Text("Flush").tag(Kinds.flush)
            }
            .pickerStyle(.segmented)
        }
    }

    private struct FeedingEntryRow: View {
        let entry: FeedingEntryEntity
        let kindDisplay: [String: String]

        var body: some View {
            // Prepare local strings to avoid complex expressions in the ViewBuilder
            let kindKey: String = entry.kind ?? Kinds.formula
            let kindText: String = kindDisplay[kindKey] ?? "Formula"
            let volumeText: String = String(format: "%.0f", entry.volume)
            let title: String = "\(kindText): \(volumeText) oz"

            return VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(entry.date ?? Date(), style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private struct AddFeedingSheet: View {
        @Binding var isPresented: Bool
        @Binding var newDate: Date
        @Binding var volumeText: String
        @Binding var selectedKind: String
        @Binding var notesText: String
        let kindDisplay: [String: String]
        let parsedVolume: Double?
        let saveAction: () -> Void
        @Binding var showDuplicateAlert: Bool

        var body: some View {
            // Local computed values to keep the ViewBuilder simple
            let pv: Double? = parsedVolume
            let isSaveEnabled: Bool = (pv ?? 0) > 0

            return NavigationStack {
                Form {
                    // DatePicker
                    DatePicker("Date", selection: $newDate, displayedComponents: [.date, .hourAndMinute])

                    // Volume field and quick buttons
                    TextField("Volume (oz)", text: $volumeText)
                        .keyboardType(.decimalPad)
                    HStack {
                        ForEach([2, 3, 4, 5, 6, 8], id: \.self) { v in
                            Button("\(v)") {
                                volumeText = "\(v)"
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    // Kind segmented control
                    Picker("Type", selection: $selectedKind) {
                        Text("Formula").tag(Kinds.formula)
                        Text("Water").tag(Kinds.water)
                        Text("Flush").tag(Kinds.flush)
                    }
                    .pickerStyle(.segmented)

                    // Notes
                    TextField("Notes (optional)", text: $notesText)
                }
                .navigationTitle("New Feeding")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveAction()
                        }
                        .disabled(!isSaveEnabled)
                    }
                }
                .alert("Duplicate entry", isPresented: $showDuplicateAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("An entry with the same time, volume, and type already exists.")
                }
            }
        }
    }
}

