import SwiftUI

struct StatCard: View {
    var title: String
    var value: String
    var color: Color

    var body: some View {
        VStack {
            Text(title).font(.caption).foregroundColor(.gray)
            Text(value).font(.title2).bold().foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        #if os(iOS)
            .background(Color(.systemBackground))
#else
            .background(Color(NSColor.windowBackgroundColor))
#endif
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}
