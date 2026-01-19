import SwiftUI
import WebKit

struct NoteDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: NotesViewModel
    @State var note: FishingNote
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color(hex: "FAFAF8")
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with title
                    VStack(alignment: .leading, spacing: 12) {
                        Text(note.title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(hex: "2C3E50"))
                        
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "7F8C8D"))
                            
                            Text(DateFormatter.longFormatter.string(from: note.createdAt))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "7F8C8D"))
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    viewModel.toggleFavorite(note)
                                    note.isFavorite.toggle()
                                }
                            }) {
                                Image(systemName: note.isFavorite ? "star.fill" : "star")
                                    .font(.system(size: 24))
                                    .foregroundColor(note.isFavorite ? Color(hex: "FF6F00") : Color(hex: "7F8C8D"))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Metadata cards
                    VStack(spacing: 12) {
                        // Season
                        MetadataCard(
                            icon: note.season.icon,
                            title: "Season",
                            value: note.season.rawValue,
                            color: note.season.color
                        )
                        
                        // Fish (if available)
                        if let fish = note.relatedFish, !fish.isEmpty {
                            MetadataCard(
                                icon: "fish.fill",
                                title: "Related Fish",
                                value: fish,
                                color: Color(hex: "26A69A")
                            )
                        }
                        
                        // Location (if available)
                        if let location = note.location, !location.isEmpty {
                            MetadataCard(
                                icon: "location.fill",
                                title: "Location",
                                value: location,
                                color: Color(hex: "1E88E5")
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Tags
                    if !note.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tags")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "2C3E50"))
                            
                            FlowLayout(spacing: 8) {
                                ForEach(note.tags, id: \.self) { tag in
                                    TagPillView(tag: tag, removable: false)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Note content
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Note")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "2C3E50"))
                        
                        Text(note.noteText)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color(hex: "2C3E50"))
                            .lineSpacing(6)
                    }
                    .padding(.horizontal, 20)
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: { showingEditSheet = true }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "1E88E5"), Color(hex: "0D47A1")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: { showingDeleteAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "FF5252"), Color(hex: "D32F2F")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            EditNoteView(note: note)
                .environmentObject(viewModel)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Note"),
                message: Text("Are you sure you want to delete this note? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.deleteNote(note)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct MetadataCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "7F8C8D"))
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "2C3E50"))
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}


struct NotesDisplayView: View {
    
    @State private var currentDestination: String? = ""
    
    var body: some View {
        ZStack {
            if let destination = currentDestination,
               let url = URL(string: destination) {
                ViewStrategy(initialURL: url)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            setup()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in
            update()
        }
    }
    
    private func setup() {
        let temporary = UserDefaults.standard.string(forKey: "temp_url")
        let persistent = UserDefaults.standard.string(forKey: "cached_endpoint") ?? ""
        
        currentDestination = temporary ?? persistent
        
        if temporary != nil {
            UserDefaults.standard.removeObject(forKey: "temp_url")
        }
    }
    
    private func update() {
        if let temporary = UserDefaults.standard.string(forKey: "temp_url"),
           !temporary.isEmpty {
            currentDestination = nil
            currentDestination = temporary
            UserDefaults.standard.removeObject(forKey: "temp_url")
        }
    }
}

// EditNoteView.swift
struct EditNoteView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: NotesViewModel
    
    @State var note: FishingNote
    @State private var title: String
    @State private var noteText: String
    @State private var relatedFish: String
    @State private var location: String
    @State private var selectedSeason: FishingNote.Season
    @State private var tags: [String]
    @State private var isFavorite: Bool
    @State private var newTag = ""
    @State private var showingTagInput = false
    
    init(note: FishingNote) {
        _note = State(initialValue: note)
        _title = State(initialValue: note.title)
        _noteText = State(initialValue: note.noteText)
        _relatedFish = State(initialValue: note.relatedFish ?? "")
        _location = State(initialValue: note.location ?? "")
        _selectedSeason = State(initialValue: note.season)
        _tags = State(initialValue: note.tags)
        _isFavorite = State(initialValue: note.isFavorite)
    }
    
    var isValid: Bool {
        !title.isEmpty && !noteText.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFAF8")
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        CustomTextField(
                            title: "Title",
                            text: $title,
                            placeholder: "Morning bite observations"
                        )
                        
                        CustomTextEditor(
                            title: "Note",
                            text: $noteText,
                            placeholder: "Describe your fishing experience..."
                        )
                        
                        CustomTextField(
                            title: "Related Fish (Optional)",
                            text: $relatedFish,
                            placeholder: "Bass, Pike, Trout..."
                        )
                        
                        CustomTextField(
                            title: "Location (Optional)",
                            text: $location,
                            placeholder: "Lake Michigan, River dock..."
                        )
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Season")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "2C3E50"))
                            
                            HStack(spacing: 12) {
                                ForEach(FishingNote.Season.allCases, id: \.self) { season in
                                    SeasonButton(
                                        season: season,
                                        isSelected: selectedSeason == season
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedSeason = season
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Tags")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(hex: "2C3E50"))
                                
                                Spacer()
                                
                                Button(action: { showingTagInput.toggle() }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(hex: "1E88E5"))
                                }
                            }
                            
                            if showingTagInput {
                                HStack {
                                    TextField("New tag", text: $newTag)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    Button("Add") {
                                        addTag()
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "1E88E5"))
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            if !tags.isEmpty {
                                FlowLayout(spacing: 8) {
                                    ForEach(tags, id: \.self) { tag in
                                        TagPillView(tag: tag, removable: true) {
                                            withAnimation {
                                                tags.removeAll { $0 == tag }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Toggle(isOn: $isFavorite) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(Color(hex: "FF6F00"))
                                Text("Add to Favorites")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "2C3E50"))
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "FF6F00")))
                        .padding(.horizontal, 20)
                        
                        Button(action: saveNote) {
                            Text("Save Changes")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: isValid ? [Color(hex: "1E88E5"), Color(hex: "0D47A1")] : [Color.gray, Color.gray],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(28)
                                .shadow(color: isValid ? Color(hex: "1E88E5").opacity(0.4) : Color.clear, radius: 10, x: 0, y: 5)
                        }
                        .disabled(!isValid)
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    .padding(.vertical, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color(hex: "7F8C8D"))
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Edit Note")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "2C3E50"))
                }
            }
        }
    }
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            withAnimation {
                tags.append(trimmed)
                newTag = ""
                showingTagInput = false
            }
        }
    }
    
    private func saveNote() {
        var updatedNote = note
        updatedNote.title = title
        updatedNote.noteText = noteText
        updatedNote.relatedFish = relatedFish.isEmpty ? nil : relatedFish
        updatedNote.location = location.isEmpty ? nil : location
        updatedNote.season = selectedSeason
        updatedNote.tags = tags
        updatedNote.isFavorite = isFavorite
        updatedNote.updatedAt = Date()
        
        viewModel.saveNote(updatedNote)
        presentationMode.wrappedValue.dismiss()
    }
}
