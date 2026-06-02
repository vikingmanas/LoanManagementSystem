import Foundation
import UIKit

enum ManagerReportFrequency: String, CaseIterable, Identifiable, Hashable {
    case daily
    case weekly
    case monthly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }

    var storageFolder: String { rawValue }
}

struct StoredManagerReport: Identifiable, Hashable {
    let id = UUID()
    var frequency: ManagerReportFrequency
    var generatedAt: Date
    var csvURL: URL
    var pdfURL: URL

    var title: String {
        "\(frequency.displayName) Branch Loan Report"
    }
}

enum ManagerReportGenerationError: LocalizedError {
    case unableToCreatePDF

    var errorDescription: String? {
        switch self {
        case .unableToCreatePDF:
            return "Could not create the branch loan report PDF."
        }
    }
}

final class ManagerReportGenerationService {
    static let shared = ManagerReportGenerationService()

    private let bucket = "reports"
    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current

    private init() {}

    func generateAndStoreDueReports(
        branchOverview: BranchOverview,
        applicants: [ManagerApplicant],
        officers: [ManagerOfficer],
        generatedAt: Date = Date()
    ) async throws -> [StoredManagerReport] {
        var storedReports: [StoredManagerReport] = []

        for frequency in ManagerReportFrequency.allCases where isDue(frequency, branchCode: branchOverview.code, now: generatedAt) {
            let storedReport = try await generateAndStoreReport(
                frequency: frequency,
                branchOverview: branchOverview,
                applicants: applicants,
                officers: officers,
                generatedAt: generatedAt
            )
            markStored(frequency, branchCode: branchOverview.code, at: generatedAt)
            storedReports.append(storedReport)
        }

        return storedReports
    }

    func generateAndStoreReport(
        frequency: ManagerReportFrequency,
        branchOverview: BranchOverview,
        applicants: [ManagerApplicant],
        officers: [ManagerOfficer],
        generatedAt: Date = Date()
    ) async throws -> StoredManagerReport {
        let csvData = try CSVExportService.managerReportCSVData(
            branchName: branchOverview.name,
            applicants: applicants,
            officers: officers
        )
        let pdfData = try pdfData(
            frequency: frequency,
            branchOverview: branchOverview,
            applicants: applicants,
            officers: officers,
            generatedAt: generatedAt
        )
        let safeBranch = safePathComponent(branchOverview.code.isEmpty ? branchOverview.name : branchOverview.code)
        let stamp = fileStamp(for: generatedAt)
        let basePath = "manager/\(safeBranch)/\(frequency.storageFolder)/branch-loan-report-\(stamp)"

        async let csvURL = StorageService.shared.uploadDocument(
            data: csvData,
            bucket: bucket,
            path: "\(basePath).csv",
            contentType: "text/csv"
        )
        async let pdfURL = StorageService.shared.uploadDocument(
            data: pdfData,
            bucket: bucket,
            path: "\(basePath).pdf",
            contentType: "application/pdf"
        )

        return try await StoredManagerReport(
            frequency: frequency,
            generatedAt: generatedAt,
            csvURL: csvURL,
            pdfURL: pdfURL
        )
    }

    func localPDFURL(
        frequency: ManagerReportFrequency,
        branchOverview: BranchOverview,
        applicants: [ManagerApplicant],
        officers: [ManagerOfficer],
        generatedAt: Date = Date()
    ) throws -> URL {
        let data = try pdfData(
            frequency: frequency,
            branchOverview: branchOverview,
            applicants: applicants,
            officers: officers,
            generatedAt: generatedAt
        )
        let safeBranch = safePathComponent(branchOverview.name)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Branch_Loan_Report_\(safeBranch)_\(fileStamp(for: generatedAt)).pdf")
        try data.write(to: url, options: .atomic)
        return url
    }

    private func isDue(_ frequency: ManagerReportFrequency, branchCode: String, now: Date) -> Bool {
        guard let lastRun = defaults.object(forKey: defaultsKey(frequency, branchCode: branchCode)) as? Date else {
            return true
        }

        switch frequency {
        case .daily:
            return !calendar.isDate(lastRun, inSameDayAs: now)
        case .weekly:
            return !calendar.isDate(lastRun, equalTo: now, toGranularity: .weekOfYear)
        case .monthly:
            return !calendar.isDate(lastRun, equalTo: now, toGranularity: .month)
        }
    }

    private func markStored(_ frequency: ManagerReportFrequency, branchCode: String, at date: Date) {
        defaults.set(date, forKey: defaultsKey(frequency, branchCode: branchCode))
    }

    private func defaultsKey(_ frequency: ManagerReportFrequency, branchCode: String) -> String {
        "managerReport.lastStored.\(safePathComponent(branchCode)).\(frequency.rawValue)"
    }

    private func pdfData(
        frequency: ManagerReportFrequency,
        branchOverview: BranchOverview,
        applicants: [ManagerApplicant],
        officers: [ManagerOfficer],
        generatedAt: Date
    ) throws -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let snapshot = ManagerReportSnapshot(applicants: applicants, officers: officers)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        var lines = [
            "\(frequency.displayName) Branch Loan Report",
            "Branch: \(branchOverview.name) (\(branchOverview.code))",
            "Region: \(branchOverview.region)",
            "Generated: \(dateFormatter.string(from: generatedAt))",
            "",
            "Branch Loan Book",
            "Applications: \(snapshot.totalApplications)",
            "Approved/Disbursed: \(snapshot.disbursedCount)",
            "Disbursed Amount: \(CurrencyFormatter.shared.format(snapshot.totalDisbursed))",
            "Recovered Estimate: \(CurrencyFormatter.shared.format(snapshot.totalRecovered))",
            "",
            "Loan Officer Report"
        ]

        lines += snapshot.officerRows.map { row in
            "\(row.officer.name) - \(row.disbursedCount)/\(row.applicationCount) loans, \(CurrencyFormatter.shared.format(row.disbursedAmount)) disbursed, \(CurrencyFormatter.shared.format(row.recoveredAmount)) recovered, \(row.primaryLoanTypeText)"
        }

        lines.append("")
        lines.append("Loan Type Mix")
        lines += snapshot.loanTypeRows.map { row in
            "\(row.loanType.rawValue) - \(row.applicationCount) applications, \(CurrencyFormatter.shared.format(row.disbursedAmount)) disbursed, \(CurrencyFormatter.shared.format(row.recoveredAmount)) recovered"
        }

        lines.append("")
        lines.append("Recovery Note")
        lines.append("Recovered amount is estimated from approved and disbursed loans using tenure, interest rate, and elapsed time in the available application data.")

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray
        ]
        let headingAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        return renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = 42

            for (index, line) in lines.enumerated() {
                if y > pageRect.height - 56 {
                    context.beginPage()
                    y = 42
                }

                let attributes: [NSAttributedString.Key: Any]
                if index == 0 {
                    attributes = titleAttributes
                } else if !line.isEmpty && !line.contains(":") && !line.contains("-") {
                    attributes = headingAttributes
                } else {
                    attributes = bodyAttributes
                }

                let rect = CGRect(x: 42, y: y, width: pageRect.width - 84, height: 40)
                line.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
                y += line.isEmpty ? 12 : 24
            }
        }
    }

    private func fileStamp(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: date)
    }

    private func safePathComponent(_ value: String) -> String {
        value
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }
}

private struct ManagerReportSnapshot {
    let applicants: [ManagerApplicant]
    let officers: [ManagerOfficer]

    var totalApplications: Int { applicants.count }

    var disbursedApplications: [ManagerApplicant] {
        applicants.filter { $0.status == .approved || $0.status == .disbursed }
    }

    var disbursedCount: Int { disbursedApplications.count }

    var totalDisbursed: Double {
        disbursedApplications.reduce(0) { $0 + $1.requestedAmount }
    }

    var totalRecovered: Double {
        disbursedApplications.reduce(0) { $0 + Self.estimatedRecoveredAmount(for: $1) }
    }

    var loanTypeRows: [ManagerReportLoanTypeRow] {
        ManagerLoanType.allCases.compactMap { loanType in
            let typeApps = applicants.filter { $0.loanType == loanType }
            guard !typeApps.isEmpty else { return nil }
            return ManagerReportLoanTypeRow(loanType: loanType, applications: typeApps)
        }
        .sorted { $0.disbursedAmount > $1.disbursedAmount }
    }

    var officerRows: [ManagerReportOfficerRow] {
        officers.compactMap { officer in
            let officerApps = applicants.filter { $0.assignedOfficerId == officer.id || $0.assignedOfficer.localizedCaseInsensitiveContains(officer.name) }
            guard !officerApps.isEmpty else { return nil }
            return ManagerReportOfficerRow(officer: officer, applications: officerApps)
        }
        .sorted { $0.disbursedAmount > $1.disbursedAmount }
    }

    static func estimatedRecoveredAmount(for applicant: ManagerApplicant) -> Double {
        guard applicant.status == .approved || applicant.status == .disbursed else { return 0 }
        let monthsSinceSubmission = max(1, Calendar.current.dateComponents([.month], from: applicant.submissionDate, to: Date()).month ?? 1)
        let paidMonths = min(max(applicant.tenure, 1), monthsSinceSubmission)
        let monthlyRate = applicant.interestRate / 1200
        let emi: Double

        if monthlyRate == 0 {
            emi = applicant.requestedAmount / Double(max(applicant.tenure, 1))
        } else {
            let factor = pow(1 + monthlyRate, Double(max(applicant.tenure, 1)))
            emi = applicant.requestedAmount * monthlyRate * factor / (factor - 1)
        }

        return min(applicant.requestedAmount, emi * Double(paidMonths))
    }
}

private struct ManagerReportLoanTypeRow {
    let loanType: ManagerLoanType
    let applicationCount: Int
    let disbursedCount: Int
    let disbursedAmount: Double
    let recoveredAmount: Double

    init(loanType: ManagerLoanType, applications: [ManagerApplicant]) {
        self.loanType = loanType
        self.applicationCount = applications.count
        let disbursed = applications.filter { $0.status == .approved || $0.status == .disbursed }
        self.disbursedCount = disbursed.count
        self.disbursedAmount = disbursed.reduce(0) { $0 + $1.requestedAmount }
        self.recoveredAmount = disbursed.reduce(0) { $0 + ManagerReportSnapshot.estimatedRecoveredAmount(for: $1) }
    }
}

private struct ManagerReportOfficerRow {
    let officer: ManagerOfficer
    let applicationCount: Int
    let disbursedCount: Int
    let disbursedAmount: Double
    let recoveredAmount: Double
    let loanTypeRows: [ManagerReportLoanTypeRow]

    var primaryLoanTypeText: String {
        guard let topType = loanTypeRows.first else { return "No approved loans yet" }
        return "Primary type: \(topType.loanType.rawValue)"
    }

    init(officer: ManagerOfficer, applications: [ManagerApplicant]) {
        self.officer = officer
        self.applicationCount = applications.count
        let disbursed = applications.filter { $0.status == .approved || $0.status == .disbursed }
        self.disbursedCount = disbursed.count
        self.disbursedAmount = disbursed.reduce(0) { $0 + $1.requestedAmount }
        self.recoveredAmount = disbursed.reduce(0) { $0 + ManagerReportSnapshot.estimatedRecoveredAmount(for: $1) }
        self.loanTypeRows = ManagerLoanType.allCases.compactMap { loanType in
            let typeApps = applications.filter { $0.loanType == loanType }
            guard !typeApps.isEmpty else { return nil }
            return ManagerReportLoanTypeRow(loanType: loanType, applications: typeApps)
        }
        .sorted { $0.disbursedAmount > $1.disbursedAmount }
    }
}
