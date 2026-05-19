//
//  LoanDecisionPayload.swift
//  LoanManagementSystem
//
//  Created by Parth (iSDP) on 19/05/26.
//

import Foundation

struct LoanDecisionPayload: Codable {
    let loanId: String
    let officerId: String
    let decision: DecisionType
    let remarks: String
    
    enum DecisionType: String, Codable {
        case approved = "Approved"
        case rejected = "Rejected"
    }
}
