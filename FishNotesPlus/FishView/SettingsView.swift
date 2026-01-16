import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var notesManager: NotesManager
    @State private var textSize: Double = 16
    @State private var theme: String = "Light"
    @State private var showingExport = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Appearance").font(.subheadline)) {
                        Picker("Theme", selection: $theme) {
                            Text("Light").tag("Light")
                            Text("Soft").tag("Soft")
                        }
                        .pickerStyle(.menu)
                        
                        HStack {
                            Text("Text Size")
                            Slider(value: $textSize, in: 12...24, step: 1)
                        }
                    }
                    
                    Section(header: Text("Data Management").font(.subheadline)) {
                        
                        Button("Reset All Data") {
                            showingResetAlert = true
                        }
                        .foregroundColor(.red)
                    }
                    
                    Section(header: Text("Information").font(.subheadline)) {
                        NavigationLink("Privacy Policy") {
                            Text("Your data is stored locally on your device and never shared without your explicit action. No cloud sync or accounts are used.")
                                .padding()
                        }
                        
                        NavigationLink("About") {
                            Text("Fish Notes Plus - Your personal fishing notebook.\nVersion 1.0\nBuilt with love for anglers.")
                                .padding()
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .alert("Reset All Data", isPresented: $showingResetAlert) {
                Button("Reset", role: .destructive) {
                    notesManager.notes = []
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will delete all your notes permanently. Are you sure?")
            }
        }
    }
}

#Preview {
    SettingsView()
}
