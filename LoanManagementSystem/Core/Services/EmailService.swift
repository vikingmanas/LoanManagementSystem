
import Foundation

/// Lightweight service to send transactional emails via the Resend API.
/// Used by Admin to send welcome/credential emails to newly created staff.
final class EmailService {
    static let shared = EmailService()
    private init() {}
    
    
    /// Sends a professional welcome email with login credentials to a newly created staff member.
    /// - Parameters:
    ///   - recipientEmail: The staff member's email address.
    ///   - recipientName: The staff member's full name.
    ///   - password: The temporary password set by the admin.
    ///   - role: "Loan Officer" or "Bank Manager".
    ///   - branchName: The branch the staff is assigned to.
    ///   - employeeCode: The assigned employee code.
    func sendWelcomeEmail(
        recipientEmail: String,
        recipientName: String,
        password: String,
        role: String,
        branchName: String,
        employeeCode: String
    ) async {
        let url = AppConfiguration.googleAppsScriptURL
        
        guard url.absoluteString != "YOUR_GOOGLE_APPS_SCRIPT_URL_HERE" else {
            print("⚠️ [EmailService] Google Apps Script URL not configured. Skipping welcome email.")
            return
        }
        
        let htmlBody = buildWelcomeHTML(
            name: recipientName,
            email: recipientEmail,
            password: password,
            role: role,
            branchName: branchName,
            employeeCode: employeeCode
        )
        
        let payload: [String: Any] = [
            "to": recipientEmail,
            "subject": "Welcome to LMS — Your Login Credentials",
            "html": htmlBody
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ [EmailService] Welcome email sent to \(recipientEmail)")
            } else {
                let body = String(data: data, encoding: .utf8) ?? "No body"
                print("❌ [EmailService] Failed to send email. Response: \(body)")
            }
        } catch {
            print("❌ [EmailService] Network error sending email: \(error.localizedDescription)")
        }
    }
    
    
    private func buildWelcomeHTML(
        name: String,
        email: String,
        password: String,
        role: String,
        branchName: String,
        employeeCode: String
    ) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="margin:0; padding:0; background-color:#f4f6f9; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">
            <table width="100%" cellpadding="0" cellspacing="0" style="padding: 40px 20px;">
                <tr>
                    <td align="center">
                        <table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff; border-radius:12px; overflow:hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.08);">
                            
                            <!-- Header -->
                            <tr>
                                <td style="background: linear-gradient(135deg, #1a2a4a 0%, #203A70 100%); padding: 36px 40px; text-align:center;">
                                    <h1 style="color:#ffffff; margin:0; font-size:24px; font-weight:700; letter-spacing:0.5px;">
                                        ₹ Loan Management System
                                    </h1>
                                    <p style="color:rgba(255,255,255,0.7); margin:8px 0 0; font-size:14px;">
                                        Staff Account Created Successfully
                                    </p>
                                </td>
                            </tr>
                            
                            <!-- Body -->
                            <tr>
                                <td style="padding: 36px 40px;">
                                    <h2 style="color:#1a2a4a; margin:0 0 8px; font-size:20px;">
                                        Welcome, \(name)! 👋
                                    </h2>
                                    <p style="color:#5a6577; line-height:1.6; margin:0 0 24px; font-size:15px;">
                                        Your account has been created by the system administrator.
                                        Below are your login credentials and assignment details.
                                    </p>
                                    
                                    <!-- Credentials Card -->
                                    <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0f4ff; border-radius:10px; border: 1px solid #d4dff7; margin-bottom:24px;">
                                        <tr>
                                            <td style="padding: 24px;">
                                                <p style="color:#203A70; font-weight:700; font-size:14px; text-transform:uppercase; letter-spacing:1px; margin:0 0 16px;">
                                                    🔐 Your Login Credentials
                                                </p>
                                                <table width="100%" cellpadding="0" cellspacing="0">
                                                    <tr>
                                                        <td style="padding:6px 0; color:#5a6577; font-size:14px; width:120px;">Email:</td>
                                                        <td style="padding:6px 0; color:#1a2a4a; font-size:14px; font-weight:600;">\(email)</td>
                                                    </tr>
                                                    <tr>
                                                        <td style="padding:6px 0; color:#5a6577; font-size:14px;">Password:</td>
                                                        <td style="padding:6px 0;">
                                                            <code style="background:#1a2a4a; color:#5ce0d2; padding:4px 12px; border-radius:6px; font-size:14px; font-weight:600; letter-spacing:1px;">
                                                                \(password)
                                                            </code>
                                                        </td>
                                                    </tr>
                                                </table>
                                            </td>
                                        </tr>
                                    </table>
                                    
                                    <!-- Assignment Card -->
                                    <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0faf5; border-radius:10px; border: 1px solid #c3e8d5; margin-bottom:24px;">
                                        <tr>
                                            <td style="padding: 24px;">
                                                <p style="color:#1a6b42; font-weight:700; font-size:14px; text-transform:uppercase; letter-spacing:1px; margin:0 0 16px;">
                                                    🏢 Assignment Details
                                                </p>
                                                <table width="100%" cellpadding="0" cellspacing="0">
                                                    <tr>
                                                        <td style="padding:6px 0; color:#5a6577; font-size:14px; width:120px;">Position:</td>
                                                        <td style="padding:6px 0; color:#1a2a4a; font-size:14px; font-weight:600;">\(role)</td>
                                                    </tr>
                                                    <tr>
                                                        <td style="padding:6px 0; color:#5a6577; font-size:14px;">Employee Code:</td>
                                                        <td style="padding:6px 0; color:#1a2a4a; font-size:14px; font-weight:600;">\(employeeCode)</td>
                                                    </tr>
                                                    <tr>
                                                        <td style="padding:6px 0; color:#5a6577; font-size:14px;">Branch:</td>
                                                        <td style="padding:6px 0; color:#1a2a4a; font-size:14px; font-weight:600;">\(branchName)</td>
                                                    </tr>
                                                </table>
                                            </td>
                                        </tr>
                                    </table>
                                    
                                    <!-- Warning -->
                                    <table width="100%" cellpadding="0" cellspacing="0" style="background:#fff8f0; border-radius:10px; border: 1px solid #f5dfc3; margin-bottom:24px;">
                                        <tr>
                                            <td style="padding: 16px 24px;">
                                                <p style="color:#b45309; font-size:13px; margin:0; line-height:1.5;">
                                                    ⚠️ <strong>Important:</strong> Please change your password after your first login for security purposes.
                                                </p>
                                            </td>
                                        </tr>
                                    </table>
                                    
                                    <p style="color:#5a6577; font-size:13px; line-height:1.5; margin:0;">
                                        If you did not expect this email, please contact your system administrator immediately.
                                    </p>
                                </td>
                            </tr>
                            
                            <!-- Footer -->
                            <tr>
                                <td style="background:#f8f9fb; padding: 20px 40px; border-top: 1px solid #e8ecf1; text-align:center;">
                                    <p style="color:#9ba3b0; font-size:12px; margin:0;">
                                        This is an automated message from Loan Management System.<br>
                                        © 2026 LMS. All rights reserved.
                                    </p>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </table>
        </body>
        </html>
        """
    }
}
