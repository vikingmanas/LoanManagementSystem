import Observation
import Combine
import Foundation
import LocalAuthentication

@MainActor
@Observable
final class LocalSecurityService {
    static let shared = LocalSecurityService()

    private(set) var lastOTPCode: String = ""
    private(set) var lastOTPIssuedAt: Date?

    private let otpTTL: TimeInterval = 300

    private init() {}

    var biometricTypeName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Biometric Login"
        }
    }

    func canUseBiometrics() -> Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Password"

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }

    @discardableResult
    func issueOTP() -> String {
        let code = String(format: "%06d", Int.random(in: 100_000...999_999))
        lastOTPCode = code
        lastOTPIssuedAt = Date()
        return code
    }

    func verifyOTP(_ input: String) -> Bool {
        let cleanInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let issuedAt = lastOTPIssuedAt,
              !lastOTPCode.isEmpty,
              Date().timeIntervalSince(issuedAt) <= otpTTL else {
            return false
        }

        return cleanInput == lastOTPCode
    }

    func clearOTP() {
        lastOTPCode = ""
        lastOTPIssuedAt = nil
    }
}
