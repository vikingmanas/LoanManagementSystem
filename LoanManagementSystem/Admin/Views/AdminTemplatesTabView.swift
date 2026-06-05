import SwiftUI

struct AdminTemplatesTabView: View {
    @State private var viewModel = AdminTemplatesViewModel()
    @State private var showingEditSheet = false
    @State private var selectedTemplate: MessageTemplate? = nil
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.templates) { template in
                    Button(action: {
                        selectedTemplate = template
                    }) {
                        HStack(spacing: LMSSpacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous)
                                    .fill(LMSColors.actionBlue.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: template.type.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(LMSColors.actionBlue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(LMSFont.headline)
                                    .foregroundStyle(LMSColors.textPrimary)
                                
                                Text(template.subject.isEmpty ? template.body : template.subject)
                                    .font(LMSFont.caption)
                                    .foregroundStyle(LMSColors.textSecondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if !template.isActive {
                                Text("Inactive")
                                    .font(LMSFont.caption2.weight(.bold))
                                    .foregroundStyle(LMSColors.coral)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(LMSColors.coral.opacity(0.1), in: Capsule())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteTemplate(template)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Message Templates")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        selectedTemplate = nil
                        showingEditSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(LMSColors.brandNavy)
                    }
                }
            }
            .accessibleSheet(isPresented: Binding(
                get: { showingEditSheet || selectedTemplate != nil },
                set: { isPresented in
                    if !isPresented {
                        showingEditSheet = false
                        selectedTemplate = nil
                    }
                }
            )) {
                AdminTemplateEditSheet(viewModel: viewModel, template: selectedTemplate)
            }
            .refreshable {
                await viewModel.loadTemplates()
            }
            .task {
                await viewModel.loadTemplates()
            }
        }
    }
}
