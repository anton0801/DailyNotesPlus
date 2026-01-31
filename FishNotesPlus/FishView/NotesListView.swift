import SwiftUI
import WebKit

struct NotesListView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    @EnvironmentObject var gearViewModel: GearViewModel
    @State private var showingCreateNote = false
    @State private var showingSearch = false
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Search bar (if active)
                    if showingSearch {
                        DarkSearchBar(text: $notesViewModel.searchText, placeholder: "Search notes...")
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Filter chips
                    if showingFilters {
                        filterSection
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Notes list
                    if notesViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryAccent))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if notesViewModel.filteredNotes.isEmpty {
                        emptyStateView
                    } else {
                        notesListView
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCreateNote) {
                CreateNoteView()
                    .environmentObject(notesViewModel)
                    .environmentObject(gearViewModel)
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("\(notesViewModel.filteredNotes.count) notes")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Search button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingSearch.toggle()
                    if !showingSearch {
                        notesViewModel.searchText = ""
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(showingSearch ? AppTheme.primaryAccent.opacity(0.2) : AppTheme.surface)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: showingSearch ? "xmark.circle.fill" : "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(showingSearch ? AppTheme.primaryAccent : AppTheme.textSecondary)
                }
                .shadow(color: showingSearch ? AppTheme.primaryAccent.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 0)
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Filter button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingFilters.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(showingFilters ? AppTheme.primaryAccent.opacity(0.2) : AppTheme.surface)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 20))
                        .foregroundColor(showingFilters ? AppTheme.primaryAccent : AppTheme.textSecondary)
                }
                .shadow(color: showingFilters ? AppTheme.primaryAccent.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 0)
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Add button
            Button(action: { showingCreateNote = true }) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryAccent.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .blur(radius: 8)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primaryAccent, AppTheme.primaryAccent.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.background)
                }
                .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(spacing: 12) {
            // Season filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All Seasons",
                        isSelected: notesViewModel.selectedSeason == nil,
                        color: AppTheme.textSecondary
                    ) {
                        notesViewModel.selectedSeason = nil
                    }
                    
                    ForEach(FishingNote.Season.allCases, id: \.self) { season in
                        FilterChip(
                            title: season.rawValue,
                            icon: season.icon,
                            isSelected: notesViewModel.selectedSeason == season,
                            color: season.color
                        ) {
                            notesViewModel.selectedSeason = notesViewModel.selectedSeason == season ? nil : season
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Favorites filter
            HStack(spacing: 8) {
                Toggle("Favorites Only", isOn: $notesViewModel.showFavoritesOnly)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .toggleStyle(SwitchToggleStyle(tint: AppTheme.secondaryAccent))
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Notes List
    private var notesListView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(notesViewModel.filteredNotes) { note in
                    NavigationLink(destination: NoteDetailView(note: note)
                        .environmentObject(notesViewModel)
                        .environmentObject(gearViewModel)
                    ) {
                        EnhancedNoteCardView(note: note)
                            .environmentObject(notesViewModel)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryAccent.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "note.text")
                    .font(.system(size: 50))
                    .foregroundColor(AppTheme.primaryAccent.opacity(0.5))
            }
            
            VStack(spacing: 12) {
                Text("No Notes Yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Start documenting your fishing experiences")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingCreateNote = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create First Note")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.background)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(AppTheme.primaryGradient)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 12, x: 0, y: 6)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}

// MARK: - Enhanced Note Card with Photos
struct EnhancedNoteCardView: View {
    let note: FishingNote
    @EnvironmentObject var viewModel: NotesViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Photo section (if has photos)
            if !note.photos.isEmpty {
                photoSection
            }
            
            // Content section
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1)
                        
                        Text(DateFormatter.longFormatter.string(from: note.createdAt))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            viewModel.toggleFavorite(note)
                        }
                    }) {
                        Image(systemName: note.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 20))
                            .foregroundColor(note.isFavorite ? AppTheme.secondaryAccent : AppTheme.textSecondary)
                            .shadow(color: note.isFavorite ? AppTheme.secondaryAccent.opacity(0.5) : Color.clear, radius: 8, x: 0, y: 0)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                // Note preview
                Text(note.noteText)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
                
                // Metadata badges
                metadataBadges
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(note.season.color.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Photo Section
    private var photoSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(note.photos) { photo in
                    if let imageData = Data(base64Encoded: photo.imageData),
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Metadata Badges
    private var metadataBadges: some View {
        HStack(spacing: 8) {
            // Season badge
            HStack(spacing: 4) {
                Image(systemName: note.season.icon)
                    .font(.system(size: 12))
                Text(note.season.rawValue)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(note.season.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(note.season.color.opacity(0.2))
            )
            
            // Photo count badge
            if !note.photos.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.system(size: 12))
                    Text("\(note.photos.count)")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(AppTheme.primaryAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppTheme.primaryAccent.opacity(0.2))
                )
            }
            
            // Gear badge
            if !note.gearUsed.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "figure.fishing")
                        .font(.system(size: 12))
                    Text("\(note.gearUsed.count)")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(AppTheme.secondaryAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppTheme.secondaryAccent.opacity(0.2))
                )
            }
            
            // Tags badge
            if !note.tags.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 10))
                    Text(note.tags.first!)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                    
                    if note.tags.count > 1 {
                        Text("+\(note.tags.count - 1)")
                            .font(.system(size: 10, weight: .semibold))
                    }
                }
                .foregroundColor(AppTheme.success)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppTheme.success.opacity(0.2))
                )
            }
            
            Spacer()
        }
    }
}

// MARK: - Dark Search Bar
struct DarkSearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundColor(AppTheme.textSecondary)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.textPrimary)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.primaryAccent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Create Note View (Enhanced)
struct CreateNoteView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var notesViewModel: NotesViewModel
    @EnvironmentObject var gearViewModel: GearViewModel
    
    @State private var title = ""
    @State private var noteText = ""
    @State private var relatedFish = ""
    @State private var location = ""
    @State private var selectedSeason: FishingNote.Season = .spring
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var isFavorite = false
    @State private var showingTagInput = false
    
    // NEW: Photos
    @State private var photos: [NotePhoto] = []
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    // NEW: Gear
    @State private var selectedGear: Set<String> = []
    @State private var showingGearPicker = false
    
    var isValid: Bool {
        !title.isEmpty && !noteText.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Photos section
                        photosSection
                        
                        // Title
                        DarkTextField(
                            title: "Title",
                            text: $title,
                            placeholder: "Morning bite observations"
                        )
                        
                        // Note text
                        DarkTextEditor(
                            title: "Note",
                            text: $noteText,
                            placeholder: "Describe your fishing experience, observations, techniques..."
                        )
                        
                        // Related fish
                        DarkTextField(
                            title: "Related Fish (Optional)",
                            text: $relatedFish,
                            placeholder: "Bass, Pike, Trout..."
                        )
                        
                        // Location
                        DarkTextField(
                            title: "Location (Optional)",
                            text: $location,
                            placeholder: "Lake Michigan, River dock..."
                        )
                        
                        // Season picker
                        seasonPickerSection
                        
                        // Gear section
                        gearSection
                        
                        // Tags section
                        tagsSection
                        
                        // Favorite toggle
                        Toggle(isOn: $isFavorite) {
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(AppTheme.secondaryAccent)
                                Text("Add to Favorites")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: AppTheme.secondaryAccent))
                        .padding(.horizontal, 20)
                        
                        // Save button
                        Button(action: saveNote) {
                            Text("Save Note")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppTheme.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(isValid ? AppTheme.primaryGradient : LinearGradient(colors: [AppTheme.textDisabled, AppTheme.textDisabled], startPoint: .leading, endPoint: .trailing))
                                        .shadow(color: isValid ? AppTheme.primaryAccent.opacity(0.5) : Color.clear, radius: 12, x: 0, y: 6)
                                )
                        }
                        .disabled(!isValid)
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
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
                    .foregroundColor(AppTheme.textSecondary)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("New Note")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .sheet(isPresented: $showingGearPicker) {
            GearPickerView(selectedGear: $selectedGear)
                .environmentObject(gearViewModel)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage, photos.count < 3 {
                addPhoto(image)
                selectedImage = nil
            }
        }
    }
    
    // MARK: - Photos Section
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photos (Max 3)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Text("\(photos.count)/3")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Add photo button
                    if photos.count < 3 {
                        Button(action: { showingImagePicker = true }) {
                            ZStack {
                                if #available(iOS 17.0, *) {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(AppTheme.surface)
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(AppTheme.primaryAccent.opacity(0.3), lineWidth: 2)
                                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(AppTheme.surface)
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(AppTheme.primaryAccent.opacity(0.3), lineWidth: 2)
                                        )
                                }
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(AppTheme.primaryAccent.opacity(0.6))
                                    
                                    Text("Add Photo")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    // Photo previews
                    ForEach(photos) { photo in
                        if let imageData = Data(base64Encoded: photo.imageData),
                           let uiImage = UIImage(data: imageData) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(AppTheme.primaryAccent.opacity(0.3), lineWidth: 1)
                                    )
                                
                                // Delete button
                                Button(action: {
                                    withAnimation {
                                        photos.removeAll { $0.id == photo.id }
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.danger)
                                            .frame(width: 28, height: 28)
                                        
                                        Image(systemName: "xmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .shadow(color: AppTheme.danger.opacity(0.5), radius: 4, x: 0, y: 2)
                                }
                                .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var seasonPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Season")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
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
    }
    
    // MARK: - Gear Section
    private var gearSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Gear Used")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Button(action: { showingGearPicker = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("Add Gear")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.secondaryAccent)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            if selectedGear.isEmpty {
                Text("No gear selected")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textDisabled)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(selectedGear), id: \.self) { gearId in
                        if let gear = gearViewModel.gearItems.first(where: { $0.id == gearId }) {
                            SelectedGearRow(gear: gear) {
                                selectedGear.remove(gearId)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Tags Section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tags")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Button(action: { showingTagInput.toggle() }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.success)
                }
            }
            
            if showingTagInput {
                HStack {
                    TextField("New tag", text: $newTag)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppTheme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppTheme.success.opacity(0.2), lineWidth: 1)
                                )
                        )
                    
                    Button("Add") {
                        addTag()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.success)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            if !tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        DarkTagPill(tag: tag, removable: true) {
                            withAnimation {
                                tags.removeAll { $0 == tag }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func addPhoto(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else { return }
        let base64String = imageData.base64EncodedString()
        
        let photo = NotePhoto(imageData: base64String)
        withAnimation {
            photos.append(photo)
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
            isFavorite: isFavorite,
            photos: photos,
            gearUsed: Array(selectedGear)
        )
        
        notesViewModel.saveNote(note)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Season Button
struct SeasonButton: View {
    let season: FishingNote.Season
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: season.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? AppTheme.background : season.color)
                
                Text(season.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? AppTheme.background : AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? season.color : AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(season.color.opacity(0.5), lineWidth: isSelected ? 0 : 1)
                    )
            )
            .shadow(color: isSelected ? season.color.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Selected Gear Row
struct SelectedGearRow: View {
    let gear: GearItem
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: gear.type.icon)
                .font(.system(size: 16))
                .foregroundColor(gear.type.color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(gear.type.color.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(gear.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(gear.type.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.danger)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(gear.type.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Dark Tag Pill
struct DarkTagPill: View {
    let tag: String
    var removable: Bool = false
    var onRemove: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "tag.fill")
                .font(.system(size: 10))
            
            Text(tag)
                .font(.system(size: 13, weight: .medium))
            
            if removable, let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                }
            }
        }
        .foregroundColor(AppTheme.success)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(AppTheme.success.opacity(0.2))
        )
    }
}

// MARK: - Gear Picker View
struct GearPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: GearViewModel
    @Binding var selectedGear: Set<String>
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.gearItems) { gear in
                            GearPickerRow(
                                gear: gear,
                                isSelected: selectedGear.contains(gear.id)
                            ) {
                                if selectedGear.contains(gear.id) {
                                    selectedGear.remove(gear.id)
                                } else {
                                    selectedGear.insert(gear.id)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Select Gear")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.secondaryAccent)
                }
            }
        }
    }
}

struct GearPickerRow: View {
    let gear: GearItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(isSelected ? gear.type.color : AppTheme.textDisabled, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    if isSelected {
                        Circle()
                            .fill(gear.type.color)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.background)
                    }
                }
                
                Image(systemName: gear.type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(gear.type.color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(gear.type.color.opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(gear.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(gear.type.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? gear.type.color.opacity(0.1) : AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(gear.type.color.opacity(isSelected ? 0.5 : 0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
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

