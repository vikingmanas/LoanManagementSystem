//
//  LoanDecisionActionBar.swift
//  LoanManagementSystem
//
//  Created by Parth (iSDP) on 19/05/26.
//

import SwiftUI

struct LoanDecisionActionBar: View {
    // Parent view se data bind hoga
    @Binding var remarks: String
    var isProcessing: Bool
    
    // Actions jo integrator pass karega
    var onApprove: () -> Void
    var onReject: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Remarks Input Field
            TextField("Enter remarks or reason for decision...", text: $remarks, axis: .vertical)
                .lineLimit(3...5)
                .padding(14)
                // Modern SwiftUI: Using .regularMaterial instead of systemGray6 for a premium frosted glass look
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                )
            
            // Action Buttons Row
            HStack(spacing: 16) {
                // REJECT BUTTON
                Button(action: onReject) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Reject")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.red.opacity(0.1))
                    // Modern SwiftUI: foregroundStyle replaces foregroundColor
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isProcessing || remarks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                // APPROVE BUTTON
                Button(action: onApprove) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Approve")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isProcessing || remarks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        // Modern SwiftUI: Native background color that adapts perfectly to Dark Mode
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: -5)
    }
}

// MARK: - Modern Swift 6 Preview
#Preview("Action Bar Preview") {
    // @Previewable is the latest Swift 6 macro to handle @State inside previews easily
    @Previewable @State var dummyRemarks = ""
    
    ZStack {
        // Background color to see the white card's shadow clearly
        Color.gray.opacity(0.1).ignoresSafeArea()
        
        LoanDecisionActionBar(
            remarks: $dummyRemarks,
            isProcessing: false,
            onApprove: { print("Approve Tapped!") },
            onReject: { print("Reject Tapped!") }
        )
        .padding()
    }
}
