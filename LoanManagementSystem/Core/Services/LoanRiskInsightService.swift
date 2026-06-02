import CoreML
import Foundation

struct LoanRiskInsight {
    let score: Int
    let label: String
    let explanation: String
}

enum LoanRiskInsightService {
    static func insight(for applicant: ManagerApplicant) -> LoanRiskInsight {
        _ = try? MLDictionaryFeatureProvider(dictionary: [
            "cibil_score": applicant.cibilScore,
            "requested_amount": applicant.requestedAmount,
            "verification_progress": applicant.verificationProgress
        ])

        var score = 100
        score -= max(0, 750 - applicant.cibilScore) / 4
        score -= Int(applicant.requestedAmount / 1_000_000) * 3
        score += Int(applicant.verificationProgress * 20)

        switch applicant.riskLevel {
        case .low: score += 10
        case .medium: score -= 5
        case .high: score -= 18
        case .critical: score -= 30
        }

        score = min(100, max(0, score))

        let label: String
        if score >= 80 {
            label = "Strong"
        } else if score >= 60 {
            label = "Review"
        } else {
            label = "High Risk"
        }

        let explanation = "Local ML-ready risk signal based on CIBIL, amount, verification progress, and officer risk flags."
        return LoanRiskInsight(score: score, label: label, explanation: explanation)
    }
}
