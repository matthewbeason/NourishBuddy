import SwiftUI

struct EntryForm: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var feedVol = ""
    @State private var waterVol = ""
    @State private var medDose = ""

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("Feed (oz)", text: $feedVol)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Log") {
                    viewModel.logFeed(volume: Double(feedVol) ?? 0)
                    feedVol = ""
                }
            }
            HStack {
                TextField("Water (oz)", text: $waterVol)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Log") {
                    viewModel.logWater(volume: Double(waterVol) ?? 0)
                    waterVol = ""
                }
            }
            HStack {
                Picker("Med", selection: $viewModel.selectedMed) {
                    ForEach(viewModel.commonMeds, id: \.self) { Text($0) }
                }
                .pickerStyle(MenuPickerStyle())
                TextField("Dose (mg)", text: $medDose)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Log") {
                    viewModel.logMedication(dose: Double(medDose) ?? 0)
                    medDose = ""
                }
            }
        }
        .padding()
    }
}

