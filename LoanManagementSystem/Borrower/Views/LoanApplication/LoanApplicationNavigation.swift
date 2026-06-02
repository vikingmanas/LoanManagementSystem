import SwiftUI

enum LoanApplicationRoute: Hashable {
    case productDetail(BorrowerLoanProduct)
    case applicationWizard(BorrowerLoanProduct)
    case tracking(BorrowerLoanApplication)
    case governmentSchemeDetail(GovernmentSchemeCardModel)
}
