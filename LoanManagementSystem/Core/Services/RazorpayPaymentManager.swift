import Foundation
import UIKit
#if canImport(RazorpayCheckout)
import RazorpayCheckout
#elseif canImport(Razorpay)
import Razorpay
#endif

class RazorpayPaymentManager: NSObject {
    static let shared = RazorpayPaymentManager()
    
    #if canImport(RazorpayCheckout) || canImport(Razorpay)
    private var razorpay: RazorpayCheckout!
    #endif
    
    // The user will replace this with their actual test key
    private let testAPIKey = "rzp_test_Sx4QQYFH2GpWM0"
    
    var onPaymentSuccess: ((String) -> Void)?
    var onPaymentFailure: ((String) -> Void)?
    
    private override init() {
        super.init()
    }
    
    func presentPayment(amountInINR: Double, receiptId: String, from viewController: UIViewController) {
        #if canImport(RazorpayCheckout) || canImport(Razorpay)
        // Razorpay expects the amount in the smallest currency sub-unit (paise for INR)
        let amountInPaise = Int(amountInINR * 100)
        
        self.razorpay = RazorpayCheckout.initWithKey(testAPIKey, andDelegateWithData: self)
        
        let options: [String: Any] = [
            "amount": amountInPaise,
            "currency": "INR",
            "description": "EMI Repayment",
            "receipt": receiptId,
            "name": "Loan Management System",
            "theme": [
                "color": "#1C243B" // LMS brandNavy
            ]
        ]
        
        razorpay.open(options, displayController: viewController)
        #else
        DispatchQueue.main.async {
            self.onPaymentFailure?("Razorpay SDK is not linked with this build.")
            self.clearCallbacks()
        }
        #endif
    }
    
    private func clearCallbacks() {
        onPaymentSuccess = nil
        onPaymentFailure = nil
    }
}

#if canImport(RazorpayCheckout) || canImport(Razorpay)
extension RazorpayPaymentManager: RazorpayPaymentCompletionProtocolWithData {
    
    // MARK: - RazorpayPaymentCompletionProtocolWithData
    
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
}
#endif

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
