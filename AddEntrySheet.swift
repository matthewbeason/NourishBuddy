import SwiftUI

enum AddMode: String, CaseIterable, Identifiable {
    case feeding = "Feeding"
    case care = "Care"
    var id: String { rawValue }
}

struct AddEntrySheet<FeedingContent: View, CareContent: View>: View {
    @Environment(\.dismiss) private var dismiss

    @State private var mode: AddMode = .feeding

    let feedingContent: FeedingContent
    let careContent: CareContent

    init(mode: AddMode = .feeding,
         @ViewBuilder feedingContent: () -> FeedingContent,
         @ViewBuilder careContent: () -> CareContent) {
        self._mode = State(initialValue: mode)
        self.feedingContent = feedingContent()
        self.careContent = careContent()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Add", selection: $mode) {
                    ForEach(AddMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Group {
                    switch mode {
                    case .feeding:
                        feedingContent
                    case .care:
                        careContent
                    }
                }
            }
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.large)
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

#Preview {
    AddEntrySheet(
        feedingContent: {
            Text("Feeding form goes here")
        },
        careContent: {
            Text("Care form goes here")
        }
    )
}
