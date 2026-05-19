//
//  LoanDecisionViewModel.swift
//  LoanManagementSystem
//
//  Created by Parth (iSDP) on 19/05/26.
//

import Foundation
import Observation

@Observable
@MainActor
class LoanDecisionViewModel {
    var remarks: String = ""
    var isProcessing: Bool = false
    var errorMessage: String? = nil
    
    let loanId: String
    
    init(loanId: String) {
        self.loanId = loanId
    }
    
    func submitDecision(isApproved: Bool) async {
        isProcessing = true
        errorMessage = nil
        
        let payload = LoanDecisionPayload(
            loanId: loanId,
            officerId: "current_officer_id", // Mock ID, baad me Auth session se aayega
            decision: isApproved ? .approved : .rejected,
            remarks: remarks
        )
        
        do {
            // Yahan mock API call hai using Swift 6 concurrency sleep
            // Baad me integrator isko Firebase call se replace kar dega
            try await Task.sleep(for: .seconds(1.5))
            
            print("Success! Data sent to backend: \(payload)")
            self.remarks = "" // Submit hone ke baad box clear kar do
            
        } catch {
            errorMessage = "Failed to submit. Please try again."
        }
        
        isProcessing = false
    }
}
