import SwiftUI

struct SettingsDetailView: View {
    @State private var isDarkMode = false
    @State private var selectedLanguage = "English"
    let languages = ["English", "Hindi", "Marathi", "Gujarati"]
    
    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Toggle(isOn: $isDarkMode) {
                    HStack {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundStyle(isDarkMode ? .indigo : .orange)
                        Text("Dark Mode")
                    }
                }
            }
            
            Section(header: Text("Localization")) {
                Picker(selection: $selectedLanguage, label: HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(.blue)
                    Text("Language")
                }) {
                    ForEach(languages, id: \.self) { lang in
                        Text(lang)
                    }
                }
            }
            
            Section(header: Text("App Version")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0 (Build 42)")
                        .foregroundStyle(Color.AppTheme.textSecondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsDetailView()
    }
}
