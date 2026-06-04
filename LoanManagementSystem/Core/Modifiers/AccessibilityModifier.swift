import SwiftUI
import Combine

// MARK: - Reusable modifier that applies all accessibility overrides.
// Attach this to any view (including sheet content) that needs to respect
// the user's accessibility preferences.

struct AccessibilityOverridesModifier: ViewModifier {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("forceHighContrast") private var forceHighContrast = false
    @AppStorage("forceBoldText") private var forceBoldText = false
    @AppStorage("reduceMotion") private var reduceMotion = false

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .bold(forceBoldText)
            .brightness(forceHighContrast ? (isDarkMode ? 0.05 : -0.05) : 0.0)
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
    /// Applies all user-selected accessibility overrides (dark mode, bold text,
    /// high contrast, reduce motion).
    /// Apply this at the app root AND inside every `.sheet` / `.fullScreenCover`
    /// to ensure settings take effect immediately on all presentations.
    func accessibilityOverrides() -> some View {
        modifier(AccessibilityOverridesModifier())
    }
}


// MARK: - Convenience sheet wrappers that auto-apply accessibility overrides.
// Use these in place of `.sheet(...)` to guarantee every sheet
// inherits bold text, contrast, dark mode, and reduce-motion settings
// without requiring manual `.accessibilityOverrides()` calls.

extension View {
    /// Drop-in replacement for `.sheet(isPresented:onDismiss:content:)` that
    /// automatically applies all accessibility overrides to the sheet content.
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

    /// Drop-in replacement for `.sheet(item:onDismiss:content:)` that
    /// automatically applies all accessibility overrides to the sheet content.
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

    /// Drop-in replacement for `.fullScreenCover(isPresented:onDismiss:content:)`
    /// that automatically applies all accessibility overrides.
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

    /// Drop-in replacement for `.fullScreenCover(item:onDismiss:content:)`
    /// that automatically applies all accessibility overrides.
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
