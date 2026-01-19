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
                Color(hex: "FAFAF8")
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Icon
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "1E88E5"))
                    
                    VStack(spacing: 12) {
                        Text("Export Notes")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "2C3E50"))
                        
                        Text("Choose export format")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "7F8C8D"))
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
                        Text("Export \(viewModel.filteredNotes.count) Notes")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "1E88E5"), Color(hex: "0D47A1")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: Color(hex: "1E88E5").opacity(0.4), radius: 10, x: 0, y: 5)
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
                    .foregroundColor(Color(hex: "1E88E5"))
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
            HStack {
                Image(systemName: format == .txt ? "doc.text" : "tablecells")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : Color(hex: "1E88E5"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(format == .txt ? "Text File" : "CSV File")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Color(hex: "2C3E50"))
                    
                    Text(".\(format.fileExtension)")
                        .font(.system(size: 14))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color(hex: "7F8C8D"))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ?
                          LinearGradient(
                            colors: [Color(hex: "1E88E5"), Color(hex: "0D47A1")],
                            startPoint: .leading,
                            endPoint: .trailing
                          ) :
                          LinearGradient(
                            colors: [Color.white, Color.white],
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                    )
                    .shadow(color: Color.black.opacity(isSelected ? 0.15 : 0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
