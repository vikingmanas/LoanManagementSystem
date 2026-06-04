import SwiftUI

struct InAppVoiceOverModifier: ViewModifier {
    @StateObject private var ttsManager = TTSManager.shared
    @AppStorage("enableInAppVoiceOver") private var enableInAppVoiceOver: Bool = false
    
    let textToRead: () -> String
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottomTrailing) {
            content
            
            if enableInAppVoiceOver {
                Button(action: {
                    if ttsManager.isSpeaking {
                        ttsManager.stopSpeaking()
                    } else {
                        ttsManager.speak(text: textToRead())
                    }
                }) {
                    Image(systemName: ttsManager.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.1")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(16)
                        .background(ttsManager.isSpeaking ? LMSColors.coral : LMSColors.brandNavy)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding()
                .accessibilityLabel("In-App Voice Over")
                .accessibilityHint(ttsManager.isSpeaking ? "Tap to stop reading." : "Tap to read the current screen out loud.")
            }
        }
        .onDisappear {
            if ttsManager.isSpeaking {
                ttsManager.stopSpeaking()
            }
        }
    }
}

extension View {
    /// Adds a floating action button to the bottom trailing corner of the view that reads out the provided text when tapped.
    /// This button only appears if the user has enabled "In-App Voice Over" in the Accessibility Settings.
    func inAppVoiceOver(text: @escaping () -> String) -> some View {
        self.modifier(InAppVoiceOverModifier(textToRead: text))
    }
}
