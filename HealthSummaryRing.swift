import SwiftUI
import CoreData
import Charts

struct HealthSummaryRing: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FeedingEntryEntity.date, ascending: false)],
        animation: .default)
    private var feedings: FetchedResults<FeedingEntryEntity>

    // MARK: - Date helpers
    private var todayStart: Date { Calendar.current.startOfDay(for: Date()) }
    private var tomorrowStart: Date { Calendar.current.date(byAdding: .day, value: 1, to: todayStart)! }

    // MARK: - Active goal (baseline or daily override)
    private var activeGoal: (feeds: Int16, ozPerFeed: Double) {
        guard let model = viewContext.persistentStoreCoordinator?.managedObjectModel else {
            return (6, 7.0)
        }
        // Daily override first
        if model.entitiesByName["FeedingDailyGoalEntity"] != nil {
            let req = NSFetchRequest<NSManagedObject>(entityName: "FeedingDailyGoalEntity")
            req.fetchLimit = 1
            req.predicate = NSPredicate(format: "day == %@", todayStart as NSDate)
            if let obj = (try? viewContext.fetch(req))?.first {
                let feeds = (obj.value(forKey: "feedsTarget") as? Int16) ?? 6
                let oz = (obj.value(forKey: "ouncesPerFeedTarget") as? Double) ?? 7.0
                return (feeds, oz)
            }
        }
        // Baseline plan next
        if model.entitiesByName["FeedingGoalPlanEntity"] != nil {
            let req = NSFetchRequest<NSManagedObject>(entityName: "FeedingGoalPlanEntity")
            req.fetchLimit = 1
            req.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
            if let obj = (try? viewContext.fetch(req))?.first {
                let feeds = (obj.value(forKey: "feedsPerDay") as? Int16) ?? 6
                let oz = (obj.value(forKey: "ouncesPerFeed") as? Double) ?? 7.0
                return (feeds, oz)
            }
        }
        // Fallback default
        return (6, 7.0)
    }

    private var goalFeedsPerDay: Int16 { activeGoal.feeds }
    private var goalOuncesPerFeed: Double { activeGoal.ozPerFeed }
    private var dailyGoal: Double { Double(goalFeedsPerDay) * goalOuncesPerFeed }

    // MARK: - Today sums
    private var formulaToday: Double {
        feedings
            .filter { entry in
                guard let date = entry.date else { return false }
                return Calendar.current.isDate(date, inSameDayAs: todayStart)
            }
            .filter { (($0.kind ?? "formula").lowercased()) == "formula" }
            .reduce(0) { $0 + $1.volume }
    }

    private var waterToday: Double {
        feedings
            .filter { entry in
                guard let date = entry.date else { return false }
                return Calendar.current.isDate(date, inSameDayAs: todayStart)
            }
            .filter {
                let k = ($0.kind ?? "formula").lowercased()
                return k == "water" || k == "flush"
            }
            .reduce(0) { $0 + $1.volume }
    }

    @State private var showingEditToday = false
    @State private var showingEditBaseline = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Daily Nourish Goal")
                .font(.title2)

            ConcentricGoalRingsView(
                nourishProgress: {
                    let target = dailyGoal
                    guard target > 0 else { return 0 }
                    return min(max(formulaToday / target, 0), 1)
                }(),
                waterProgress: {
                    let target = dailyGoal
                    guard target > 0 else { return 0 }
                    return min(max(waterToday / target, 0), 1)
                }(),
                nourishOz: formulaToday,
                waterOz: waterToday,
                targetOz: dailyGoal
            )
            .frame(width: 260, height: 260)
            .padding(.vertical, 8)

            HStack {
                Button("Edit Today") { showingEditToday = true }
                    .buttonStyle(.bordered)
                Button("Edit Baseline Plan") { showingEditBaseline = true }
                    .buttonStyle(.bordered)
            }
            
            CareDotSparkline()
                .padding(.top, 8)
        }
        .padding()
        .sheet(isPresented: $showingEditToday) {
            EditDailyGoalSheet()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingEditBaseline) {
            EditBaselinePlanSheet()
                .environment(\.managedObjectContext, viewContext)
        }
    }
}

private struct ConcentricGoalRingsView: View {
    let nourishProgress: Double
    let waterProgress: Double
    let nourishOz: Double
    let waterOz: Double
    let targetOz: Double

    private let nourishColor = Color.nourishTan
    private let waterColor = Color.blue

    var body: some View {
        ZStack {
            // Tracks
            Circle()
                .stroke(lineWidth: 10)
                .foregroundColor(waterColor.opacity(0.15))
            Circle()
                .inset(by: 14)
                .stroke(lineWidth: 18)
                .foregroundColor(nourishColor.opacity(0.15))

            // Progress arcs
            Circle()
                .trim(from: 0, to: waterProgress)
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .foregroundColor(waterColor)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: waterProgress)
            Circle()
                .inset(by: 14)
                .trim(from: 0, to: nourishProgress)
                .stroke(style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .foregroundColor(nourishColor)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: nourishProgress)

            // Center text
            VStack(spacing: 4) {
                Text("\(Int(nourishOz)) / \(Int(targetOz)) oz")
                    .font(.title2)
                    .bold()
                Text("Water (incl. flush) \(Int(waterOz)) oz")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private extension Color {
    static var nourishTan: Color { Color(red: 0.76, green: 0.63, blue: 0.46) }
}
private struct CareDotSparkline: View {
    @FetchRequest private var events: FetchedResults<CareEventEntity>

    init() {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let tomorrowStart = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!
        _events = FetchRequest(
            entity: CareEventEntity.entity(),
            sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", todayStart as NSDate, tomorrowStart as NSDate),
            animation: .default
        )
    }

    @State private var selected: CareEventEntity?

    private func careColor(for task: String) -> Color {
        switch task {
        case "Medication": return .pink
        case "Feeding": return .nourishTan
        case "Oral Care": return .purple
        case "Jaw Exercises": return .green
        case "SVN": return .blue
        case "PMV": return .teal
        case "Other": return .gray
        default: return .secondary
        }
    }
    
    private func stableHash(_ s: String) -> Int {
        return s.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
    }

    private func jitterY(for ev: CareEventEntity) -> Double {
        let offsets: [Double] = [-0.18, -0.09, 0.0, 0.09, 0.18]
        let seedString: String = (ev.id?.uuidString)
            ?? ev.objectID.uriRepresentation().absoluteString
        let h = abs(stableHash(seedString))
        return offsets[h % offsets.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Care Activity")
                    .font(.headline)
                Spacer()
                Text("\(events.count) events today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if events.isEmpty {
                Text("No care events yet today")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Chart(events, id: \.objectID) { ev in
                    PointMark(
                        x: .value("Time", ev.date ?? Date()),
                        y: .value("Jitter", jitterY(for: ev))
                    )
                    .foregroundStyle(careColor(for: ev.task ?? ""))
                    .symbolSize(60)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartXScale(domain: {
                    let start = Calendar.current.startOfDay(for: Date())
                    let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
                    return start...end
                }())
                .chartYScale(domain: -0.25...0.25)
                .chartPlotStyle { plot in
                    plot.padding(.vertical, 4)
                    plot.frame(height: 60)
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { gesture in
                                        let location = gesture.location
                                        guard let plotFrame = proxy.plotFrame else { return }
                                        let origin = geo[plotFrame].origin
                                        let xPos = location.x - origin.x
                                        if let date: Date = proxy.value(atX: xPos) {
                                            // Find nearest event within 60 minutes
                                            let nearest = events.min { a, b in
                                                let ad = a.date ?? .distantPast
                                                let bd = b.date ?? .distantPast
                                                return abs(ad.timeIntervalSince(date)) < abs(bd.timeIntervalSince(date))
                                            }
                                            if let n = nearest, let nd = n.date, abs(nd.timeIntervalSince(date)) <= 3600 {
                                                selected = n
                                            }
                                        }
                                    }
                            )
                    }
                }
            }
        }
        .sheet(isPresented: Binding(get: { selected != nil }, set: { if !$0 { selected = nil } })) {
            if let ev = selected {
                CareEventDetailSheet(event: ev)
            }
        }
    }
}

private struct CareEventDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let event: CareEventEntity

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Task")
                        Spacer()
                        Text(event.task ?? "")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Time")
                        Spacer()
                        Text(event.date ?? Date(), style: .time)
                            .foregroundStyle(.secondary)
                    }
                    if (event.task ?? "") == "Medication", let name = event.itemName, !name.isEmpty {
                        HStack {
                            Text("Medication")
                            Spacer()
                            Text(name)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let note = event.note, !note.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Note")
                            Text(note)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(event.task ?? "Care Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

