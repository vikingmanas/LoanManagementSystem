import SwiftUI

struct ManagerApplicantListSheet: View {
    let title: String
    let systemImage: String
    let description: String
    let applicants: [ManagerApplicant]
    
    @Environment(\.dismiss) var dismiss
    
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
