import SwiftUI

struct ChecklistDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: ChecklistViewModel
    @State var checklist: Checklist
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header card
                        headerCard
                        
                        // Progress section
                        progressSection
                        
                        // Items list
                        itemsSection
                        
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
                                .fill(AppTheme.success.opacity(0.2))
                                .frame(width: 36, height: 36)
                                .blur(radius: 8)
                            
                            Circle()
                                .fill(AppTheme.success.opacity(0.2))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.success)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditChecklistView(checklist: checklist)
                .environmentObject(viewModel)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Checklist"),
                message: Text("Are you sure you want to delete this checklist?"),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.deleteChecklist(checklist)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
        .onChange(of: viewModel.checklists) { newChecklists in
            if let updated = newChecklists.first(where: { $0.id == checklist.id }) {
                checklist = updated
            }
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category badge
            HStack(spacing: 8) {
                Image(systemName: checklist.category.icon)
                    .font(.system(size: 14))
                Text(checklist.category.rawValue)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(checklist.category.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(checklist.category.color.opacity(0.2))
            )
            
            // Title
            Text(checklist.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            // Date info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Created")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Text(checklist.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Updated")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Text(checklist.updatedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(checklist.category.color.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 16) {
            // Stats
            HStack(spacing: 16) {
                StatBox(
                    icon: "checkmark.circle.fill",
                    title: "Completed",
                    value: "\(checklist.items.filter { $0.isCompleted }.count)",
                    color: AppTheme.success
                )
                
                StatBox(
                    icon: "circle",
                    title: "Remaining",
                    value: "\(checklist.items.filter { !$0.isCompleted }.count)",
                    color: AppTheme.textSecondary
                )
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Progress")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    Text("\(Int(checklist.completionPercentage))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(checklist.category.color)
                }
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.cardHighlight)
                        .frame(height: 16)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [checklist.category.color, checklist.category.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: (UIScreen.main.bounds.width - 80) * (checklist.completionPercentage / 100), height: 16)
                        .shadow(color: checklist.category.color.opacity(0.5), radius: 8, x: 0, y: 4)
                }
                
                // Completion message
                if checklist.isCompleted {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.success)
                        
                        Text("All tasks completed!")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.success)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(AppTheme.success.opacity(0.2))
                    )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(checklist.category.color.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
            )
        }
    }
    
    // MARK: - Items Section
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tasks (\(checklist.items.count))")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            VStack(spacing: 12) {
                ForEach(checklist.items) { item in
                    ChecklistItemRow(
                        item: item,
                        categoryColor: checklist.category.color
                    ) {
                        toggleItem(item)
                    }
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Reset button
            if checklist.items.contains(where: { $0.isCompleted }) {
                Button(action: {
                    showingResetAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18))
                        Text("Reset All Items")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.secondaryAccent, AppTheme.secondaryAccent.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: AppTheme.secondaryAccent.opacity(0.5), radius: 12, x: 0, y: 6)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .alert(isPresented: $showingResetAlert) {
                    Alert(
                        title: Text("Reset Checklist"),
                        message: Text("This will uncheck all items. Continue?"),
                        primaryButton: .destructive(Text("Reset")) {
                            viewModel.resetChecklist(checklist)
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            
            HStack(spacing: 12) {
                Button(action: { showingEditSheet = true }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.success)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(AppTheme.success.opacity(0.2))
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
    
    private func toggleItem(_ item: ChecklistItem) {
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        viewModel.toggleItemCompletion(checklist, itemId: item.id)
    }
}

// MARK: - Checklist Item Row
struct ChecklistItemRow: View {
    let item: ChecklistItem
    let categoryColor: Color
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(item.isCompleted ? categoryColor : AppTheme.textDisabled, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    if item.isCompleted {
                        Circle()
                            .fill(categoryColor)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.background)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: item.isCompleted)
                
                // Text
                Text(item.text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(item.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary)
                    .strikethrough(item.isCompleted, color: AppTheme.textDisabled)
                
                Spacer()
                
                // Priority indicator
                if let priority = item.priority {
                    Circle()
                        .fill(priority.color)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.isCompleted ? AppTheme.cardHighlight.opacity(0.5) : AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(item.isCompleted ? Color.clear : categoryColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Create Checklist View
struct CreateChecklistView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: ChecklistViewModel
    
    @State private var title = ""
    @State private var selectedCategory: Checklist.ChecklistCategory = .custom
    @State private var items: [ChecklistItem] = []
    @State private var newItemText = ""
    @State private var selectedPriority: ChecklistItem.Priority?
    @State private var showingPriorityPicker = false
    
    var isValid: Bool {
        !title.isEmpty && !items.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Title
                        DarkTextField(
                            title: "Checklist Name",
                            text: $title,
                            placeholder: "e.g., Weekend Fishing Trip"
                        )
                        
                        // Category picker
                        categoryPickerSection
                        
                        // Items section
                        itemsSection
                        
                        // Add item field
                        addItemSection
                        
                        // Create button
                        Button(action: saveChecklist) {
                            Text("Create Checklist")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppTheme.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(isValid ? AppTheme.successGradient : LinearGradient(colors: [AppTheme.textDisabled, AppTheme.textDisabled], startPoint: .leading, endPoint: .trailing))
                                        .shadow(color: isValid ? AppTheme.success.opacity(0.5) : Color.clear, radius: 12, x: 0, y: 6)
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
                    Text("New Checklist")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
    }
    
    // MARK: - Category Picker
    private var categoryPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Checklist.ChecklistCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Items Section
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Items (\(items.count))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                if !items.isEmpty {
                    Button(action: {
                        items.removeAll()
                    }) {
                        Text("Clear All")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.danger)
                    }
                }
            }
            
            if items.isEmpty {
                if #available(iOS 17.0, *) {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 32))
                            .foregroundColor(AppTheme.textDisabled.opacity(0.5))
                        
                        Text("No items yet")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.textDisabled.opacity(0.2), lineWidth: 1)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            )
                    )
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 32))
                            .foregroundColor(AppTheme.textDisabled.opacity(0.5))
                        
                        Text("No items yet")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.textDisabled.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        EditableItemRow(
                            item: item,
                            categoryColor: selectedCategory.color
                        ) {
                            items.removeAll { $0.id == item.id }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Add Item Section
    private var addItemSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Item")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            HStack(spacing: 12) {
                TextField("Enter item name...", text: $newItemText)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.success.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .onSubmit {
                        addItem()
                    }
                
                Button(action: {
                    showingPriorityPicker.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(selectedPriority != nil ? (selectedPriority?.color.opacity(0.2) ?? AppTheme.surface) : AppTheme.surface)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(selectedPriority?.color ?? AppTheme.textDisabled)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: addItem) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.success.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .blur(radius: 8)
                        
                        Circle()
                            .fill(AppTheme.success)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.background)
                    }
                    .shadow(color: AppTheme.success.opacity(0.5), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(newItemText.isEmpty)
            }
            
            // Priority picker
            if showingPriorityPicker {
                HStack(spacing: 12) {
                    Text("Priority:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    ForEach([ChecklistItem.Priority.low, .medium, .high], id: \.self) { priority in
                        Button(action: {
                            selectedPriority = selectedPriority == priority ? nil : priority
                        }) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 10, height: 10)
                                
                                Text(priority.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(selectedPriority == priority ? AppTheme.background : priority.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedPriority == priority ? priority.color : priority.color.opacity(0.2))
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    Spacer()
                }
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private func addItem() {
        guard !newItemText.isEmpty else { return }
        
        let item = ChecklistItem(
            text: newItemText,
            priority: selectedPriority
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            items.append(item)
            newItemText = ""
            selectedPriority = nil
            showingPriorityPicker = false
        }
        
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
    }
    
    private func saveChecklist() {
        let checklist = Checklist(
            title: title,
            category: selectedCategory,
            items: items
        )
        
        viewModel.saveChecklist(checklist)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let category: Checklist.ChecklistCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? AppTheme.background : category.color)
                
                Text(category.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? AppTheme.background : AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? category.color : AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(category.color.opacity(0.5), lineWidth: isSelected ? 0 : 1)
                    )
            )
            .shadow(color: isSelected ? category.color.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Editable Item Row
struct EditableItemRow: View {
    let item: ChecklistItem
    let categoryColor: Color
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textDisabled)
            
            Text(item.text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            if let priority = item.priority {
                Circle()
                    .fill(priority.color)
                    .frame(width: 8, height: 8)
            }
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.danger)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(categoryColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Edit Checklist View
struct EditChecklistView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: ChecklistViewModel
    
    @State var checklist: Checklist
    @State private var title: String
    @State private var selectedCategory: Checklist.ChecklistCategory
    @State private var items: [ChecklistItem]
    @State private var newItemText = ""
    @State private var selectedPriority: ChecklistItem.Priority?
    @State private var showingPriorityPicker = false
    
    init(checklist: Checklist) {
        _checklist = State(initialValue: checklist)
        _title = State(initialValue: checklist.title)
        _selectedCategory = State(initialValue: checklist.category)
        _items = State(initialValue: checklist.items)
    }
    
    var isValid: Bool {
        !title.isEmpty && !items.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        DarkTextField(title: "Checklist Name", text: $title, placeholder: "e.g., Weekend Fishing Trip")
                        
                        categoryPickerSection
                        itemsSection
                        addItemSection
                        
                        Button(action: saveChanges) {
                            Text("Save Changes")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppTheme.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(isValid ? AppTheme.successGradient : LinearGradient(colors: [AppTheme.textDisabled, AppTheme.textDisabled], startPoint: .leading, endPoint: .trailing))
                                        .shadow(color: isValid ? AppTheme.success.opacity(0.5) : Color.clear, radius: 12, x: 0, y: 6)
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
                    Text("Edit Checklist")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
    }
    
    private var categoryPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Checklist.ChecklistCategory.allCases, id: \.self) { category in
                    CategoryButton(category: category, isSelected: selectedCategory == category) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }
    
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Items (\(items.count))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(items) { item in
                    EditableItemRow(item: item, categoryColor: selectedCategory.color) {
                        items.removeAll { $0.id == item.id }
                    }
                }
            }
        }
    }
    
    private var addItemSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Item")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            HStack(spacing: 12) {
                TextField("Enter item name...", text: $newItemText)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.success.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .onSubmit { addItem() }
                
                Button(action: { showingPriorityPicker.toggle() }) {
                    ZStack {
                        Circle()
                            .fill(selectedPriority != nil ? (selectedPriority?.color.opacity(0.2) ?? AppTheme.surface) : AppTheme.surface)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(selectedPriority?.color ?? AppTheme.textDisabled)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: addItem) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.success.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .blur(radius: 8)
                        
                        Circle()
                            .fill(AppTheme.success)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.background)
                    }
                    .shadow(color: AppTheme.success.opacity(0.5), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(newItemText.isEmpty)
            }
            
            if showingPriorityPicker {
                HStack(spacing: 12) {
                    Text("Priority:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    ForEach([ChecklistItem.Priority.low, .medium, .high], id: \.self) { priority in
                        Button(action: {
                            selectedPriority = selectedPriority == priority ? nil : priority
                        }) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 10, height: 10)
                                
                                Text(priority.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(selectedPriority == priority ? AppTheme.background : priority.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedPriority == priority ? priority.color : priority.color.opacity(0.2))
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    Spacer()
                }
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private func addItem() {
        guard !newItemText.isEmpty else { return }
        
        let item = ChecklistItem(text: newItemText, priority: selectedPriority)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            items.append(item)
            newItemText = ""
            selectedPriority = nil
            showingPriorityPicker = false
        }
        
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
    }
    
    private func saveChanges() {
        var updatedChecklist = checklist
        updatedChecklist.title = title
        updatedChecklist.category = selectedCategory
        updatedChecklist.items = items
        updatedChecklist.updatedAt = Date()
        
        viewModel.saveChecklist(updatedChecklist)
        presentationMode.wrappedValue.dismiss()
    }
}
