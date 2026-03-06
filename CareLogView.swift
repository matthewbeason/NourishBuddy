import SwiftUI
import CoreData

struct CareLogView: View {
    @Environment(\.managedObjectContext) var viewContext
    
    @FetchRequest(
        entity: CareEventEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CareEventEntity.date, ascending: false)]
    ) var events: FetchedResults<CareEventEntity>
    
    @State private var showingAddSheet = false
    
    private let tasks = [
        "Feeding",
        "Medication",
        "Oral Care",
        "Jaw Exercises",
        "SVN",
        "PMV",
        "Other"
    ]
    private let slots = ["None", "AM", "PM", "Night"]
    
    private var filteredEvents: [CareEventEntity] {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return events.filter { $0.date ?? Date.distantPast >= oneWeekAgo }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredEvents, id: \.objectID) { event in
                    Row(event: event)
                }
                .onDelete(perform: deleteEvents)
            }
            .navigationTitle("Care Events")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Care Event")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddCareEventSheet(
                    slots: slots,
                    onSave: { task, slot, date, note, itemName in
                        let newEvent = CareEventEntity(context: viewContext)
                        newEvent.id = UUID()
                        newEvent.date = date
                        newEvent.task = task
                        newEvent.slot = slot == "None" ? nil : slot
                        newEvent.note = note.isEmpty ? nil : note
                        newEvent.itemName = (itemName?.isEmpty == false) ? itemName : nil
                        do {
                            try viewContext.save()
                        } catch {
                            print("Failed to save CareEvent: \(error)")
                        }
                        showingAddSheet = false
                    },
                    onCancel: {
                        showingAddSheet = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func deleteEvents(offsets: IndexSet) {
        for index in offsets {
            let event = filteredEvents[index]
            viewContext.delete(event)
        }
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete CareEvent: \(error)")
        }
    }
    
    private struct Row: View {
        let event: CareEventEntity
        
        private var taskText: String {
            event.task ?? ""
        }
        
        private var timeText: String {
            guard let date = event.date else { return "" }
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        private var slotText: String? {
            event.slot
        }
        
        private var itemNameText: String? {
            if let name = event.itemName, !name.isEmpty { return name }
            return nil
        }
        
        private var noteText: String? {
            event.note?.isEmpty == false ? event.note : nil
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(taskText)
                        .font(.headline)
                    Spacer()
                    Text(timeText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let name = itemNameText {
                    Text(name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 8) {
                    if let slot = slotText {
                        Text(slot)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let note = noteText {
                        Text(note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct AddCareEventSheet: View {
    enum MedicationGroup: String, CaseIterable, Identifiable {
        case daily = "Daily"
        case prn = "PRN"
        var id: String { rawValue }
    }
    
    private let tasks: [String] = [
        "Feeding",
        "Medication",
        "Oral Care",
        "Jaw Exercises",
        "SVN",
        "PMV",
        "Other"
    ]
    private let dailyMeds: [String] = [
        "Omeprazole — 11 mL (2x/day)",
        "Zyrtec — 7.5 mL (1x/day)",
        "Probiotic — 1 cap (1x/day)",
        "Oral care — toothbrush & toothette (1x/day)",
        "Chlorhexidine (2x/day)",
        "Iron — 6 mL (1x/day)",
        "SVN — saline bullets (2x/day AM/PM)",
        "PMV (after SVN)",
        "Omnitrope — 0.8 mg (nightly)",
        "Jaw exercises (daily)"
    ]
    private let prnMeds: [String] = [
        "Mucinex — 10 mL (q4–6h PRN)",
        "Benadryl — 8.75–10 mL (q6h PRN)",
        "Tylenol — 10 mL (q6h PRN; can alternate q3h w/ ibuprofen)",
        "Ibuprofen — 10 mL (q6h PRN; NOT on empty stomach)",
        "Zofran — 5 mL (q8h up to 3x/day PRN)",
        "Oxy — 1.5 mL (PRN)",
        "Ciprodex drops (ears)"
    ]
    let slots: [String]
    let onSave: (_ task: String, _ slot: String, _ date: Date, _ note: String, _ itemName: String?) -> Void
    let onCancel: () -> Void
    let embedded: Bool
    
    init(
        slots: [String],
        onSave: @escaping (_ task: String, _ slot: String, _ date: Date, _ note: String, _ itemName: String?) -> Void,
        onCancel: @escaping () -> Void,
        embedded: Bool = false
    ) {
        self.slots = slots
        self.onSave = onSave
        self.onCancel = onCancel
        self.embedded = embedded
    }
    
    @State private var selectedTask: String = ""
    @State private var selectedSlot: String = "None"
    @State private var eventDate: Date = Date()
    @State private var note: String = ""
    @State private var selectedMedication: String = ""
    @State private var medicationGroup: MedicationGroup = .daily
    
    private var canSave: Bool {
        !selectedTask.isEmpty
    }
    
    private func iconForTask(_ task: String) -> String {
        switch task {
        case "Medication": return "pills.fill"
        case "Oral Care": return "mouth.fill"
        case "SVN": return "drop.fill"
        case "PMV": return "wind"
        case "Jaw Exercises": return "face.smiling"
        case "Feeding": return "fork.knife"
        case "Other": return "square.and.pencil"
        default: return "square"
        }
    }
    
    var body: some View {
        #if DEBUG
        let _ = {
            assert(prnMeds.contains("Ibuprofen — 10 mL (q6h PRN; NOT on empty stomach)"), "PRN meds should include Ibuprofen preset")
            return 0
        }()
        #endif
        
        let formContent = Form {
            Section("Task") {
                ForEach(tasks, id: \.self) { task in
                    Button {
                        selectedTask = task
                        if task == "Medication" {
                            medicationGroup = .daily
                            if selectedMedication.isEmpty, let first = dailyMeds.first {
                                selectedMedication = first
                            }
                        } else {
                            selectedMedication = ""
                        }
                    } label: {
                        HStack {
                            Label(task, systemImage: iconForTask(task))
                            Spacer()
                            if selectedTask == task {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .onAppear {
                if selectedTask.isEmpty, let first = tasks.first {
                    selectedTask = first
                }
            }
            
            if selectedTask == "Medication" {
                Section("Medication") {
                    Picker("Type", selection: $medicationGroup) {
                        ForEach(MedicationGroup.allCases) { group in
                            Text(group.rawValue).tag(group)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    let meds = medicationGroup == .daily ? dailyMeds : prnMeds
                    Picker("", selection: $selectedMedication) {
                        ForEach(meds, id: \.self) { med in
                            Text(med).tag(med)
                        }
                    }
                    .labelsHidden()
                }
                .pickerStyle(.inline)
                .onAppear {
                    if selectedMedication.isEmpty, let first = dailyMeds.first {
                        selectedMedication = first
                    }
                }
                .onChange(of: selectedTask) { newValue in
                    if newValue == "Medication", selectedMedication.isEmpty, let first = dailyMeds.first {
                        selectedMedication = first
                    } else if newValue != "Medication" {
                        selectedMedication = ""
                    }
                }
                .onChange(of: medicationGroup) { newGroup in
                    let meds = newGroup == .daily ? dailyMeds : prnMeds
                    if !meds.contains(selectedMedication) {
                        if let first = meds.first { selectedMedication = first } else { selectedMedication = "" }
                    }
                }
            }
            
            Section("Notes") {
                TextEditor(text: $note)
                    .frame(minHeight: 140)
            }
            
            Section("Date & Time") {
                DatePicker("Date & Time", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
            }
            
            Section("Slot") {
                Picker("Slot", selection: $selectedSlot) {
                    ForEach(slots, id: \.self) { slot in
                        Text(slot).tag(slot)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        
        if embedded {
            formContent
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            onCancel()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            onSave(selectedTask, selectedSlot, eventDate, note, selectedTask == "Medication" ? selectedMedication : nil)
                        }
                        .disabled(selectedTask.isEmpty || (selectedTask == "Medication" && selectedMedication.isEmpty))
                    }
                }
        } else {
            NavigationStack {
                formContent
                    .navigationTitle("New Care Event")
                    .scrollDismissesKeyboard(.interactively)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                onCancel()
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                onSave(selectedTask, selectedSlot, eventDate, note, selectedTask == "Medication" ? selectedMedication : nil)
                            }
                            .disabled(selectedTask.isEmpty || (selectedTask == "Medication" && selectedMedication.isEmpty))
                        }
                    }
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    CareLogView()
        .environment(\.managedObjectContext, context)
}

