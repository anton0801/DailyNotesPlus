import SwiftUI

struct ChecklistsView: View {
    @EnvironmentObject var viewModel: ChecklistViewModel
    @State private var showingAddChecklist = false
    @State private var selectedChecklist: Checklist?
    @State private var showingTemplates = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Templates section (if showing)
                    if showingTemplates {
                        templatesSection
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Checklists list
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.success))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.filteredChecklists.isEmpty {
                        emptyStateView
                    } else {
                        checklistsListView
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddChecklist) {
                CreateChecklistView()
                    .environmentObject(viewModel)
            }
            .sheet(item: $selectedChecklist) { checklist in
                ChecklistDetailView(checklist: checklist)
                    .environmentObject(viewModel)
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Checklists")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("\(viewModel.filteredChecklists.count) lists")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Templates button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingTemplates.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(showingTemplates ? AppTheme.success.opacity(0.2) : AppTheme.surface)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: showingTemplates ? "star.fill" : "star")
                        .font(.system(size: 20))
                        .foregroundColor(showingTemplates ? AppTheme.success : AppTheme.textSecondary)
                }
                .shadow(color: showingTemplates ? AppTheme.success.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 0)
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Add button
            Button(action: { showingAddChecklist = true }) {
                ZStack {
                    Circle()
                        .fill(AppTheme.success.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .blur(radius: 8)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.success, AppTheme.success.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.background)
                }
                .shadow(color: AppTheme.success.opacity(0.5), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Templates Section
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Templates")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.templates) { template in
                        TemplateCard(template: template) {
                            createFromTemplate(template)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Checklists List
    private var checklistsListView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredChecklists) { checklist in
                    ChecklistCardView(checklist: checklist)
                        .environmentObject(viewModel)
                        .onTapGesture {
                            selectedChecklist = checklist
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
                    .fill(AppTheme.success.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checklist")
                    .font(.system(size: 50))
                    .foregroundColor(AppTheme.success.opacity(0.5))
            }
            
            VStack(spacing: 12) {
                Text("No Checklists Yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Create checklists to stay organized")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingAddChecklist = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Checklist")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.background)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(AppTheme.successGradient)
                        .shadow(color: AppTheme.success.opacity(0.5), radius: 12, x: 0, y: 6)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    private func createFromTemplate(_ template: Checklist) {
        var newChecklist = template
        newChecklist.id = UUID().uuidString
        newChecklist.isTemplate = false
        newChecklist.createdAt = Date()
        newChecklist.updatedAt = Date()
        newChecklist.items = template.items.map {
            var item = $0
            item.id = UUID().uuidString
            item.isCompleted = false
            return item
        }
        
        viewModel.saveChecklist(newChecklist)
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: Checklist
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: template.category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(template.category.color)
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(template.category.color.opacity(0.6))
                }
                
                Text(template.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(2)
                
                Text("\(template.items.count) items")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(16)
            .frame(width: 180)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(template.category.color.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Checklist Card
struct ChecklistCardView: View {
    let checklist: Checklist
    @EnvironmentObject var viewModel: ChecklistViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Category icon
                ZStack {
                    Circle()
                        .fill(checklist.category.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: checklist.category.icon)
                        .font(.system(size: 18))
                        .foregroundColor(checklist.category.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(checklist.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                    
                    Text(checklist.category.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                // Completion badge
                if checklist.isCompleted {
                    ZStack {
                        Circle()
                            .fill(AppTheme.success.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.success)
                    }
                }
            }
            
            // Progress bar
            VStack(spacing: 8) {
                HStack {
                    Text("\(checklist.items.filter { $0.isCompleted }.count) / \(checklist.items.count) completed")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text("\(Int(checklist.completionPercentage))%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(checklist.category.color)
                }
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.cardHighlight)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [checklist.category.color, checklist.category.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: (UIScreen.main.bounds.width - 80) * (checklist.completionPercentage / 100), height: 8)
                        .shadow(color: checklist.category.color.opacity(0.4), radius: 4, x: 0, y: 2)
                }
            }
            
            // Quick items preview
            if !checklist.items.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(checklist.items.prefix(3)) { item in
                        HStack(spacing: 8) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14))
                                .foregroundColor(item.isCompleted ? AppTheme.success : AppTheme.textDisabled)
                            
                            Text(item.text)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(item.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary)
                                .strikethrough(item.isCompleted)
                                .lineLimit(1)
                        }
                    }
                    
                    if checklist.items.count > 3 {
                        Text("+\(checklist.items.count - 3) more")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textDisabled)
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
                        .stroke(checklist.category.color.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
}
