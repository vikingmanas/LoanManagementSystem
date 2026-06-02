import Foundation
import UIKit

enum SanctionLetterService {
    static func generateSanctionLetter(for application: BorrowerLoanApplication) throws -> URL {
        let safeApplicationId = application.displayIdentifier
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Sanction_Letter_\(safeApplicationId).pdf")

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let borrowerName = application.formData.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let amount = application.formData.requestedAmountValue
        let tenure = application.formData.preferredTenureMonths
        let interestRate = firstRate(from: application.product.interestRateRange)
        let approvedNote = application.stageHistory.last(where: { $0.stage == .approved })?.note ?? "Approved subject to the bank's final documentation and compliance checks."

        try renderer.writePDF(to: url) { context in
            context.beginPage()

            var y: CGFloat = 52
            draw("Loan Management System", at: CGPoint(x: 52, y: y), font: .boldSystemFont(ofSize: 22))
            y += 30
            draw("Sanction Letter", at: CGPoint(x: 52, y: y), font: .systemFont(ofSize: 17), color: .darkGray)
            y += 42

            draw("Date: \(Date().formatted(date: .abbreviated, time: .omitted))", at: CGPoint(x: 52, y: y), font: .systemFont(ofSize: 10), color: .darkGray)
            y += 28
            draw("Application Reference: \(application.displayIdentifier)", at: CGPoint(x: 52, y: y), font: .boldSystemFont(ofSize: 11))
            y += 32

            let greeting = borrowerName.isEmpty ? "Dear Customer," : "Dear \(borrowerName),"
            y = drawParagraph(greeting, y: y, font: .boldSystemFont(ofSize: 12))
            y += 10
            y = drawParagraph(
                "We are pleased to inform you that your \(application.product.type.title) application has been sanctioned based on the information and documents submitted through the Loan Management System.",
                y: y
            )
            y += 18

            y = drawSectionTitle("Sanction Details", y: y)
            y = drawKeyValue("Loan Product", application.product.type.title, y: y)
            y = drawKeyValue("Sanctioned Amount", amount.formattedAsINR(), y: y)
            y = drawKeyValue("Tenure", tenure > 0 ? "\(tenure) months" : "As per approved terms", y: y)
            y = drawKeyValue("Interest Rate", interestRate, y: y)
            y = drawKeyValue("Processing Fee", application.product.processingFees, y: y)
            y = drawKeyValue("Purpose", application.formData.loanPurpose.isEmpty ? "As declared in application" : application.formData.loanPurpose, y: y)

            y += 18
            y = drawSectionTitle("Approval Remarks", y: y)
            y = drawParagraph(approvedNote, y: y)

            y += 22
            y = drawSectionTitle("Conditions", y: y)
            let conditions = [
                "All submitted KYC, income, address, and collateral documents must remain valid and verifiable.",
                "Disbursement is subject to successful execution of loan agreements and any remaining bank compliance checks.",
                "EMI, charges, and repayment obligations will be governed by the final loan agreement."
            ]
            for condition in conditions {
                y = drawParagraph("• \(condition)", y: y)
            }

            y += 30
            draw("Authorized Signatory", at: CGPoint(x: 52, y: y), font: .boldSystemFont(ofSize: 11))
            y += 16
            draw("Loan Management System", at: CGPoint(x: 52, y: y), font: .systemFont(ofSize: 10), color: .darkGray)
        }

        return url
    }

    private static func firstRate(from range: String) -> String {
        let value = range.split(separator: "-").first?.trimmingCharacters(in: .whitespacesAndNewlines)
        return value?.isEmpty == false ? "\(value ?? "") p.a." : "As per approved terms"
    }

    @discardableResult
    private static func drawSectionTitle(_ title: String, y: CGFloat) -> CGFloat {
        draw(title, at: CGPoint(x: 52, y: y), font: .boldSystemFont(ofSize: 13), color: UIColor(red: 0.04, green: 0.12, blue: 0.24, alpha: 1))
        return y + 22
    }

    @discardableResult
    private static func drawKeyValue(_ key: String, _ value: String, y: CGFloat) -> CGFloat {
        draw(key, in: CGRect(x: 52, y: y, width: 150, height: 18), font: .boldSystemFont(ofSize: 10), color: .darkGray)
        draw(value, in: CGRect(x: 215, y: y, width: 315, height: 22), font: .systemFont(ofSize: 10), color: .black)
        return y + 20
    }

    @discardableResult
    private static func drawParagraph(_ text: String, y: CGFloat, font: UIFont = .systemFont(ofSize: 10.5)) -> CGFloat {
        let rect = CGRect(x: 52, y: y, width: 490, height: 86)
        draw(text, in: rect, font: font, color: .black)
        let height = text.boundingRect(
            with: CGSize(width: 490, height: 200),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).height
        return y + max(18, ceil(height) + 6)
    }

    private static func draw(_ text: String, at point: CGPoint, font: UIFont, color: UIColor = .black) {
        draw(text, in: CGRect(x: point.x, y: point.y, width: 490, height: 26), font: font, color: color)
    }

    private static func draw(_ text: String, in rect: CGRect, font: UIFont, color: UIColor = .black) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
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
