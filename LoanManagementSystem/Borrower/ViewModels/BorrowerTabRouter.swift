import Observation
import Combine
import SwiftUI

enum BorrowerTab: Hashable {
    case dashboard
    case loans
    case applications
    case messages
    case support
}

@Observable
final class BorrowerTabRouter {
    var selectedTab: BorrowerTab = .dashboard

    func select(_ tab: BorrowerTab) {
        selectedTab = tab
    }
}
