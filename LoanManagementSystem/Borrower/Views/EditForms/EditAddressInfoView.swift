import SwiftUI

struct EditAddressInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @Bindable var viewModel: BorrowerProfileViewModel

    @State private var streetAddress: String
    @State private var city: String
    @State private var state: String
    @State private var zipCode: String

    @State private var isSameAsCurrent: Bool

    init(viewModel: BorrowerProfileViewModel) {
        self.viewModel = viewModel
        _streetAddress = State(initialValue: viewModel.profile?.currentAddress.streetAddress ?? "")
        _city = State(initialValue: viewModel.profile?.currentAddress.city ?? "")
        _state = State(initialValue: viewModel.profile?.currentAddress.state ?? "")
        _zipCode = State(initialValue: viewModel.profile?.currentAddress.zipCode ?? "")
        _isSameAsCurrent = State(initialValue: viewModel.profile?.currentAddress.isSameAsCurrent ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Current Address")) {
                    TextField("Street Address", text: $streetAddress)
                        .font(Font.AppTheme.input)
                    TextField("City", text: $city)
                        .font(Font.AppTheme.input)
                    TextField("State", text: $state)
                        .font(Font.AppTheme.input)
                    TextField("Zip/Pin Code", text: $zipCode)
                        .keyboardType(.numberPad)
                        .font(Font.AppTheme.input)
                }

                Section {
                    Toggle("Permanent address is same as current", isOn: $isSameAsCurrent)
                }
            }
            .navigationTitle("Edit Address Info")
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
                        viewModel.updateAddress(
                            street: streetAddress,
                            city: city,
                            state: state,
                            zip: zipCode,
                            isSame: isSameAsCurrent
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


