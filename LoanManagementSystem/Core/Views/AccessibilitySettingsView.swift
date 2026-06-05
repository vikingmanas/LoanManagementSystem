import SwiftUI

struct AccessibilitySettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("forceHighContrast") private var forceHighContrast = false
    @AppStorage("forceBoldText") private var forceBoldText = false
    @AppStorage("reduceMotion") private var reduceMotion = false
    @AppStorage("enableHaptics") private var enableHaptics = true
    @AppStorage("enableVoiceOver") private var enableVoiceOver = false
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $isDarkMode) {
                    Label("Dark Mode", systemImage: isDarkMode ? "moon.fill" : "sun.max.fill")
                }
                
                Toggle(isOn: $forceHighContrast) {
                    Label("High Contrast", systemImage: "circle.lefthalf.filled")
                }
                
                Toggle(isOn: $forceBoldText) {
                    Label("Bold Text", systemImage: "bold")
                }
            } header: {
                Text("Display")
            }
            
            Section {
                Toggle(isOn: $enableVoiceOver) {
                    Label("VoiceOver", systemImage: "waveform")
                }
                
                Toggle(isOn: $reduceMotion) {
                    Label("Reduce Motion", systemImage: "hare.fill")
                }
                
                Toggle(isOn: $enableHaptics) {
                    Label("Haptic Feedback", systemImage: "hand.tap.fill")
                }
            } header: {
                Text("Motion & Feedback")
            }
        }
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

#Preview {
    NavigationStack {
        AccessibilitySettingsView()
    }
}
