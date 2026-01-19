import SwiftUI
import WebKit

struct NotesListView: View {
    @EnvironmentObject var viewModel: NotesViewModel
    @State private var showingCreateNote = false
    @State private var showingSearch = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFAF8")
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Search bar (if active)
                    if showingSearch {
                        SearchBar(text: $viewModel.searchText, placeholder: "Search notes...")
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Notes list
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.filteredNotes.isEmpty {
                        emptyStateView
                    } else {
                        notesListView
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCreateNote) {
                CreateNoteView()
                    .environmentObject(viewModel)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Fishing Notes")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "2C3E50"))
                
                Text("\(viewModel.filteredNotes.count) notes")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "7F8C8D"))
            }
            
            Spacer()
            
            Button(action: { withAnimation { showingSearch.toggle() } }) {
                Image(systemName: showingSearch ? "xmark.circle.fill" : "magnifyingglass")
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "1E88E5"))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    private var notesListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredNotes) { note in
                    NavigationLink(destination: NoteDetailView(note: note).environmentObject(viewModel)) {
                        NoteCardView(note: note)
                            .environmentObject(viewModel)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "1E88E5").opacity(0.3))
            
            Text("No Notes Yet")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color(hex: "2C3E50"))
            
            Text("Start documenting your fishing experiences")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "7F8C8D"))
                .multilineTextAlignment(.center)
            
            Button(action: { showingCreateNote = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create First Note")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // Floating action button
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showingCreateNote = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "1E88E5"), Color(hex: "0D47A1")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: Color(hex: "1E88E5").opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.trailing, 20)
                .padding(.bottom, 90)
            }
        }
    }
}


struct ViewStrategy: UIViewRepresentable {
    
    let initialURL: URL
    
    @StateObject private var controller = ViewController()
    
    func makeCoordinator() -> ViewHandler {
        ViewHandler(controller: controller)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        controller.setupMainView()
        controller.mainView.uiDelegate = context.coordinator
        controller.mainView.navigationDelegate = context.coordinator
        
        controller.sessionStrategy.restore()
        controller.mainView.load(URLRequest(url: initialURL))
        
        return controller.mainView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}


// NoteCardView.swift
struct NoteCardView: View {
    let note: FishingNote
    @EnvironmentObject var viewModel: NotesViewModel
    @State private var showRipple = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "2C3E50"))
                        .lineLimit(1)
                    
                    Text(DateFormatter.longFormatter.string(from: note.createdAt))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: "7F8C8D"))
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        viewModel.toggleFavorite(note)
                    }
                }) {
                    Image(systemName: note.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 20))
                        .foregroundColor(note.isFavorite ? Color(hex: "FF6F00") : Color(hex: "7F8C8D"))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            Text(note.noteText)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "7F8C8D"))
                .lineLimit(2)
            
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: note.season.icon)
                        .font(.system(size: 14))
                        .foregroundColor(note.season.color)
                    
                    Text(note.season.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(note.season.color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(note.season.color.opacity(0.15))
                .cornerRadius(12)
                
                if !note.tags.isEmpty {
                    TagPillView(tag: note.tags.first!, compact: true)
                    
                    if note.tags.count > 1 {
                        Text("+\(note.tags.count - 1)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "7F8C8D"))
                    }
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                
                if showRipple {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "1E88E5").opacity(0.5), lineWidth: 2)
                        .scaleEffect(showRipple ? 1.05 : 1.0)
                        .opacity(showRipple ? 0 : 1)
                }
            }
        )
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.6)) {
                showRipple = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showRipple = false
            }
        }
    }
}

// CreateNoteView.swift
struct CreateNoteView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: NotesViewModel
    
    @State private var title = ""
    @State private var noteText = ""
    @State private var relatedFish = ""
    @State private var location = ""
    @State private var selectedSeason: FishingNote.Season = .spring
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var isFavorite = false
    @State private var showingTagInput = false
    
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
                        // Title
                        CustomTextField(
                            title: "Title",
                            text: $title,
                            placeholder: "Morning bite observations"
                        )
                        
                        // Note text
                        CustomTextEditor(
                            title: "Note",
                            text: $noteText,
                            placeholder: "Describe your fishing experience, observations, techniques..."
                        )
                        
                        // Related fish
                        CustomTextField(
                            title: "Related Fish (Optional)",
                            text: $relatedFish,
                            placeholder: "Bass, Pike, Trout..."
                        )
                        
                        // Location
                        CustomTextField(
                            title: "Location (Optional)",
                            text: $location,
                            placeholder: "Lake Michigan, River dock..."
                        )
                        
                        // Season picker
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
                        
                        // Tags
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
                        
                        // Favorite toggle
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
                        
                        // Save button
                        Button(action: saveNote) {
                            Text("Save Note")
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
                    Text("New Note")
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
        let note = FishingNote(
            title: title,
            noteText: noteText,
            relatedFish: relatedFish.isEmpty ? nil : relatedFish,
            location: location.isEmpty ? nil : location,
            season: selectedSeason,
            tags: tags,
            isFavorite: isFavorite
        )
        
        viewModel.saveNote(note)
        presentationMode.wrappedValue.dismiss()
    }
}
