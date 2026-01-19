import SwiftUI

struct BackupView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: NotesViewModel
    @State private var showingBackupSuccess = false
    @State private var showingRestoreAlert = false
    @State private var backupData: Data?
    @State private var showingFilePicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFAF8")
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Icon
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color(hex: "26A69A"))
                    
                    VStack(spacing: 12) {
                        Text("Backup & Restore")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "2C3E50"))
                        
                        Text("Protect your fishing notes")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "7F8C8D"))
                    }
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button(action: createBackup) {
                            HStack {
                                Image(systemName: "arrow.down.doc")
                                    .font(.system(size: 20))
                                
                                Text("Create Backup")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "26A69A"), Color(hex: "00695C")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: Color(hex: "26A69A").opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: { showingRestoreAlert = true }) {
                            HStack {
                                Image(systemName: "arrow.up.doc")
                                    .font(.system(size: 20))
                                
                                Text("Restore Backup")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "1E88E5"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color(hex: "1E88E5"), lineWidth: 2)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 40)
                    
                    // Info
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(Color(hex: "7F8C8D"))
                            
                            Text("Local backup - your data stays on device")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "7F8C8D"))
                        }
                        
                        Text("\(viewModel.notes.count) notes will be backed up")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "7F8C8D"))
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color(hex: "1E88E5"))
                }
            }
        }
        .alert(isPresented: $showingBackupSuccess) {
            Alert(
                title: Text("Backup Created"),
                message: Text("Your notes have been backed up successfully."),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showingRestoreAlert) {
            Alert(
                title: Text("Restore Backup"),
                message: Text("This will replace all current notes with backed up data. Continue?"),
                primaryButton: .destructive(Text("Restore")) {
                    restoreBackup()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func createBackup() {
        // Create backup JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(viewModel.notes) {
            let fileName = "fishing_notes_backup_\(Date().timeIntervalSince1970).json"
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            try? data.write(to: fileURL)
            backupData = data
            
            // Save to UserDefaults as well
            UserDefaults.standard.set(data, forKey: "notesBackup")
            UserDefaults.standard.set(Date(), forKey: "lastBackupDate")
            
            showingBackupSuccess = true
        }
    }
    
    private func restoreBackup() {
        if let data = UserDefaults.standard.data(forKey: "notesBackup") {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            if let notes = try? decoder.decode([FishingNote].self, from: data) {
                // Delete existing notes
                for note in viewModel.notes {
                    viewModel.deleteNote(note)
                }
                
                // Restore backed up notes
                for note in notes {
                    viewModel.saveNote(note)
                }
            }
        }
    }
}
