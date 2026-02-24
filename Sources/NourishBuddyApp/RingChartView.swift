import SwiftUI

struct RingChartView: View {
    var hydration: Double
    var hydrationGoal: Double
    var nourishment: Double
    var nourishmentGoal: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 16)
            Circle()
                .trim(from: 0, to: CGFloat(min(hydration/hydrationGoal, 1)))
                .stroke(Color.blue, lineWidth: 16)
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0, to: CGFloat(min(nourishment/nourishmentGoal, 1)))
                .stroke(Color.green, lineWidth: 16)
                .rotationEffect(.degrees(-90))
                .scaleEffect(0.8)
        }
    }
}
