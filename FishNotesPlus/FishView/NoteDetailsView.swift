import SwiftUI
import WebKit

struct NoteDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var notesViewModel: NotesViewModel
    @EnvironmentObject var gearViewModel: GearViewModel
    @State var note: FishingNote
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingFullGallery = false
    @State private var selectedPhotoIndex = 0
    
    var body: some View {
        ZStack {
            AppTheme.background
                .edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Photo gallery (if has photos)
                    if !note.photos.isEmpty {
                        photoGallerySection
                    }
                    
                    // Main info card
                    mainInfoCard
                    
                    // Metadata cards
                    metadataSection
                    
                    // Gear section (if has gear)
                    if !note.gearUsed.isEmpty {
                        gearSection
                    }
                    
                    // Tags section (if has tags)
                    if !note.tags.isEmpty {
                        tagsSection
                    }
                    
                    // Note content
                    noteContentSection
                    
                    // Action buttons
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.surface.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .blur(radius: 8)
                        
                        Circle()
                            .fill(AppTheme.surface)
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            notesViewModel.toggleFavorite(note)
                            note.isFavorite.toggle()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(note.isFavorite ? AppTheme.secondaryAccent.opacity(0.2) : AppTheme.surface)
                                .frame(width: 36, height: 36)
                                .blur(radius: note.isFavorite ? 8 : 0)
                            
                            Circle()
                                .fill(note.isFavorite ? AppTheme.secondaryAccent.opacity(0.2) : AppTheme.surface)
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: note.isFavorite ? "star.fill" : "star")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(note.isFavorite ? AppTheme.secondaryAccent : AppTheme.textPrimary)
                        }
                    }
                    
                    Button(action: { showingEditSheet = true }) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primaryAccent.opacity(0.2))
                                .frame(width: 36, height: 36)
                                .blur(radius: 8)
                            
                            Circle()
                                .fill(AppTheme.primaryAccent.opacity(0.2))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.primaryAccent)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditNoteView(note: note)
                .environmentObject(notesViewModel)
                .environmentObject(gearViewModel)
        }
        .fullScreenCover(isPresented: $showingFullGallery) {
            PhotoGalleryView(photos: note.photos, selectedIndex: $selectedPhotoIndex)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Note"),
                message: Text("Are you sure you want to delete this note? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    notesViewModel.deleteNote(note)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
        .onChange(of: notesViewModel.notes) { newNotes in
            if let updated = newNotes.first(where: { $0.id == note.id }) {
                note = updated
            }
        }
    }
    
    // MARK: - Photo Gallery Section
    private var photoGallerySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photos (\(note.photos.count))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Button(action: { showingFullGallery = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 12))
                        Text("View All")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.primaryAccent)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            TabView(selection: $selectedPhotoIndex) {
                ForEach(Array(note.photos.enumerated()), id: \.element.id) { index, photo in
                    if let imageData = Data(base64Encoded: photo.imageData),
                       let uiImage = UIImage(data: imageData) {
                        Button(action: { showingFullGallery = true }) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(AppTheme.primaryAccent.opacity(0.3), lineWidth: 2)
                                )
                                .shadow(color: AppTheme.primaryAccent.opacity(0.3), radius: 15, x: 0, y: 8)
                        }
                        .tag(index)
                    }
                }
            }
            .frame(height: 280)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            
            // Photo indicators
            HStack(spacing: 8) {
                ForEach(0..<note.photos.count, id: \.self) { index in
                    Circle()
                        .fill(selectedPhotoIndex == index ? AppTheme.primaryAccent : AppTheme.textDisabled)
                        .frame(width: selectedPhotoIndex == index ? 8 : 6, height: selectedPhotoIndex == index ? 8 : 6)
                        .shadow(color: selectedPhotoIndex == index ? AppTheme.primaryAccent.opacity(0.5) : Color.clear, radius: 4, x: 0, y: 2)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Main Info Card
    private var mainInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text(note.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            // Season & Date
            HStack(spacing: 12) {
                // Season badge
                HStack(spacing: 6) {
                    Image(systemName: note.season.icon)
                        .font(.system(size: 14))
                    Text(note.season.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(note.season.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(note.season.color.opacity(0.2))
                )
                
                Spacer()
                
                // Date
                Text(DateFormatter.longFormatter.string(from: note.createdAt))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(note.season.color.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Metadata Section
    private var metadataSection: some View {
        VStack(spacing: 12) {
            if let fish = note.relatedFish, !fish.isEmpty {
                MetadataCard(
                    icon: "fish.fill",
                    title: "Related Fish",
                    value: fish,
                    color: AppTheme.primaryAccent
                )
            }
            
            if let location = note.location, !location.isEmpty {
                MetadataCard(
                    icon: "mappin.and.ellipse",
                    title: "Location",
                    value: location,
                    color: Color(hex: "FF6B35")
                )
            }
        }
    }
    
    // MARK: - Gear Section
    private var gearSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.fishing")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.secondaryAccent)
                
                Text("Gear Used (\(note.gearUsed.count))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            VStack(spacing: 12) {
                ForEach(note.gearUsed, id: \.self) { gearId in
                    if let gear = gearViewModel.gearItems.first(where: { $0.id == gearId }) {
                        GearDetailRow(gear: gear)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.secondaryAccent.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Tags Section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "tag.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.success)
                
                Text("Tags")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(note.tags, id: \.self) { tag in
                    DarkTagPill(tag: tag, removable: false)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.success.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Note Content Section
    private var noteContentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.primaryAccent)
                
                Text("Note")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            Text(note.noteText)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(6)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.primaryAccent.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: { showingEditSheet = true }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primaryAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(AppTheme.primaryAccent.opacity(0.2))
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: { showingDeleteAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.danger)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(AppTheme.danger.opacity(0.2))
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
}

// MARK: - Metadata Card Component
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
                .background(
                    Circle()
                        .fill(color.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Gear Detail Row
struct GearDetailRow: View {
    let gear: GearItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Gear icon/image
            if let photoData = gear.photoData,
               let imageData = Data(base64Encoded: photoData),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(gear.type.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: gear.type.icon)
                        .font(.system(size: 22))
                        .foregroundColor(gear.type.color)
                }
            }
            
            // Gear info
            VStack(alignment: .leading, spacing: 4) {
                Text(gear.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                HStack(spacing: 8) {
                    Text(gear.type.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    // Rating stars
                    HStack(spacing: 2) {
                        ForEach(0..<Int(gear.effectivenessRating.rounded()), id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.secondaryAccent)
                        }
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textDisabled)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardHighlight)
        )
    }
}

// MARK: - Photo Gallery Full Screen View
struct PhotoGalleryView: View {
    @Environment(\.presentationMode) var presentationMode
    let photos: [NotePhoto]
    @Binding var selectedIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            AppTheme.background
                .edgesIgnoringSafeArea(.all)
            
            TabView(selection: $selectedIndex) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    if let imageData = Data(base64Encoded: photo.imageData),
                       let uiImage = UIImage(data: imageData) {
                        ZStack {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(scale)
                                .offset(offset)
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            scale = lastScale * value
                                        }
                                        .onEnded { _ in
                                            withAnimation(.spring()) {
                                                if scale < 1 {
                                                    scale = 1
                                                    offset = .zero
                                                } else if scale > 3 {
                                                    scale = 3
                                                }
                                                lastScale = scale
                                            }
                                        }
                                )
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            if scale > 1 {
                                                offset = CGSize(
                                                    width: lastOffset.width + value.translation.width,
                                                    height: lastOffset.height + value.translation.height
                                                )
                                            }
                                        }
                                        .onEnded { _ in
                                            lastOffset = offset
                                        }
                                )
                            
                            // Caption (if exists)
                            if let caption = photo.caption, !caption.isEmpty {
                                VStack {
                                    Spacer()
                                    
                                    Text(caption)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(AppTheme.surface.opacity(0.95))
                                                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                                        )
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 100)
                                }
                            }
                        }
                        .tag(index)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Header overlay
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.surface.opacity(0.9))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                    .padding(20)
                    
                    Spacer()
                    
                    // Photo counter
                    Text("\(selectedIndex + 1) / \(photos.count)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(AppTheme.surface.opacity(0.9))
                        )
                        .padding(20)
                }
                
                Spacer()
            }
        }
        .statusBar(hidden: true)
    }
}

// MARK: - Edit Note View (Enhanced)
struct EditNoteView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var notesViewModel: NotesViewModel
    @EnvironmentObject var gearViewModel: GearViewModel
    
    @State var note: FishingNote
    @State private var title: String
    @State private var noteText: String
    @State private var relatedFish: String
    @State private var location: String
    @State private var selectedSeason: FishingNote.Season
    @State private var tags: [String]
    @State private var isFavorite: Bool
    @State private var photos: [NotePhoto]
    @State private var selectedGear: Set<String>
    
    @State private var newTag = ""
    @State private var showingTagInput = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingGearPicker = false
    
    init(note: FishingNote) {
        _note = State(initialValue: note)
        _title = State(initialValue: note.title)
        _noteText = State(initialValue: note.noteText)
        _relatedFish = State(initialValue: note.relatedFish ?? "")
        _location = State(initialValue: note.location ?? "")
        _selectedSeason = State(initialValue: note.season)
        _tags = State(initialValue: note.tags)
        _isFavorite = State(initialValue: note.isFavorite)
        _photos = State(initialValue: note.photos)
        _selectedGear = State(initialValue: Set(note.gearUsed))
    }
    
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
                        
                        DarkTextField(title: "Title", text: $title, placeholder: "Morning bite observations")
                        DarkTextEditor(title: "Note", text: $noteText, placeholder: "Describe your fishing experience...")
                        DarkTextField(title: "Related Fish (Optional)", text: $relatedFish, placeholder: "Bass, Pike, Trout...")
                        DarkTextField(title: "Location (Optional)", text: $location, placeholder: "Lake Michigan, River dock...")
                        
                        seasonPickerSection
                        gearSection
                        tagsSection
                        
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
                        
                        Button(action: saveChanges) {
                            Text("Save Changes")
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
                    Text("Edit Note")
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
                    SeasonButton(season: season, isSelected: selectedSeason == season) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedSeason = season
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
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
    
    private func saveChanges() {
        var updatedNote = note
        updatedNote.title = title
        updatedNote.noteText = noteText
        updatedNote.relatedFish = relatedFish.isEmpty ? nil : relatedFish
        updatedNote.location = location.isEmpty ? nil : location
        updatedNote.season = selectedSeason
        updatedNote.tags = tags
        updatedNote.isFavorite = isFavorite
        updatedNote.photos = photos
        updatedNote.gearUsed = Array(selectedGear)
        updatedNote.updatedAt = Date()
        
        notesViewModel.saveNote(updatedNote)
        presentationMode.wrappedValue.dismiss()
    }
}

//struct FlowLayout: Layout {
//    var spacing: CGFloat = 8
//    
//    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
//        let result = FlowResult(
//            in: proposal.replacingUnspecifiedDimensions().width,
//            subviews: subviews,
//            spacing: spacing
//        )
//        return result.size
//    }
//    
//    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
//        let result = FlowResult(
//            in: bounds.width,
//            subviews: subviews,
//            spacing: spacing
//        )
//        for (index, subview) in subviews.enumerated() {
//            subview.place(
//                at: CGPoint(
//                    x: bounds.minX + result.positions[index].x,
//                    y: bounds.minY + result.positions[index].y
//                ),
//                proposal: .unspecified
//            )
//        }
//    }
//    
//    struct FlowResult {
//        var size: CGSize = .zero
//        var positions: [CGPoint] = []
//        
//        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
//            var x: CGFloat = 0
//            var y: CGFloat = 0
//            var lineHeight: CGFloat = 0
//            
//            for subview in subviews {
//                let size = subview.sizeThatFits(.unspecified)
//                
//                if x + size.width > maxWidth && x > 0 {
//                    x = 0
//                    y += lineHeight + spacing
//                    lineHeight = 0
//                }
//                
//                positions.append(CGPoint(x: x, y: y))
//                lineHeight = max(lineHeight, size.height)
//                x += size.width + spacing
//            }
//            
//            self.size = CGSize(width: maxWidth, height: y + lineHeight)
//        }
//    }
//}

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
