import SwiftUI

struct ExportView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: NotesViewModel
    @State private var selectedFormat: ExportFormat = .txt
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    
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
                            .fill(AppTheme.primaryAccent.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                        
                        Circle()
                            .fill(AppTheme.primaryAccent.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.primaryAccent)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Export Notes")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text("Choose export format")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    // Format selection
                    VStack(spacing: 12) {
                        FormatButton(
                            format: .txt,
                            isSelected: selectedFormat == .txt
                        ) {
                            selectedFormat = .txt
                        }
                        
                        FormatButton(
                            format: .csv,
                            isSelected: selectedFormat == .csv
                        ) {
                            selectedFormat = .csv
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Export button
                    Button(action: exportNotes) {
                        Text("Export \(viewModel.notes.count) Notes")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(AppTheme.primaryGradient)
                                    .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 12, x: 0, y: 6)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 40)
                    
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
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private func exportNotes() {
        if let url = viewModel.exportNotes(format: selectedFormat) {
            exportURL = url
            showingShareSheet = true
        }
    }
}

struct FormatButton: View {
    let format: ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: format == .txt ? "doc.text" : "tablecells")
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? AppTheme.background : AppTheme.primaryAccent)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(format == .txt ? "Text File" : "CSV File")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isSelected ? AppTheme.background : AppTheme.textPrimary)
                    
                    Text(".\(format.fileExtension)")
                        .font(.system(size: 14))
                        .foregroundColor(isSelected ? AppTheme.background.opacity(0.8) : AppTheme.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.background)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppTheme.primaryAccent : AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.primaryAccent.opacity(0.5), lineWidth: isSelected ? 0 : 2)
                    )
                    .shadow(color: isSelected ? AppTheme.primaryAccent.opacity(0.4) : Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
