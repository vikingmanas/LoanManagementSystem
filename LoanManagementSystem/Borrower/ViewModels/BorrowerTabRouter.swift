import Combine
import SwiftUI

enum BorrowerTab: Hashable {
    case dashboard
    case loans
    case applications
    case messages
    case support
}

final class BorrowerTabRouter: ObservableObject {
    @Published var selectedTab: BorrowerTab = .dashboard

    func select(_ tab: BorrowerTab) {
        selectedTab = tab
    }
}
