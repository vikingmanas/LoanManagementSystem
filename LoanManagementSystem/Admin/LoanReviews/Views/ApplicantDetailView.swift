import SwiftUI

struct ApplicantDetailView: View {
    @ObservedObject var viewModel: LoanReviewViewModel
    let applicantId: UUID
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddNote = false
    @State private var newNote = ""
    
    private var applicant: LoanApplicantModel? {
        viewModel.applicants.first(where: { $0.id == applicantId })
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            LMSColors.background.ignoresSafeArea()
            
            if let applicant = applicant {
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LMSColors.brandNavy.opacity(0.12))
                                    .frame(width: 80, height: 80)
                                Text(String(applicant.applicantName.prefix(1)))
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(LMSColors.brandNavy)
                            }
                            
                            VStack(spacing: 4) {
                                Text(applicant.applicantName)
                                    .font(LMSFont.title.weight(.bold))
                                    .foregroundStyle(LMSColors.textPrimary)
                                Text(applicant.loanId)
                                    .font(LMSFont.subheadline)
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                            
                            HStack(spacing: 12) {
                                Text(applicant.status.rawValue.uppercased())
                                    .font(LMSFont.caption2.weight(.bold))
                                    .foregroundStyle(applicant.status.color)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(applicant.status.color.opacity(0.12), in: Capsule())
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                    Text(applicant.recommendation.rawValue)
                                }
                                .font(LMSFont.caption2.weight(.bold))
                                .foregroundStyle(applicant.recommendation.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(applicant.recommendation.color.opacity(0.12), in: Capsule())
                            }
                        }
                        .padding(.vertical, 24)
                        
                        // Loan Request Details
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Loan Request")
                                .font(LMSFont.headline)
                                .foregroundStyle(LMSColors.textPrimary)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Amount")
                                        .font(LMSFont.caption)
                                        .foregroundStyle(LMSColors.textTertiary)
                                    Text(formatCurrency(applicant.requestedAmount))
                                        .font(LMSFont.title3.weight(.bold))
                                        .foregroundStyle(LMSColors.textPrimary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Type")
                                        .font(LMSFont.caption)
                                        .foregroundStyle(LMSColors.textTertiary)
                                    Text(applicant.loanType.rawValue)
                                        .font(LMSFont.subheadline.weight(.semibold))
                                        .foregroundStyle(LMSColors.textSecondary)
                                }
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lmsCardElevated()
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                        
                        // Financial Profile
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Financial Profile")
                                .font(LMSFont.headline)
                                .foregroundStyle(LMSColors.textPrimary)
                            
                            detailRow(icon: "briefcase.fill", title: "Employment", value: applicant.employmentType)
                            Divider().background(LMSColors.separatorLight)
                            detailRow(icon: "indianrupeesign.circle.fill", title: "Monthly Income", value: formatCurrency(applicant.monthlyIncome))
                            Divider().background(LMSColors.separatorLight)
                            detailRow(icon: "creditcard.fill", title: "Existing EMI", value: formatCurrency(applicant.existingEMI))
                            Divider().background(LMSColors.separatorLight)
                            
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(LMSColors.textTertiary)
                                    .frame(width: 20)
                                Text("CIBIL Score")
                                    .font(LMSFont.subheadline)
                                    .foregroundStyle(LMSColors.textSecondary)
                                Spacer()
                                Text("\(applicant.cibilScore)")
                                    .font(LMSFont.subheadline.weight(.bold))
                                    .foregroundStyle(scoreColor(applicant.cibilScore))
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lmsCard()
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                        
                        // Timeline & Notes
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Application Timeline")
                                    .font(LMSFont.headline)
                                    .foregroundStyle(LMSColors.textPrimary)
                                Spacer()
                                Button { showingAddNote = true } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(LMSColors.brandNavy)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            if let notes = applicant.internalNotes {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Internal Notes")
                                        .font(LMSFont.caption.weight(.bold))
                                        .foregroundStyle(LMSColors.brandNavy)
                                    Text(notes)
                                        .font(LMSFont.subheadline)
                                        .foregroundStyle(LMSColors.textSecondary)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(LMSColors.brandNavy.opacity(0.05), in: RoundedRectangle(cornerRadius: LMSRadius.md))
                                .padding(.horizontal, 20)
                            }
                            
                            VStack(spacing: 0) {
                                ForEach(applicant.timeline.indices, id: \.self) { index in
                                    let event = applicant.timeline[index]
                                    let isLast = index == applicant.timeline.count - 1
                                    
                                    HStack(alignment: .top, spacing: 16) {
                                        VStack(spacing: 0) {
                                            Circle()
                                                .fill(index == 0 ? LMSColors.brandNavy : LMSColors.separator)
                                                .frame(width: 12, height: 12)
                                            if !isLast {
                                                Rectangle()
                                                    .fill(LMSColors.separatorLight)
                                                    .frame(width: 2)
                                            }
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(event.action)
                                                    .font(LMSFont.subheadline.weight(.semibold))
                                                    .foregroundStyle(LMSColors.textPrimary)
                                                Spacer()
                                                if let user = event.user {
                                                    Text(user)
                                                        .font(LMSFont.caption2)
                                                        .foregroundStyle(LMSColors.brandNavy)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(LMSColors.brandNavy.opacity(0.1), in: Capsule())
                                                }
                                            }
                                            Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(LMSFont.caption)
                                                .foregroundStyle(LMSColors.textTertiary)
                                        }
                                        .padding(.bottom, isLast ? 0 : 20)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lmsCard()
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                        
                        Spacer().frame(height: 180)
                    }
                }
                
                // Floating Action Toolbar
                VStack(spacing: 12) {
                    Divider().background(LMSColors.separatorLight)
                    
                    if applicant.status != .approved && applicant.status != .rejected {
                        HStack(spacing: 12) {
                            Button {
                                viewModel.updateStatus(for: applicantId, to: .changesRequested, user: "Manager")
                                dismiss()
                            } label: {
                                Text("Request Changes")
                                    .font(LMSFont.button)
                                    .foregroundStyle(LMSColors.coral)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(LMSColors.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: LMSRadius.md))
                            }
                            .buttonStyle(LMSPressableStyle())
                            
                            Button {
                                viewModel.updateStatus(for: applicantId, to: .approved, user: "Manager")
                                dismiss()
                            } label: {
                                Text("Approve Loan")
                                    .font(LMSFont.button)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(LMSColors.emerald, in: RoundedRectangle(cornerRadius: LMSRadius.md))
                            }
                            .buttonStyle(LMSPressableStyle())
                        }
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                        .padding(.bottom, 16)
                    }
                }
                .background(.ultraThinMaterial)
                
            } else {
                Text("Applicant Not Found")
                    .font(LMSFont.headline)
                    .foregroundStyle(LMSColors.textSecondary)
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Add Internal Note", isPresented: $showingAddNote) {
            TextField("Enter note...", text: $newNote)
            Button("Cancel", role: .cancel) { newNote = "" }
            Button("Save") {
                viewModel.addInternalNote(id: applicantId, note: newNote, user: "Manager")
                newNote = ""
            }
        }
        .toolbar {
            if applicant?.status != .rejected && applicant?.status != .approved {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reject") {
                        viewModel.updateStatus(for: applicantId, to: .rejected, user: "Manager")
                        dismiss()
                    }
                    .foregroundStyle(LMSColors.coral)
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(LMSColors.textTertiary)
                .frame(width: 20)
            Text(title)
                .font(LMSFont.subheadline)
                .foregroundStyle(LMSColors.textSecondary)
            Spacer()
            Text(value)
                .font(LMSFont.subheadline.weight(.semibold))
                .foregroundStyle(LMSColors.textPrimary)
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₹\(Int(amount))"
    }
    
    private func scoreColor(_ score: Int) -> Color {
        if score >= 750 { return LMSColors.emerald }
        if score >= 650 { return LMSColors.amber }
        return LMSColors.coral
    }
}

#Preview {
    NavigationStack {
        ApplicantDetailView(viewModel: LoanReviewViewModel(), applicantId: LoanReviewViewModel().applicants[0].id)
    }
    .preferredColorScheme(.dark)
}
