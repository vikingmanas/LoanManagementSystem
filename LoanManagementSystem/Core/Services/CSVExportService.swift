import Foundation

enum CSVExportService {
    static func managerReportURL(
        branchName: String,
        applicants: [ManagerApplicant],
        officers: [ManagerOfficer]
    ) throws -> URL {
        let csvData = try managerReportCSVData(branchName: branchName, applicants: applicants, officers: officers)
        let safeBranchName = safeBranchName(branchName)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Branch_Loan_Report_\(safeBranchName).csv")
        try csvData.write(to: url, options: .atomic)
        return url
    }

    static func managerReportCSVData(
        branchName: String,
        applicants: [ManagerApplicant],
        officers: [ManagerOfficer]
    ) throws -> Data {
        func escape(_ value: String) -> String {
            if value.contains(",") || value.contains("\"") || value.contains("\n") {
                return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
            }
            return value
        }

        let disbursedApplications = applicants.filter { $0.status == .approved || $0.status == .disbursed }
        let totalDisbursed = disbursedApplications.reduce(0) { $0 + $1.requestedAmount }
        let totalRecovered = disbursedApplications.reduce(0) { $0 + estimatedRecoveredAmount(for: $1) }

        var rows: [[String]] = [
            ["Branch Loan Report"],
            ["Branch", branchName],
            ["Applications", "\(applicants.count)"],
            ["Approved/Disbursed", "\(disbursedApplications.count)"],
            ["Total Disbursed", CurrencyFormatter.shared.format(totalDisbursed)],
            ["Recovered Estimate", CurrencyFormatter.shared.format(totalRecovered)],
            [],
            ["Application ID", "Borrower", "Loan Type", "Amount", "Recovered Estimate", "CIBIL", "Status", "Risk", "Assigned Officer", "Submitted"]
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        rows += applicants.map { applicant in
            [
                applicant.applicationId,
                applicant.borrowerName,
                applicant.loanType.rawValue,
                CurrencyFormatter.shared.format(applicant.requestedAmount),
                CurrencyFormatter.shared.format(estimatedRecoveredAmount(for: applicant)),
                "\(applicant.cibilScore)",
                applicant.status.rawValue,
                applicant.riskLevel.rawValue,
                applicant.assignedOfficer,
                dateFormatter.string(from: applicant.submissionDate)
            ]
        }

        rows.append([])
        rows.append(["Officer", "Role", "Applications", "Approved/Disbursed", "Loan Types", "Disbursed", "Recovered Estimate", "Active Cases", "Capacity", "Rating", "Approval Rate"])
        rows += officers.map { officer in
            let officerApplications = applicants.filter { $0.assignedOfficerId == officer.id || $0.assignedOfficer.localizedCaseInsensitiveContains(officer.name) }
            let officerDisbursed = officerApplications.filter { $0.status == .approved || $0.status == .disbursed }
            let loanTypes = Set(officerApplications.map(\.loanType.rawValue)).sorted().joined(separator: " / ")
            return [
                officer.name,
                officer.role,
                "\(officerApplications.count)",
                "\(officerDisbursed.count)",
                loanTypes.isEmpty ? "None" : loanTypes,
                CurrencyFormatter.shared.format(officerDisbursed.reduce(0) { $0 + $1.requestedAmount }),
                CurrencyFormatter.shared.format(officerDisbursed.reduce(0) { $0 + estimatedRecoveredAmount(for: $1) }),
                "\(officer.activeCases)",
                "\(officer.maxCapacity)",
                String(format: "%.1f", officer.rating),
                String(format: "%.1f%%", officer.approvalRate)
            ]
        }

        let csv = rows.map { $0.map(escape).joined(separator: ",") }.joined(separator: "\n")
        guard let data = csv.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return data
    }

    private static func estimatedRecoveredAmount(for applicant: ManagerApplicant) -> Double {
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

    private static func safeBranchName(_ branchName: String) -> String {
        branchName
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
    }
}
