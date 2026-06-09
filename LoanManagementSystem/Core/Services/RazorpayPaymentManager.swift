import Foundation
import UIKit
import Razorpay

class RazorpayPaymentManager: NSObject, RazorpayPaymentCompletionProtocolWithData {
    static let shared = RazorpayPaymentManager()
    
    private var razorpay: RazorpayCheckout!
    
    private let testAPIKey = "rzp_test_Sx4QQYFH2GpWM0"
    
    var onPaymentSuccess: ((String) -> Void)?
    var onPaymentFailure: ((String) -> Void)?
    
    private override init() {
        super.init()
    }
    
    func presentPayment(amountInINR: Double, receiptId: String, from viewController: UIViewController) {

        let amountInPaise = Int(amountInINR * 100)
        
        self.razorpay = RazorpayCheckout.initWithKey(testAPIKey, andDelegateWithData: self)
        
        let options: [String: Any] = [
            "amount": amountInPaise,
            "currency": "INR",
            "description": "EMI Repayment",
            "receipt": receiptId,
            "name": "Loan Management System",
            "theme": [
                "color": "#1C243B"
            ]
        ]
        
        razorpay.open(options, displayController: viewController)
    }
    
    func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable : Any]?) {
        DispatchQueue.main.async {
            self.onPaymentFailure?(str)
            self.clearCallbacks()
        }
    }
    
    func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable : Any]?) {
        DispatchQueue.main.async {
            self.onPaymentSuccess?(payment_id)
            self.clearCallbacks()
        }
    }
    
    private func clearCallbacks() {
        onPaymentSuccess = nil
        onPaymentFailure = nil
    }
}

extension UIViewController {
    var topMostViewController: UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController
        }
        if let nav = self as? UINavigationController {
            return nav.visibleViewController?.topMostViewController ?? self
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController ?? self
        }
        return self
    }
}
