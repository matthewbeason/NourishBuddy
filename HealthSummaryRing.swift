import SwiftUI
import CoreData

struct HealthSummaryRing: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FeedingEntryEntity.date, ascending: false)],
        animation: .default)
    private var feedings: FetchedResults<FeedingEntryEntity>

    private let dailyGoal: Double = 1000

    private var formulaToday: Double {
        let today = Calendar.current.startOfDay(for: Date())
        return feedings
            .filter { entry in
                guard let date = entry.date else { return false }
                return Calendar.current.isDate(date, inSameDayAs: today)
            }
            .filter { ($0.kind ?? "formula") == "formula" }
            .reduce(0) { $0 + $1.volume }
    }

    private var waterFlushToday: Double {
        let today = Calendar.current.startOfDay(for: Date())
        return feedings
            .filter { entry in
                guard let date = entry.date else { return false }
                return Calendar.current.isDate(date, inSameDayAs: today)
            }
            .filter {
                let k = ($0.kind ?? "formula")
                return k == "water" || k == "flush"
            }
            .reduce(0) { $0 + $1.volume }
    }

    private var todayTotal: Double {
        let today = Calendar.current.startOfDay(for: Date())
        return feedings
            .filter { entry in
                guard let date = entry.date else { return false }
                return Calendar.current.isDate(date, inSameDayAs: today)
            }
            .reduce(0) { $0 + $1.volume }
    }

    private var progress: Double {
        min(todayTotal / dailyGoal, 1.0)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Daily Hydration Goal")
                .font(.title2)

            ZStack {
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.2)
                    .foregroundColor(.blue)

                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .foregroundColor(progress >= 1 ? .green : .blue)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: progress)

                VStack {
                    Text("\(Int(todayTotal)) oz")
                        .font(.largeTitle)
                        .bold()
                    Text("of \(Int(dailyGoal)) oz")
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 200, height: 200)
            .padding()

            if progress >= 1 {
                Text("✅ Goal reached!")
                    .foregroundColor(.green)
                    .font(.headline)
            } else {
                Text("Keep nourishing 💧")
                    .foregroundColor(.blue)
                    .font(.subheadline)
            }

            VStack(spacing: 4) {
                Text("Formula today: \(Int(formulaToday)) oz")
                    .font(.subheadline)
                Text("Water/Flush today: \(Int(waterFlushToday)) oz")
                    .font(.subheadline)
            }
        }
        .padding()
    }
}

