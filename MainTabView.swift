import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            FeedingEntryView()
                .tabItem {
                    Label("Log", systemImage: "list.bullet")
                }

            FeedingVolumeChart()
                .tabItem {
                    Label("Chart", systemImage: "chart.bar.fill")
                }

            HealthSummaryRing()
                .tabItem {
                    Label("Summary", systemImage: "gauge.with.dots.needle.33percent")
                }
            
            CareLogView()
                .tabItem {
                    Label("Care", systemImage: "checklist")
                }
        }
    }
}
