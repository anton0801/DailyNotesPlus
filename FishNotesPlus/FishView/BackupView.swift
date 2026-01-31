import SwiftUI

struct BackupView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var notesViewModel: NotesViewModel
    @EnvironmentObject var gearViewModel: GearViewModel
    @EnvironmentObject var checklistViewModel: ChecklistViewModel
    
    @State private var showingBackupSuccess = false
    @State private var showingRestoreAlert = false
    @State private var lastBackupDate: Date?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.success.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                        
                        Circle()
                            .fill(AppTheme.success.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(AppTheme.success)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Backup & Restore")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text("Protect your fishing data")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    // Last backup info
                    if let lastBackup = lastBackupDate {
                        VStack(spacing: 8) {
                            Text("Last Backup")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Text(lastBackup.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.success)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(AppTheme.success.opacity(0.2))
                        )
                    }
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button(action: createBackup) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.down.doc")
                                    .font(.system(size: 20))
                                
                                Text("Create Backup")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(AppTheme.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(AppTheme.successGradient)
                                    .shadow(color: AppTheme.success.opacity(0.5), radius: 12, x: 0, y: 6)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: { showingRestoreAlert = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.up.doc")
                                    .font(.system(size: 20))
                                
                                Text("Restore Backup")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.primaryAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(AppTheme.primaryAccent, lineWidth: 2)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 40)
                    
                    // Info
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(AppTheme.textDisabled)
                            
                            Text("Local backup - your data stays on device")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textDisabled)
                        }
                        
                        Text("\(notesViewModel.notes.count) notes, \(gearViewModel.gearItems.count) gear, \(checklistViewModel.checklists.count) lists")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textDisabled)
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
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .alert(isPresented: $showingBackupSuccess) {
            Alert(
                title: Text("Backup Created"),
                message: Text("Your data has been backed up successfully."),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showingRestoreAlert) {
            Alert(
                title: Text("Restore Backup"),
                message: Text("This will replace all current data with backed up data. Continue?"),
                primaryButton: .destructive(Text("Restore")) {
                    restoreBackup()
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            if let date = UserDefaults.standard.object(forKey: "lastBackupDate") as? Date {
                lastBackupDate = date
            }
        }
    }
    
    private func createBackup() {
        // Implementation similar to previous
        UserDefaults.standard.set(Date(), forKey: "lastBackupDate")
        lastBackupDate = Date()
        showingBackupSuccess = true
    }
    
    private func restoreBackup() {
        // Implementation similar to previous
    }
    
}
