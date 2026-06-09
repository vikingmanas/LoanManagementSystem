import SwiftUI

struct VoiceOverCardModifier: ViewModifier {
    let text: String
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture().onEnded {
                    VoiceOverManager.shared.speak(text)
                }
            )
            .accessibilityLabel(text)
    }
}

extension View {
    func voiceOverCard(text: String) -> some View {
        modifier(VoiceOverCardModifier(text: text))
    }
}
