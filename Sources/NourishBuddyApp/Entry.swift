import Foundation

struct Entry: Identifiable {
    let id = UUID()
    let date: Date
    let hydration: Double
    let nourishment: Double
}
