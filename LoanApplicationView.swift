//
//  LoanApplicationView.swift
//  LoanManagementSystem
//
//  Created by Anushka Sharma on 19/05/26.
//
import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformColor = UIColor
#else
import AppKit
typealias PlatformColor = NSColor
#endif

// MARK: - Models

enum LoanType: String, CaseIterable, Identifiable {
    case home = "Home Loan"
    case personal = "Personal Loan"
    case car = "Car Loan"
    case education = "Education Loan"
    case business = "Business Loan"

    var id: String { rawValue }
}

enum EmploymentType: String, CaseIterable, Identifiable {
    case salariedPrivate = "Salaried — Private"
    case salariedGovt = "Salaried — Government"
    case selfEmployed = "Self Employed"
    case business = "Business Owner"

    var id: String { rawValue }
}

enum DocumentStatus {
    case uploaded
    case verified
    case uploading
    case pending
}

struct LoanDocument: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let status: DocumentStatus
}

// MARK: - Main View

struct LoanApplicationView: View {

    @State private var selectedLoanType: LoanType = .home
    @State private var selectedEmployment: EmploymentType = .salariedPrivate

    @State private var loanAmount = "7,50,000"
    @State private var monthlyIncome = ""

    @State private var showIncomeError = false
    @State private var showSuccess = false

    @State private var documents: [LoanDocument] = [
        LoanDocument(
            title: "Aadhaar Card",
            subtitle: "Front & Back Scan",
            icon: "person.text.rectangle",
            iconColor: .blue,
            status: .uploaded
        ),

        LoanDocument(
            title: "PAN Card",
            subtitle: "Verified Document",
            icon: "creditcard",
            iconColor: .green,
            status: .verified
        ),

        LoanDocument(
            title: "Salary Slip",
            subtitle: "Last 3 Months",
            icon: "doc.text",
            iconColor: .orange,
            status: .uploading
        ),

        LoanDocument(
            title: "Bank Statement",
            subtitle: "6 Months PDF",
            icon: "building.columns",
            iconColor: .purple,
            status: .pending
        )
    ]

    var body: some View {

        NavigationStack {

            ZStack(alignment: .bottom) {

                backgroundColor
                    .ignoresSafeArea()

                ScrollView {

                    VStack(spacing: 20) {

                        eligibilityCard

                        loanSection

                        employmentSection

                        documentsSection

                        Spacer()
                            .frame(height: 120)
                    }
                    .padding()
                }

                submitButton
            }
            .navigationTitle("Apply for Loan")
            .navigationTitle("Apply for Loan")

            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif

            .sheet(isPresented: $showSuccess) {
                SuccessView()
            
            }
        }
    }
}

// MARK: - Sections

extension LoanApplicationView {

    var eligibilityCard: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("AI Eligibility Score")
                .font(.headline)
                .foregroundColor(.white)

            Text("780 / 900")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            ProgressView(value: 0.86)
                .tint(.white)

            Text("Excellent chances of approval")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var loanSection: some View {

        VStack(alignment: .leading, spacing: 10) {

            sectionTitle("Loan Details")

            GroupBox {

                VStack(spacing: 0) {

                    NavigationLink {

                        LoanTypePicker(selected: $selectedLoanType)

                    } label: {

                        row(
                            title: "Loan Type",
                            value: selectedLoanType.rawValue,
                            icon: "building.columns.fill",
                            color: .blue
                        )
                    }

                    Divider()

                    row(
                        title: "Loan Amount",
                        value: "₹ \(loanAmount)",
                        icon: "indianrupeesign.circle.fill",
                        color: .green
                    )

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {

                        row(
                            title: "Monthly Income",
                            value: monthlyIncome.isEmpty ? "Enter Amount" : "₹ \(monthlyIncome)",
                            icon: "wallet.pass.fill",
                            color: .orange
                        )

                        if showIncomeError {

                            Text("Monthly income is required")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                        }
                    }
                }
            }
        }
    }

    var employmentSection: some View {

        VStack(alignment: .leading, spacing: 10) {

            sectionTitle("Employment")

            GroupBox {

                VStack(spacing: 0) {

                    NavigationLink {

                        EmploymentPicker(selected: $selectedEmployment)

                    } label: {

                        row(
                            title: "Employment Type",
                            value: selectedEmployment.rawValue,
                            icon: "briefcase.fill",
                            color: .purple
                        )
                    }

                    Divider()

                    row(
                        title: "Company",
                        value: "Infosys Ltd.",
                        icon: "building.2.fill",
                        color: .cyan
                    )

                    Divider()

                    row(
                        title: "Role",
                        value: "Software Engineer",
                        icon: "person.fill.checkmark",
                        color: .blue
                    )
                }
            }
        }
    }

    var documentsSection: some View {

        VStack(alignment: .leading, spacing: 10) {

            sectionTitle("Documents")

            GroupBox {

                VStack(spacing: 0) {

                    ForEach(documents.indices, id: \.self) { index in

                        documentRow(documents[index])

                        if index != documents.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    var submitButton: some View {

        VStack {

            Button {

                handleSubmit()

            } label: {

                Text("Submit Application")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

// MARK: - Components

extension LoanApplicationView {

    func sectionTitle(_ title: String) -> some View {

        Text(title.uppercased())
            .font(.caption.bold())
            .foregroundColor(secondaryTextColor)
    }

    func row(
        title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {

        HStack(spacing: 12) {

            ZStack {

                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {

                Text(title)
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)

                Text(value)
                    .foregroundColor(primaryTextColor)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
    }

    func documentRow(_ doc: LoanDocument) -> some View {

        HStack {

            Image(systemName: doc.icon)
                .foregroundColor(doc.iconColor)
                .frame(width: 30)

            VStack(alignment: .leading) {

                Text(doc.title)

                Text(doc.subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            switch doc.status {

            case .uploaded:

                statusBadge("Uploaded", color: .blue)

            case .verified:

                statusBadge("Verified", color: .green)

            case .uploading:

                statusBadge("Uploading", color: .orange)

            case .pending:

                statusBadge("Upload", color: .purple)
            }
        }
        .padding()
    }

    func statusBadge(_ text: String, color: Color) -> some View {

        Text(text)
            .font(.caption.bold())
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Actions

extension LoanApplicationView {

    func handleSubmit() {

        if monthlyIncome.isEmpty {

            showIncomeError = true

            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            #endif

            return
        }

        showIncomeError = false

        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif

        showSuccess = true
    }
}

// MARK: - Pickers

struct LoanTypePicker: View {

    @Binding var selected: LoanType
    @Environment(\.dismiss) var dismiss

    var body: some View {

        List {

            ForEach(LoanType.allCases) { type in

                Button {

                    selected = type
                    dismiss()

                } label: {

                    HStack {

                        Text(type.rawValue)

                        Spacer()

                        if selected == type {

                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Loan Type")
    }
}

struct EmploymentPicker: View {

    @Binding var selected: EmploymentType
    @Environment(\.dismiss) var dismiss

    var body: some View {

        List {

            ForEach(EmploymentType.allCases) { type in

                Button {

                    selected = type
                    dismiss()

                } label: {

                    HStack {

                        Text(type.rawValue)

                        Spacer()

                        if selected == type {

                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Employment")
    }
}

// MARK: - Success Screen

struct SuccessView: View {

    @Environment(\.dismiss) var dismiss

    var body: some View {

        VStack(spacing: 20) {

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)

            Text("Application Submitted!")
                .font(.largeTitle.bold())

            Text("Your loan application has been submitted successfully.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button {

                dismiss()

            } label: {

                Text("Done")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .background(backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Cross Platform Colors

var backgroundColor: Color {

    #if os(iOS)
    return Color(UIColor.systemGroupedBackground)
    #else
    return Color(NSColor.windowBackgroundColor)
    #endif
}

var secondaryTextColor: Color {

    #if os(iOS)
    return Color(UIColor.secondaryLabel)
    #else
    return .gray
    #endif
}

var primaryTextColor: Color {

    #if os(iOS)
    return Color(UIColor.label)
    #else
    return .primary
    #endif
}

// MARK: - Preview

#Preview {

    LoanApplicationView()
}
