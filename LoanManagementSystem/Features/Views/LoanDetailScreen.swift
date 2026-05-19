//
//  LoanDetailScreen.swift
//  LoanManagementSystem
//
//  Created by Parth (iSDP) on 19/05/26.
//

import SwiftUI

struct LoanDetailScreen: View {
    // Modern Swift 6: @Observable class ke liye sirf @State use hota hai (@StateObject ki zaroorat nahi)
    @State private var viewModel = LoanDecisionViewModel(loanId: "LOAN_12345")
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Mock Background / Other UI
            ScrollView {
                VStack {
                    Text("Borrower Profile & Documents")
                        .font(.title3)
                        // Modern SwiftUI: foregroundStyle replaces foregroundColor
                        .foregroundStyle(.gray)
                        .padding(.top, 50)
                }
                .frame(maxWidth: .infinity)
            }
            // Pure SwiftUI minimal background replacing UIKit's systemGroupedBackground
            .background(.gray.opacity(0.1))
            
            // Tumhara component yahan drop kar diya gaya hai! (Plug-and-play)
            LoanDecisionActionBar(
                remarks: $viewModel.remarks,
                isProcessing: viewModel.isProcessing,
                onApprove: {
                    Task {
                        await viewModel.submitDecision(isApproved: true)
                    }
                },
                onReject: {
                    Task {
                        await viewModel.submitDecision(isApproved: false)
                    }
                }
            )
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#Preview {
    LoanDetailScreen()
}
