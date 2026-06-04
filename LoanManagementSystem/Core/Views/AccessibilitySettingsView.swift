import SwiftUI

struct AccessibilitySettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("forceHighContrast") private var forceHighContrast = false
    @AppStorage("forceBoldText") private var forceBoldText = false
    @AppStorage("reduceMotion") private var reduceMotion = false
    @AppStorage("enableHaptics") private var enableHaptics = true
    
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
            } footer: {
                Text("These settings override the system defaults specifically for this app.")
            }
            
            Section {
                Toggle(isOn: $reduceMotion) {
                    Label("Reduce Motion", systemImage: "hare.fill")
                }
                
                Toggle(isOn: $enableHaptics) {
                    Label("Haptic Feedback", systemImage: "hand.tap.fill")
                }
            } header: {
                Text("Motion & Feedback")
            } footer: {
                Text("Reduce motion disables most animations and transitions.")
            }
        }
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AccessibilitySettingsView()
    }
}
