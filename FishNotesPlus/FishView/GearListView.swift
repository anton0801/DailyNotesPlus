import SwiftUI

struct GearListView: View {
    @EnvironmentObject var viewModel: GearViewModel
    @State private var showingAddGear = false
    @State private var showingFilters = false
    @State private var selectedGear: GearItem?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Filter chips
                    if showingFilters {
                        filterChipsView
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Gear list
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryAccent))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.filteredGearItems.isEmpty {
                        emptyStateView
                    } else {
                        gearListView
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddGear) {
                AddGearView()
                    .environmentObject(viewModel)
            }
            .sheet(item: $selectedGear) { gear in
                GearDetailView(gear: gear)
                    .environmentObject(viewModel)
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Gear")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("\(viewModel.filteredGearItems.count) items")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Filter button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingFilters.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(showingFilters ? AppTheme.secondaryAccent.opacity(0.2) : AppTheme.surface)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 22))
                        .foregroundColor(showingFilters ? AppTheme.secondaryAccent : AppTheme.textSecondary)
                }
                .shadow(color: showingFilters ? AppTheme.secondaryAccent.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 0)
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Add button
            Button(action: { showingAddGear = true }) {
                ZStack {
                    Circle()
                        .fill(AppTheme.secondaryAccent.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .blur(radius: 8)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.secondaryAccent, AppTheme.secondaryAccent.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.background)
                }
                .shadow(color: AppTheme.secondaryAccent.opacity(0.5), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Filter Chips
    private var filterChipsView: some View {
        VStack(spacing: 12) {
            // Type filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All",
                        isSelected: viewModel.selectedType == nil,
                        color: AppTheme.textSecondary
                    ) {
                        viewModel.selectedType = nil
                    }
                    
                    ForEach(GearItem.GearType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.rawValue,
                            icon: type.icon,
                            isSelected: viewModel.selectedType == type,
                            color: type.color
                        ) {
                            viewModel.selectedType = viewModel.selectedType == type ? nil : type
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Sort options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GearViewModel.SortOption.allCases, id: \.self) { option in
                        SortChip(
                            title: option.rawValue,
                            isSelected: viewModel.sortBy == option
                        ) {
                            viewModel.sortBy = option
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Gear List
    private var gearListView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredGearItems) { gear in
                    GearCardView(gear: gear)
                        .environmentObject(viewModel)
                        .onTapGesture {
                            selectedGear = gear
                        }
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
                    .fill(AppTheme.secondaryAccent.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "figure.fishing")
                    .font(.system(size: 50))
                    .foregroundColor(AppTheme.secondaryAccent.opacity(0.5))
            }
            
            VStack(spacing: 12) {
                Text("No Gear Yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Start building your fishing gear collection")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingAddGear = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add First Gear")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.background)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(AppTheme.secondaryGradient)
                        .shadow(color: AppTheme.secondaryAccent.opacity(0.5), radius: 12, x: 0, y: 6)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}

// MARK: - Gear Card Component
struct GearCardView: View {
    let gear: GearItem
    @EnvironmentObject var viewModel: GearViewModel
    @State private var showImage = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Gear image or icon
            ZStack {
                if let photoData = gear.photoData,
                   let imageData = Data(base64Encoded: photoData),
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(gear.type.color.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: gear.type.icon)
                                .font(.system(size: 32))
                                .foregroundColor(gear.type.color)
                        )
                }
            }
            .shadow(color: gear.type.color.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // Gear info
            VStack(alignment: .leading, spacing: 8) {
                // Name
                Text(gear.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                
                // Brand & Model
                if let brand = gear.brand, !brand.isEmpty {
                    Text(brand + (gear.model != nil ? " • \(gear.model!)" : ""))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                
                // Type badge
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: gear.type.icon)
                            .font(.system(size: 10))
                        Text(gear.type.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(gear.type.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(gear.type.color.opacity(0.2))
                    )
                    
                    Spacer()
                }
                
                // Rating & Usage
                HStack(spacing: 12) {
                    // Rating stars
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(gear.effectivenessRating.rounded()) ? "star.fill" : "star")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.secondaryAccent)
                        }
                    }
                    
                    // Usage count
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10))
                        Text("\(gear.usageCount)")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textDisabled)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(gear.type.color.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? AppTheme.background : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : AppTheme.surface)
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.5), lineWidth: isSelected ? 0 : 1)
                    )
            )
            .shadow(color: isSelected ? color.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Sort Chip
struct SortChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .foregroundColor(isSelected ? AppTheme.background : AppTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? AppTheme.primaryAccent : AppTheme.cardHighlight)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Add Gear View
struct AddGearView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: GearViewModel
    
    @State private var name = ""
    @State private var selectedType: GearItem.GearType = .rod
    @State private var brand = ""
    @State private var model = ""
    @State private var rating: Double = 0
    @State private var notes = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
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
                        
                        // Name
                        DarkTextField(
                            title: "Gear Name",
                            text: $name,
                            placeholder: "e.g., Shimano Stradic"
                        )
                        
                        // Type picker
                        typePickerSection
                        
                        // Brand & Model
                        DarkTextField(
                            title: "Brand (Optional)",
                            text: $brand,
                            placeholder: "e.g., Shimano, Penn"
                        )
                        
                        DarkTextField(
                            title: "Model (Optional)",
                            text: $model,
                            placeholder: "e.g., 2500HG"
                        )
                        
                        // Rating
                        ratingSection
                        
                        // Notes
                        DarkTextEditor(
                            title: "Notes (Optional)",
                            text: $notes,
                            placeholder: "Add any additional information..."
                        )
                        
                        // Save button
                        Button(action: saveGear) {
                            Text("Add Gear")
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
                    Text("Add Gear")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
    
    // MARK: - Photo Section
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
    
    // MARK: - Type Picker Section
    private var typePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gear Type")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(GearItem.GearType.allCases, id: \.self) { type in
                    TypeButton(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedType = type
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Rating Section
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
        
        let gear = GearItem(
            name: name,
            type: selectedType,
            brand: brand.isEmpty ? nil : brand,
            model: model.isEmpty ? nil : model,
            photoData: photoData,
            effectivenessRating: rating,
            usageCount: 0,
            notes: notes.isEmpty ? nil : notes
        )
        
        viewModel.saveGearItem(gear)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Type Button
struct TypeButton: View {
    let type: GearItem.GearType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? AppTheme.background : type.color)
                
                Text(type.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? AppTheme.background : AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? type.color : AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(type.color.opacity(0.5), lineWidth: isSelected ? 0 : 1)
                    )
            )
            .shadow(color: isSelected ? type.color.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Dark TextField Component
struct DarkTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.textPrimary)
                .padding(16)
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
}

// MARK: - Dark Text Editor Component
struct DarkTextEditor: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.textDisabled)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                }
                
                TextEditor(text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
            }
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
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
