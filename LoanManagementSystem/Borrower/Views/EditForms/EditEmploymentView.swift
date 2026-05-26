import SwiftUI

struct EditEmploymentView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: BorrowerProfileViewModel

    @State private var employmentType: String
    @State private var companyName: String
    @State private var designation: String
    @State private var monthlyIncome: String

    init(viewModel: BorrowerProfileViewModel) {
        self.viewModel = viewModel
        _employmentType = State(initialValue: viewModel.profile?.employment.employmentType ?? "")
        _companyName = State(initialValue: viewModel.profile?.employment.companyName ?? "")
        _designation = State(initialValue: viewModel.profile?.employment.designation ?? "")

        let incomeVal = viewModel.profile?.income.monthlyIncome ?? 0.0
        _monthlyIncome = State(initialValue: String(format: "%.0f", incomeVal))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Employment Details")) {
                    TextField("Employment Type", text: $employmentType)
                        .font(Font.AppTheme.input)
                    TextField("Company Name", text: $companyName)
                        .font(Font.AppTheme.input)
                    TextField("Designation", text: $designation)
                        .font(Font.AppTheme.input)
                    TextField("Monthly Income", text: $monthlyIncome)
                        .keyboardType(.numberPad)
                        .font(Font.AppTheme.input)
                }
            }
            .navigationTitle("Edit Employment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.AppTheme.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let incomeDouble = Double(monthlyIncome) ?? 0.0
                        viewModel.updateEmployment(
                            type: employmentType,
                            company: companyName,
                            designation: designation,
                            income: incomeDouble
                        )
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "checkmark")
                            .fontWeight(.bold)
                            .foregroundStyle(Color.AppTheme.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditEmploymentView(viewModel: PreviewSupport.borrowerProfileViewModel)
    }
}

