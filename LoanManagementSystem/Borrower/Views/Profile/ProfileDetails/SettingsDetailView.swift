import SwiftUI

struct SettingsDetailView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedLanguage") private var selectedLanguage = "English"
    let languages = ["English", "Hindi", "Marathi", "Gujarati"]
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $isDarkMode) {
                    Label("Dark Mode", systemImage: isDarkMode ? "moon.fill" : "sun.max.fill")
                }
            } header: {
                Text("Appearance")
            }
            
            Section {
                Picker(selection: $selectedLanguage) {
                    ForEach(languages, id: \.self) { lang in
                        Text(lang)
                    }
                } label: {
                    Label("Language", systemImage: "globe")
                }
            } header: {
                Text("Localization")
            }
            
            Section {
                LabeledContent("Version", value: "1.0.0 (Build 42)")
            } header: {
                Text("Information")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
