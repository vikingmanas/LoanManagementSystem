import SwiftUI

struct AdminTemplateEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AdminTemplatesViewModel
    
    @State private var template: MessageTemplate
    private var isNew: Bool
    
    init(viewModel: AdminTemplatesViewModel, template: MessageTemplate?) {
        self.viewModel = viewModel
        if let template = template {
            self._template = State(initialValue: template)
            self.isNew = false
        } else {
            self._template = State(initialValue: MessageTemplate(
                id: UUID(),
                name: "",
                subject: "",
                body: "",
                type: .email,
                isActive: true
            ))
            self.isNew = true
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Template Info") {
                    TextField("Template Name (e.g. Loan Approval)", text: $template.name)
                    Picker("Type", selection: $template.type) {
                        ForEach(MessageTemplateType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    Toggle("Is Active", isOn: $template.isActive)
                }
                
                Section("Content") {
                    if template.type == .email {
                        TextField("Subject", text: $template.subject)
                    }
                    
                    TextEditor(text: $template.body)
                        .frame(minHeight: 150)
                        .overlay(
                            Group {
                                if template.body.isEmpty {
                                    Text("Enter message body here...\nUse {{variable}} for dynamic content.")
                                        .foregroundColor(LMSColors.textSecondary)
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }
            }
            .navigationTitle(isNew ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveTemplate(template)
                        dismiss()
                    }
                    .disabled(template.name.isEmpty || template.body.isEmpty)
                }
            }
        }
    }
}
