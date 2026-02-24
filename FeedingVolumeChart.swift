import SwiftUI
import Charts
import CoreData

struct FeedingVolumeChart: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FeedingEntryEntity.date, ascending: true)],
        animation: .default)
    private var feedings: FetchedResults<FeedingEntryEntity>

    var dailySums: [(date: Date, total: Double)] {
        let grouped = Dictionary(grouping: feedings) { entry in
            Calendar.current.startOfDay(for: entry.date ?? Date())
        }
        return grouped.map { (key, values) in
            (key, values.reduce(0) { $0 + $1.volume })
        }.sorted(by: { $0.date < $1.date })
    }

    var body: some View {
        Chart(dailySums, id: \.date) { item in
            BarMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Volume", item.total)
            )
        }
        .frame(height: 250)
        .padding()
        .navigationTitle("Volume Chart")
    }
}
