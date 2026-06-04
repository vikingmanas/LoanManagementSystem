import Foundation
import PDFKit
import SwiftUI
import UIKit

@MainActor
final class AuditReportExporter {
    static let shared = AuditReportExporter()
    private init() {}

    func generateCSV(from entries: [AuditLogEntry]) -> URL? {
        var csvString = "Action,User,Entity Type,Entity ID,Timestamp,Details\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for entry in entries {
            let action = escapeCSV(entry.action)
            let user = escapeCSV(entry.userName)
            let entityType = escapeCSV(entry.entityType)
            let entityId = escapeCSV(entry.entityId)
            let timestamp = escapeCSV(dateFormatter.string(from: entry.timestamp))
            let details = escapeCSV(entry.details)
            
            csvString.append("\(action),\(user),\(entityType),\(entityId),\(timestamp),\(details)\n")
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Audit_Report_\(Int(Date().timeIntervalSince1970)).csv"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }
    
    private func escapeCSV(_ text: String) -> String {
        var escaped = text
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            escaped = escaped.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return escaped
    }
    
    func generatePDF(from entries: [AuditLogEntry]) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Loan Management System",
            kCGPDFContextAuthor: "Admin",
            kCGPDFContextTitle: "Audit Trail Report"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0 // Letter size
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24)
            ]
            
            let title = "Audit Trail Report"
            title.draw(at: CGPoint(x: 20, y: 20), withAttributes: titleAttributes)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]
            let generatedText = "Generated on: \(dateFormatter.string(from: Date()))"
            generatedText.draw(at: CGPoint(x: 20, y: 55), withAttributes: subtitleAttributes)
            
            let countText = "Total Entries: \(entries.count)"
            countText.draw(at: CGPoint(x: 20, y: 70), withAttributes: subtitleAttributes)
            
            var currentY: CGFloat = 110.0
            
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12)
            ]
            
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10)
            ]
            
            "Action".draw(at: CGPoint(x: 20, y: currentY), withAttributes: headerAttributes)
            "User".draw(at: CGPoint(x: 180, y: currentY), withAttributes: headerAttributes)
            "Entity".draw(at: CGPoint(x: 320, y: currentY), withAttributes: headerAttributes)
            "Date".draw(at: CGPoint(x: 450, y: currentY), withAttributes: headerAttributes)
            
            currentY += 20
            
            context.cgContext.move(to: CGPoint(x: 20, y: currentY))
            context.cgContext.addLine(to: CGPoint(x: pageWidth - 20, y: currentY))
            context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            context.cgContext.strokePath()
            currentY += 10
            
            for entry in entries {
                if currentY > pageHeight - 60 {
                    context.beginPage()
                    currentY = 20
                }
                
                let actionRect = CGRect(x: 20, y: currentY, width: 150, height: 30)
                let userRect = CGRect(x: 180, y: currentY, width: 130, height: 30)
                let entityRect = CGRect(x: 320, y: currentY, width: 120, height: 30)
                let dateRect = CGRect(x: 450, y: currentY, width: 140, height: 30)
                
                entry.action.draw(in: actionRect, withAttributes: bodyAttributes)
                entry.userName.draw(in: userRect, withAttributes: bodyAttributes)
                "\(entry.entityType)\n\(entry.entityId)".draw(in: entityRect, withAttributes: bodyAttributes)
                dateFormatter.string(from: entry.timestamp).draw(in: dateRect, withAttributes: bodyAttributes)
                
                currentY += 30 // Space for multiline text
                
                let detailRect = CGRect(x: 20, y: currentY, width: pageWidth - 40, height: 40)
                entry.details.draw(in: detailRect, withAttributes: subtitleAttributes)
                
                currentY += 25
                
                context.cgContext.move(to: CGPoint(x: 20, y: currentY))
                context.cgContext.addLine(to: CGPoint(x: pageWidth - 20, y: currentY))
                context.cgContext.setStrokeColor(UIColor.systemGroupedBackground.cgColor)
                context.cgContext.strokePath()
                currentY += 10
            }
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Audit_Report_\(Int(Date().timeIntervalSince1970)).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to write PDF: \(error)")
            return nil
        }
    }
}
