import Foundation
import UIKit

enum CSVExportService {
    static func managerReportURL(
        branchName: String,
        applicants: [ManagerApplicant],
        officers: [ManagerOfficer]
    ) throws -> URL {
        func escape(_ value: String) -> String {
            if value.contains(",") || value.contains("\"") || value.contains("\n") {
                return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
            }
            return value
        }

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
