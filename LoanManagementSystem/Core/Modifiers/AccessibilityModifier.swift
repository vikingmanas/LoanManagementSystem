import SwiftUI
import Combine

struct AccessibilityOverridesModifier: ViewModifier {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("forceHighContrast") private var forceHighContrast = false
    @AppStorage("forceBoldText") private var forceBoldText = false
    @AppStorage("reduceMotion") private var reduceMotion = false

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .bold(forceBoldText)
            .contrast(forceHighContrast ? 1.2 : 1.0)
            .transaction { transaction in
                if reduceMotion {
                    transaction.disablesAnimations = true
                    transaction.animation = nil
                }
            }
    }
}

extension View {
    func accessibilityOverrides() -> some View {
        modifier(AccessibilityOverridesModifier())
    }
}

extension View {
    func accessibleSheet<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        sheet(isPresented: isPresented, onDismiss: onDismiss) {
            content()
                .accessibilityOverrides()
        }
    }

    func accessibleSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        sheet(item: item, onDismiss: onDismiss) { value in
            content(value)
                .accessibilityOverrides()
        }
    }

    func accessibleFullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        fullScreenCover(isPresented: isPresented, onDismiss: onDismiss) {
            content()
                .accessibilityOverrides()
        }
    }

    func accessibleFullScreenCover<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        fullScreenCover(item: item, onDismiss: onDismiss) { value in
            content(value)
                .accessibilityOverrides()
        }
    }
}

@discardableResult
public func withAnimation<Result>(_ animation: Animation? = .default, _ body: () throws -> Result) rethrows -> Result {
    let reduceMotion = UserDefaults.standard.bool(forKey: "reduceMotion")
    if reduceMotion {
        var transaction = SwiftUI.Transaction(animation: nil)
        transaction.disablesAnimations = true
        return try SwiftUI.withTransaction(transaction, body)
    } else {
        return try SwiftUI.withAnimation(animation, body)
    }
}
