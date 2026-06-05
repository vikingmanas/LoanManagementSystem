import Foundation
import AVFoundation
import SwiftUI

class VoiceOverManager {
    static let shared = VoiceOverManager()
    private let synthesizer = AVSpeechSynthesizer()
    
    var isEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "enableVoiceOver")
    }
    
    func speak(_ text: String) {
        guard isEnabled else { return }
        
        // Stop current speech if any
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Standard rate
        
        synthesizer.speak(utterance)
    }
}
