import Foundation

enum CSVExportService {
    static func managerReportURL(
        branchName: String,
        applicants: [ManagerApplicant],
        officers: [ManagerOfficer]
    ) throws -> URL {
        var rows: [[String]] = [
            ["Application ID", "Borrower", "Loan Type", "Amount", "CIBIL", "Status", "Risk", "Assigned Officer", "Submitted"]
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
                "\(applicant.cibilScore)",
                applicant.status.rawValue,
                applicant.riskLevel.rawValue,
                applicant.assignedOfficer,
                dateFormatter.string(from: applicant.submissionDate)
            ]
        }

        rows.append([])
        rows.append(["Officer", "Role", "Active Cases", "Capacity", "Rating", "Approval Rate"])
        rows += officers.map { officer in
            [
                officer.name,
                officer.role,
                "\(officer.activeCases)",
                "\(officer.maxCapacity)",
                String(format: "%.1f", officer.rating),
                "\(Int(officer.approvalRate * 100))%"
            ]
        }

        let csv = rows.map { $0.map(escape).joined(separator: ",") }.joined(separator: "\n")
        let safeBranchName = branchName
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Monthly_Branch_Report_\(safeBranchName).csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
