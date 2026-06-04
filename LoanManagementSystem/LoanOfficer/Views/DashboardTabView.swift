import SwiftUI

struct DashboardTabView: View {
    typealias LoanApplication = OfficerLoanApplication
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    
    var onDocumentSeeAllTapped: () -> Void
    var onManagerRespondTapped: (LoanApplication) -> Void
    var onQuickActionTapped: (String) -> Void
    
    @State private var showingPortfolioMetrics = false
    @State private var selectedDocumentForReview: DocumentQueueItem? = nil
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20) {
                
                if viewModel.isLoading {
                    VStack(spacing: 20) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LMSColors.textSecondary.opacity(0.15))
                            .frame(height: 180)
                        
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LMSColors.textSecondary.opacity(0.15))
                            .frame(height: 250)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .redacted(reason: .placeholder)
                    .transition(.opacity)
                } else {
                    VStack(spacing: 20) {
                        
                        PortfolioSummaryCard(viewModel: viewModel) {
                            showingPortfolioMetrics = true
                        }
                        .id("portfolio_card")
                        .padding(.horizontal, 16)
                        
                        DocumentQueueView(
                            viewModel: viewModel,
                            onReviewTapped: { docItem in
                                selectedDocumentForReview = docItem
                            },
                            onSeeAllTapped: {
                                onDocumentSeeAllTapped()
                            }
                        )
                        .id("doc_queue")
                        .padding(.horizontal, 16)
                        
                        OfficerQuickActionsView(
                            onVerifyDocs: {
                                onQuickActionTapped("verify_docs")
                            },
                            onReports: {
                                onQuickActionTapped("reports")
                            },
                            onEscalate: {
                                onQuickActionTapped("escalate")
                            }
                        )
                        .id("quick_actions")
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    .transition(.asymmetric(
                        insertion: .opacity.animation(.easeIn(duration: 0.4)),
                        removal: .opacity
                    ))
                }
            }
        }
        .refreshable {
            HapticsManager.triggerImpact(style: .medium)
            await viewModel.fetchDashboardData()
        }
        .accessibleSheet(isPresented: $showingPortfolioMetrics) {
            PortfolioMetricsSheet(viewModel: viewModel)
        }
        .navigationDestination(item: $selectedDocumentForReview) { docItem in
            LoanApplicationReviewDetailView(
                applicationId: docItem.applicationId,
                initialDocumentId: docItem.id,
                viewModel: viewModel
            )
        }
    }
}
