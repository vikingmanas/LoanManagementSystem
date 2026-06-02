import Foundation
import UIKit

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

    static func managerReportPDFURL(
        branchName: String,
        branchRegion: String,
        activeLoanCount: Int,
        totalDisbursed: Double,
        applicants: [ManagerApplicant],
        officers: [ManagerOfficer]
    ) throws -> URL {
        let safeBranchName = branchName
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Monthly_Branch_Report_\(safeBranchName).pdf")

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        try renderer.writePDF(to: url) { context in
            context.beginPage()

            var y: CGFloat = 44
            draw("Loan Management System", at: CGPoint(x: 44, y: y), font: .boldSystemFont(ofSize: 22))
            y += 30
            draw("Monthly Branch Report", at: CGPoint(x: 44, y: y), font: .systemFont(ofSize: 16), color: .darkGray)
            y += 34

            let summaryRows = [
                ("Branch", branchName),
                ("Region", branchRegion),
                ("Generated", Date().formatted(date: .abbreviated, time: .shortened)),
                ("Active Loans", "\(activeLoanCount)"),
                ("Total Disbursed", CurrencyFormatter.shared.format(totalDisbursed)),
                ("Pending Approvals", "\(applicants.filter { $0.status == .sentToManager || $0.status == .needsClarification }.count)")
            ]

            y = drawSectionTitle("Summary", y: y)
            for row in summaryRows {
                y = drawKeyValue(row.0, row.1, y: y)
            }

            y += 18
            y = drawSectionTitle("Applications", y: y)
            y = drawTableHeader(["Application", "Borrower", "Amount", "Status"], widths: [105, 170, 110, 120], y: y)
            for applicant in applicants.prefix(12) {
                if y > pageRect.height - 80 {
                    context.beginPage()
                    y = 44
                    y = drawTableHeader(["Application", "Borrower", "Amount", "Status"], widths: [105, 170, 110, 120], y: y)
                }
                y = drawTableRow(
                    [
                        applicant.applicationId,
                        applicant.borrowerName,
                        CurrencyFormatter.shared.format(applicant.requestedAmount),
                        applicant.status.rawValue
                    ],
                    widths: [105, 170, 110, 120],
                    y: y
                )
            }

            y += 18
            if y > pageRect.height - 160 {
                context.beginPage()
                y = 44
            }
            y = drawSectionTitle("Officer Performance", y: y)
            y = drawTableHeader(["Officer", "Cases", "Capacity", "Approval"], widths: [205, 80, 90, 110], y: y)
            for officer in officers.prefix(12) {
                if y > pageRect.height - 80 {
                    context.beginPage()
                    y = 44
                    y = drawTableHeader(["Officer", "Cases", "Capacity", "Approval"], widths: [205, 80, 90, 110], y: y)
                }
                y = drawTableRow(
                    [
                        officer.name,
                        "\(officer.activeCases)",
                        "\(officer.maxCapacity)",
                        "\(Int(officer.approvalRate * 100))%"
                    ],
                    widths: [205, 80, 90, 110],
                    y: y
                )
            }
        }

        return url
    }

    @discardableResult
    private static func drawSectionTitle(_ title: String, y: CGFloat) -> CGFloat {
        draw(title, at: CGPoint(x: 44, y: y), font: .boldSystemFont(ofSize: 14), color: UIColor(red: 0.04, green: 0.12, blue: 0.24, alpha: 1))
        return y + 24
    }

    @discardableResult
    private static func drawKeyValue(_ key: String, _ value: String, y: CGFloat) -> CGFloat {
        draw(key, at: CGPoint(x: 44, y: y), font: .boldSystemFont(ofSize: 10), color: .darkGray)
        draw(value, at: CGPoint(x: 180, y: y), font: .systemFont(ofSize: 10), color: .black)
        return y + 18
    }

    @discardableResult
    private static func drawTableHeader(_ columns: [String], widths: [CGFloat], y: CGFloat) -> CGFloat {
        var x: CGFloat = 44
        for (index, column) in columns.enumerated() {
            draw(column, in: CGRect(x: x, y: y, width: widths[index] - 8, height: 18), font: .boldSystemFont(ofSize: 9), color: .white)
            x += widths[index]
        }
        UIColor(red: 0.04, green: 0.12, blue: 0.24, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: 38, y: y - 4, width: widths.reduce(0, +) + 12, height: 22)).fill()
        x = 44
        for (index, column) in columns.enumerated() {
            draw(column, in: CGRect(x: x, y: y, width: widths[index] - 8, height: 18), font: .boldSystemFont(ofSize: 9), color: .white)
            x += widths[index]
        }
        return y + 24
    }

    @discardableResult
    private static func drawTableRow(_ columns: [String], widths: [CGFloat], y: CGFloat) -> CGFloat {
        var x: CGFloat = 44
        for (index, column) in columns.enumerated() {
            draw(column, in: CGRect(x: x, y: y, width: widths[index] - 8, height: 26), font: .systemFont(ofSize: 8), color: .black)
            x += widths[index]
        }
        UIColor.lightGray.withAlphaComponent(0.35).setStroke()
        UIBezierPath(rect: CGRect(x: 38, y: y - 4, width: widths.reduce(0, +) + 12, height: 28)).stroke()
        return y + 28
    }

    private static func draw(_ text: String, at point: CGPoint, font: UIFont, color: UIColor = .black) {
        draw(text, in: CGRect(x: point.x, y: point.y, width: 500, height: 24), font: font, color: color)
    }

    private static func draw(_ text: String, in rect: CGRect, font: UIFont, color: UIColor = .black) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        (text as NSString).draw(
            in: rect,
            withAttributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ]
        )
    }
}
