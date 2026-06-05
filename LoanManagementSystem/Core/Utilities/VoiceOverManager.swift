import AVFoundation
import SwiftUI

class VoiceOverManager {
    static let shared = VoiceOverManager()
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    var enableVoiceOver: Bool {
        UserDefaults.standard.bool(forKey: "enableVoiceOver")
    }
    
    func speak(_ text: String) {
        guard enableVoiceOver else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        // Adjust the voice and language as needed
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
}
