import Foundation

struct AdvancedRiskProfile {
    let compositeScore: Int
    let riskLevel: ManagerRiskLevel
    let factors: [ManagerRiskFactor]
}

enum AdvancedRiskEngine {
    
    static func assessRisk(for app: BorrowerLoanApplication) -> AdvancedRiskProfile {
        var factors: [ManagerRiskFactor] = []
        let formData = app.formData
        var riskScore = 100
        
        // 1. Debt-To-Income (DTI) Ratio Calculation
        let monthlyIncome = formData.monthlyIncomeValue > 0 ? formData.monthlyIncomeValue : (formData.annualIncomeValue / 12.0)
        let existingEMIs = formData.existingEMIsValue
        let creditCardObs = formData.creditCardObligationsValue
        let proposedNewEMI = app.upcomingEMI
        
        let totalDebt = existingEMIs + creditCardObs + proposedNewEMI
        let dtiRatio: Double = monthlyIncome > 0 ? (totalDebt / monthlyIncome) * 100 : 100.0
        
        if dtiRatio < 30 {
            factors.append(ManagerRiskFactor(title: "Low Debt Burden", description: "DTI is \(Int(dtiRatio))% (Excellent)", isPositive: true))
            riskScore += 10
        } else if dtiRatio <= 50 {
            factors.append(ManagerRiskFactor(title: "Moderate Debt Burden", description: "DTI is \(Int(dtiRatio))% (Acceptable)", isPositive: true))
            riskScore -= 10
        } else {
            factors.append(ManagerRiskFactor(title: "High Debt Burden", description: "DTI is \(Int(dtiRatio))%, indicating potential repayment stress.", isPositive: false))
            riskScore -= 30
        }
        
        // 2. Employment Stability
        let isSalaried = formData.employmentType.lowercased().contains("salaried")
        let yearsExp = formData.workExperienceYears
        
        if isSalaried && yearsExp >= 3 {
            factors.append(ManagerRiskFactor(title: "Stable Employment", description: "Salaried with \(yearsExp) years experience.", isPositive: true))
            riskScore += 15
        } else if isSalaried {
            factors.append(ManagerRiskFactor(title: "Recent Employment", description: "Salaried but only \(yearsExp) years experience.", isPositive: false))
            riskScore -= 5
        } else if !isSalaried && yearsExp >= 5 {
            factors.append(ManagerRiskFactor(title: "Established Business", description: "Self-employed with \(yearsExp) years experience.", isPositive: true))
            riskScore += 5
        } else {
            factors.append(ManagerRiskFactor(title: "Employment Risk", description: "Self-employed/Other with limited experience.", isPositive: false))
            riskScore -= 20
        }
        
        // 3. CIBIL Score Modifier
        let cibil = formData.creditScoreValue > 0 ? formData.creditScoreValue : 750
        if cibil >= 750 {
            factors.append(ManagerRiskFactor(title: "Excellent Credit", description: "CIBIL Score: \(cibil)", isPositive: true))
            riskScore += 15
        } else if cibil >= 650 {
            factors.append(ManagerRiskFactor(title: "Average Credit", description: "CIBIL Score: \(cibil)", isPositive: false))
            riskScore -= 10
        } else {
            factors.append(ManagerRiskFactor(title: "Poor Credit", description: "CIBIL Score: \(cibil) is below optimal thresholds.", isPositive: false))
            riskScore -= 40
        }
        
        // Final Score clamping
        riskScore = max(0, min(100, riskScore))
        
        // Determine final risk level
        let finalRiskLevel: ManagerRiskLevel
        if riskScore >= 80 {
            finalRiskLevel = .low
        } else if riskScore >= 60 {
            finalRiskLevel = .medium
        } else if riskScore >= 40 {
            finalRiskLevel = .high
        } else {
            finalRiskLevel = .critical
        }
        
        return AdvancedRiskProfile(compositeScore: riskScore, riskLevel: finalRiskLevel, factors: factors)
    }
}
