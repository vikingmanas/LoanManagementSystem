import SwiftUI

struct DocumentReviewDetailView: View {
    typealias LoanApplication = OfficerLoanApplication
    typealias DocumentType = OfficerDocumentType
    typealias DocumentStatus = OfficerDocumentStatus
    let item: DocumentQueueItem
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var showingRejectionAlert = false
    @State private var rejectionReason = ""
    
    // Find the actual loan application details to display in user/loan context
    var loanDetails: LoanApplication? {
        viewModel.applications.first { $0.applicationId == item.applicationId }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 1. Borrower & Loan Details Panel
                    if let app = loanDetails {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(app.borrowerName)
                                        .font(.system(.title3, design: .rounded).bold())
                                        .foregroundColor(LMSColors.textPrimary)
                                    
                                    Text("Application ID: \(app.applicationId)")
                                        .font(.system(.caption, design: .rounded).weight(.semibold))
                                        .foregroundColor(LMSColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                // CIBIL Score Badge
                                if let cibil = app.cibilScore {
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("CIBIL Score")
                                            .font(.system(.caption2, design: .rounded).bold())
                                            .foregroundColor(LMSColors.textSecondary)
                                        
                                        Text("\(cibil)")
                                            .font(.system(.subheadline, design: .rounded).bold())
                                            .foregroundColor(cibilColor(for: cibil))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(cibilColor(for: cibil).opacity(0.12))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // Loan & Branch details
                            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                                GridRow {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("LOAN TYPE REQUESTED")
                                            .font(.system(.caption2, design: .rounded).bold())
                                            .foregroundColor(LMSColors.textSecondary)
                                        Text(app.loanType.rawValue)
                                            .font(.system(.footnote, design: .rounded).bold())
                                            .foregroundColor(app.loanType.themeColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("REQUESTED AMOUNT")
                                            .font(.system(.caption2, design: .rounded).bold())
                                            .foregroundColor(LMSColors.textSecondary)
                                        Text(CurrencyFormatter.shared.format(app.requestedAmount))
                                            .font(.system(.footnote, design: .rounded).bold())
                                            .foregroundColor(LMSColors.textPrimary)
                                    }
                                }
                                
                                GridRow {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("ASSIGNED BRANCH")
                                            .font(.system(.caption2, design: .rounded).bold())
                                            .foregroundColor(LMSColors.textSecondary)
                                        Text(app.branch)
                                            .font(.system(.footnote, design: .rounded))
                                            .foregroundColor(LMSColors.textPrimary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("DOCUMENT STAGE")
                                            .font(.system(.caption2, design: .rounded).bold())
                                            .foregroundColor(LMSColors.textSecondary)
                                        Text(item.status.rawValue)
                                            .font(.system(.footnote, design: .rounded).bold())
                                            .foregroundColor(item.status.themeColor)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(AppTheme.neutralSurface)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.02), radius: 3, x: 0, y: 2)
                        .padding(.horizontal, 16)
                    }
                    
                    // 2. Document Graphic Preview Container
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Uploaded File Preview")
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundColor(LMSColors.textSecondary)
                            .padding(.horizontal, 16)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(uiColor: .systemGroupedBackground))
                                .frame(height: 280)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(LMSColors.textPrimary.opacity(0.08), lineWidth: 1)
                                )
                            
                            // Render specific graphic mockup according to doc type
                            DocumentGraphicMockView(docType: item.docType, borrowerName: item.borrowerName)
                                .padding(20)
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // 3. Action Buttons Section
                    VStack(spacing: 12) {
                        // Success Action: Approve
                        Button(action: {
                            HapticsManager.triggerImpact(style: .heavy)
                            viewModel.updateDocumentStatus(applicationId: item.applicationId, docId: item.id, newStatus: .verified)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                Text("Verify & Approve Document")
                                    .font(.system(.subheadline, design: .rounded).bold())
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.successGreen)
                            .cornerRadius(12)
                        }
                        
                        // Critical Action: Flag for reupload
                        Button(action: {
                            HapticsManager.triggerImpact(style: .medium)
                            showingRejectionAlert = true
                        }) {
                            HStack {
                                Image(systemName: "exclamationmark.bubble.fill")
                                Text("Flag for Re-upload")
                                    .font(.system(.subheadline, design: .rounded).bold())
                            }
                            .foregroundColor(AppTheme.criticalRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.criticalRed.opacity(0.12))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Document Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Flag Document", isPresented: $showingRejectionAlert) {
                TextField("E.g. Photo blur, Signature mismatch...", text: $rejectionReason)
                Button("Submit Flag", role: .destructive) {
                    viewModel.updateDocumentStatus(
                        applicationId: item.applicationId,
                        docId: item.id,
                        newStatus: .rejectFlag,
                        rejectionReason: rejectionReason.isEmpty ? "Signature mismatch or photo unclear." : rejectionReason
                    )
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter clarification reason for requesting re-upload from borrower.")
            }
        }
    }
    
    private func cibilColor(for score: Int) -> Color {
        if score >= 750 { return AppTheme.successGreen }
        if score >= 650 { return AppTheme.warningAmber }
        return AppTheme.criticalRed
    }
}

// Graphic preview mockups simulating scanner screenshots
struct DocumentGraphicMockView: View {
    typealias DocumentType = OfficerDocumentType
    let docType: DocumentType
    let borrowerName: String
    
    var body: some View {
        switch docType {
        case .aadhaar:
            // Custom Government ID Graphic card
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "building.columns.fill")
                        .foregroundColor(.orange)
                    Text("GOVERNMENT OF INDIA")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(LMSColors.textPrimary)
                    Spacer()
                }
                
                HStack(alignment: .top, spacing: 14) {
                    // Profile silhouette placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LMSColors.textPrimary.opacity(0.08))
                            .frame(width: 60, height: 75)
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundColor(LMSColors.textSecondary.opacity(0.5))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(borrowerName.uppercased())
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        Text("DOB/Year: 1994")
                            .font(.system(size: 9))
                            .foregroundColor(LMSColors.textSecondary)
                        Text("Gender: M/F")
                            .font(.system(size: 9))
                            .foregroundColor(LMSColors.textSecondary)
                        Text("Address: Verified Resident")
                            .font(.system(size: 9))
                            .foregroundColor(LMSColors.textSecondary)
                    }
                    Spacer()
                }
                
                Spacer()
                
                // Aadhaar Secure UID number
                Text("XXXX XXXX 9847")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(LMSColors.textPrimary)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(LMSColors.textPrimary.opacity(0.04))
                    .cornerRadius(8)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LMSColors.surface)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
            )
            .frame(height: 200)
            
        case .salarySlip:
            // Custom Payslip breakdown ledger
            VStack(alignment: .leading, spacing: 10) {
                Text("CROWN INDUSTRIES PVT. LTD.")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                Text("SALARY SLIP · MONTH: MAY 2026")
                    .font(.system(size: 8))
                    .foregroundColor(LMSColors.textSecondary)
                
                Divider()
                
                VStack(spacing: 5) {
                    HStack {
                        Text("Basic Pay")
                        Spacer()
                        Text("₹ 85,000.00")
                    }
                    HStack {
                        Text("HRA Allowance")
                        Spacer()
                        Text("₹ 15,000.00")
                    }
                    HStack {
                        Text("PF Deductions")
                            .foregroundColor(.red)
                        Spacer()
                        Text("- ₹ 5,500.00")
                            .foregroundColor(.red)
                    }
                    Divider()
                    HStack {
                        Text("NET DISBURSED AMOUNT")
                            .bold()
                        Spacer()
                        Text("₹ 94,500.00")
                            .bold()
                            .foregroundColor(AppTheme.successGreen)
                    }
                }
                .font(.system(size: 9, design: .monospaced))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LMSColors.surface)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
            )
            .frame(height: 200)
            
        case .bankStatement:
            // Custom Bank statement ledger preview
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "building.columns.fill")
                        .foregroundColor(AppTheme.actionBlue)
                    Text("SECURE HDFC BANK STATEMENT")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                    Spacer()
                }
                
                Text("Statement Period: 01 Apr to 30 Apr")
                    .font(.system(size: 8))
                    .foregroundColor(LMSColors.textSecondary)
                
                Divider()
                
                VStack(spacing: 6) {
                    HStack {
                        Text("12 Apr · UPI Credit")
                        Spacer()
                        Text("+ ₹ 12,000")
                            .foregroundColor(AppTheme.successGreen)
                    }
                    HStack {
                        Text("15 Apr · AutoDebit EMI")
                        Spacer()
                        Text("- ₹ 8,500")
                            .foregroundColor(.red)
                    }
                    HStack {
                        Text("28 Apr · Salary Credited")
                        Spacer()
                        Text("+ ₹ 94,500")
                            .foregroundColor(AppTheme.successGreen)
                    }
                    Divider()
                    HStack {
                        Text("CLOSING ACCOUNT BALANCE")
                            .bold()
                        Spacer()
                        Text("₹ 1,12,300.00")
                            .bold()
                    }
                }
                .font(.system(size: 9, design: .monospaced))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LMSColors.surface)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
            )
            .frame(height: 200)
            
        case .gstCertificate:
            // GST registry visual card
            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 26))
                    .foregroundColor(AppTheme.successGreen)
                
                Text("FORM GST REG-06")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                Text("GOVERNMENT OF INDIA FINANCE DEPT")
                    .font(.system(size: 8))
                    .foregroundColor(LMSColors.textSecondary)
                
                Divider()
                
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 4) {
                    GridRow {
                        Text("Legal Name:")
                        Text(borrowerName.uppercased())
                    }
                    GridRow {
                        Text("Trade Name:")
                        Text("Vibrant Retailers")
                    }
                    GridRow {
                        Text("GSTIN No:")
                        Text("27AAACV9847K1Z3")
                    }
                }
                .font(.system(size: 8, design: .monospaced))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LMSColors.surface)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
            )
            .frame(height: 200)
            
        default:
            // Fallback generic scanner preview
            VStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.actionBlue)
                
                Text("Uploaded Document Scan")
                    .font(.system(.subheadline, design: .rounded).bold())
                Text("File Name: \(docType.rawValue.lowercased())_signed.pdf")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(LMSColors.textSecondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LMSColors.surface)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
            )
            .frame(height: 200)
        }
    }
}
