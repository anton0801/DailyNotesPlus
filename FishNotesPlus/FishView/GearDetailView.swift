import SwiftUI

struct GearDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: GearViewModel
    @State var gear: GearItem
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingFullImage = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Photo section
                        if let photoData = gear.photoData,
                           let imageData = Data(base64Encoded: photoData),
                           let uiImage = UIImage(data: imageData) {
                            photoSection(image: uiImage)
                        } else {
                            placeholderPhotoSection
                        }
                        
                        // Main info card
                        mainInfoCard
                        
                        // Stats card
                        statsCard
                        
                        // Rating section
                        ratingSection
                        
                        // Notes section
                        if let notes = gear.notes, !notes.isEmpty {
                            notesSection(notes: notes)
                        }
                        
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
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
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
            EditGearView(gear: gear)
                .environmentObject(viewModel)
        }
        .fullScreenCover(isPresented: $showingFullImage) {
            if let photoData = gear.photoData,
               let imageData = Data(base64Encoded: photoData),
               let uiImage = UIImage(data: imageData) {
                FullImageView(image: uiImage)
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Gear"),
                message: Text("Are you sure you want to delete this gear item?"),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.deleteGearItem(gear)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Photo Section
    private func photoSection(image: UIImage) -> some View {
        Button(action: { showingFullImage = true }) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(gear.type.color.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: gear.type.color.opacity(0.4), radius: 20, x: 0, y: 10)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var placeholderPhotoSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(gear.type.color.opacity(0.2))
                .frame(height: 300)
            
            VStack(spacing: 16) {
                Image(systemName: gear.type.icon)
                    .font(.system(size: 80))
                    .foregroundColor(gear.type.color.opacity(0.6))
                
                Text(gear.type.rawValue)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(gear.type.color)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(gear.type.color.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Main Info Card
    private var mainInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Name
            Text(gear.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            // Type badge
            HStack(spacing: 8) {
                Image(systemName: gear.type.icon)
                    .font(.system(size: 14))
                Text(gear.type.rawValue)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(gear.type.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(gear.type.color.opacity(0.2))
            )
            
            Divider()
                .background(AppTheme.cardHighlight)
            
            // Brand & Model
            if let brand = gear.brand, !brand.isEmpty {
                InfoRow(
                    icon: "tag.fill",
                    title: "Brand",
                    value: brand,
                    color: AppTheme.primaryAccent
                )
            }
            
            if let model = gear.model, !model.isEmpty {
                InfoRow(
                    icon: "cube.fill",
                    title: "Model",
                    value: model,
                    color: AppTheme.secondaryAccent
                )
            }
            
            // Created date
            InfoRow(
                icon: "calendar",
                title: "Added",
                value: gear.createdAt.formatted(date: .abbreviated, time: .omitted),
                color: AppTheme.success
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(gear.type.color.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Stats Card
    private var statsCard: some View {
        HStack(spacing: 16) {
            StatBox(
                icon: "arrow.triangle.2.circlepath",
                title: "Times Used",
                value: "\(gear.usageCount)",
                color: AppTheme.primaryAccent
            )
            
            StatBox(
                icon: "chart.line.uptrend.xyaxis",
                title: "Rating",
                value: String(format: "%.1f", gear.effectivenessRating),
                color: AppTheme.secondaryAccent
            )
        }
    }
    
    // MARK: - Rating Section
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Effectiveness Rating")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Text(String(format: "%.1f / 5.0", gear.effectivenessRating))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.secondaryAccent)
            }
            
            // Stars
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: Double(index) <= gear.effectivenessRating ? "star.fill" : "star")
                        .font(.system(size: 28))
                        .foregroundColor(Double(index) <= gear.effectivenessRating ? AppTheme.secondaryAccent : AppTheme.textDisabled)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.cardHighlight)
                    .frame(height: 12)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.secondaryAccent, AppTheme.secondaryAccent.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: (UIScreen.main.bounds.width - 80) * (gear.effectivenessRating / 5.0), height: 12)
                    .shadow(color: AppTheme.secondaryAccent.opacity(0.5), radius: 8, x: 0, y: 4)
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
    
    // MARK: - Notes Section
    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.primaryAccent)
                
                Text("Notes")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            Text(notes)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(4)
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
            Button(action: {
                viewModel.incrementUsage(gear)
                gear.usageCount += 1
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Mark as Used")
                        .font(.system(size: 17, weight: .semibold))
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

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Stat Box Component
struct StatBox: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .blur(radius: 10)
                
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
        )
    }
}

// MARK: - Full Image View
struct FullImageView: View {
    @Environment(\.presentationMode) var presentationMode
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            AppTheme.background
                .edgesIgnoringSafeArea(.all)
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
            
            VStack {
                HStack {
                    Spacer()
                    
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
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Edit Gear View
struct EditGearView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: GearViewModel
    
    @State var gear: GearItem
    @State private var name: String
    @State private var selectedType: GearItem.GearType
    @State private var brand: String
    @State private var model: String
    @State private var rating: Double
    @State private var notes: String
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    init(gear: GearItem) {
        _gear = State(initialValue: gear)
        _name = State(initialValue: gear.name)
        _selectedType = State(initialValue: gear.type)
        _brand = State(initialValue: gear.brand ?? "")
        _model = State(initialValue: gear.model ?? "")
        _rating = State(initialValue: gear.effectivenessRating)
        _notes = State(initialValue: gear.notes ?? "")
        
        if let photoData = gear.photoData,
           let imageData = Data(base64Encoded: photoData),
           let uiImage = UIImage(data: imageData) {
            _selectedImage = State(initialValue: uiImage)
        }
    }
    
    var isValid: Bool {
        !name.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Photo section
                        photoSection
                        
                        DarkTextField(title: "Gear Name", text: $name, placeholder: "e.g., Shimano Stradic")
                        
                        typePickerSection
                        
                        DarkTextField(title: "Brand (Optional)", text: $brand, placeholder: "e.g., Shimano, Penn")
                        DarkTextField(title: "Model (Optional)", text: $model, placeholder: "e.g., 2500HG")
                        
                        ratingSection
                        
                        DarkTextEditor(title: "Notes (Optional)", text: $notes, placeholder: "Add any additional information...")
                        
                        Button(action: saveGear) {
                            Text("Save Changes")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppTheme.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(isValid ? AppTheme.secondaryGradient : LinearGradient(colors: [AppTheme.textDisabled, AppTheme.textDisabled], startPoint: .leading, endPoint: .trailing))
                                        .shadow(color: isValid ? AppTheme.secondaryAccent.opacity(0.5) : Color.clear, radius: 12, x: 0, y: 6)
                                )
                        }
                        .disabled(!isValid)
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
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
                    Text("Edit Gear")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
    
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photo (Optional)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            Button(action: { showingImagePicker = true }) {
                ZStack {
                    if #available(iOS 17.0, *) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.surface)
                            .frame(height: 180)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.secondaryAccent.opacity(0.3), lineWidth: 2)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.surface)
                            .frame(height: 180)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.secondaryAccent.opacity(0.3), lineWidth: 2)
                            )
                    }
                    
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.secondaryAccent.opacity(0.5))
                            
                            Text("Tap to add photo")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    private var typePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gear Type")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(GearItem.GearType.allCases, id: \.self) { type in
                    TypeButton(type: type, isSelected: selectedType == type) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedType = type
                        }
                    }
                }
            }
        }
    }
    
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Effectiveness Rating")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Text(String(format: "%.1f", rating))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.secondaryAccent)
            }
            
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { index in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            rating = Double(index)
                        }
                    }) {
                        Image(systemName: Double(index) <= rating ? "star.fill" : "star")
                            .font(.system(size: 32))
                            .foregroundColor(Double(index) <= rating ? AppTheme.secondaryAccent : AppTheme.textDisabled)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.secondaryAccent.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func saveGear() {
        var photoData: String?
        if let image = selectedImage,
           let imageData = image.jpegData(compressionQuality: 0.7) {
            photoData = imageData.base64EncodedString()
        }
        
        var updatedGear = gear
        updatedGear.name = name
        updatedGear.type = selectedType
        updatedGear.brand = brand.isEmpty ? nil : brand
        updatedGear.model = model.isEmpty ? nil : model
        updatedGear.photoData = photoData
        updatedGear.effectivenessRating = rating
        updatedGear.notes = notes.isEmpty ? nil : notes
        updatedGear.updatedAt = Date()
        
        viewModel.saveGearItem(updatedGear)
        presentationMode.wrappedValue.dismiss()
    }
}
