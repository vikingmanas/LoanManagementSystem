import SwiftUI

struct ManagerApplicantListSheet: View {
    let title: String
    let systemImage: String
    let description: String
    let applicants: [ManagerApplicant]
    
    @Environment(\.dismiss) var dismiss
    
    // We will just show a detail view when one is tapped.
    // However, since we are in a sheet, maybe it's better to just use a NavigationLink or open another sheet.
    // Since ManagerApplicantDetailView requires a view model, we should probably pass it in.
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @State private var selectedApplicant: ManagerApplicant?
    
    var body: some View {
        NavigationStack {
            Group {
                if applicants.isEmpty {
                    ContentUnavailableView(
                        title,
                        systemImage: systemImage,
                        description: Text(description)
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: LMSSpacing.sm) {
                            ForEach(applicants) { applicant in
                                NavigationLink {
                                    ManagerApplicantDetailView(applicant: applicant, viewModel: viewModel)
                                } label: {
                                    ApplicantListCard(applicant: applicant)
                                }
                                .buttonStyle(LMSPressableStyle())
                            }
                        }
                        .padding(LMSSpacing.screenHorizontal)
                    }
                    .background(LMSColors.background)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .bold()
                }
            }
        }
    }
}
