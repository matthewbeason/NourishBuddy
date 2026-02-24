import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Nourish Buddy")
                        .font(.largeTitle).bold()
                    RingChartView(
                        hydration: viewModel.hydrationTotal,
                        hydrationGoal: viewModel.hydrationGoal,
                        nourishment: viewModel.nourishmentTotal,
                        nourishmentGoal: viewModel.nourishmentGoal
                    )
                    .frame(width: 200, height: 200)
                    HStack(spacing: 16) {
                        StatCard(title: "Hydration", value: "\(viewModel.hydrationTotal) ml", color: .blue)
                        StatCard(title: "Nourishment", value: "\(viewModel.nourishmentTotal) ml", color: .green)
                    }
                    EntryForm(viewModel: viewModel)
                }
                .padding()
            }
            
        }
        .onAppear { viewModel.requestNotifications() }
    }
}
