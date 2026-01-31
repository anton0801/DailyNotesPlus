import SwiftUI

enum ApplicationStage: Equatable {
    case dormant
    case starting
    case verifying
    case authorized
    case running(destination: String)
    case paused
    case offline
}

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var notesViewModel = NotesViewModel()
    @StateObject private var gearViewModel = GearViewModel()
    @StateObject private var checklistViewModel = ChecklistViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                mainTabView
            }
        }
        .preferredColorScheme(.dark) // Force dark mode
    }
    
    private var mainTabView: some View {
        ZStack(alignment: .bottom) {
            // Main content
            TabView(selection: $selectedTab) {
                HomeView()
                    .environmentObject(notesViewModel)
                    .environmentObject(gearViewModel)
                    .environmentObject(checklistViewModel)
                    .tag(0)
                
                NotesListView()
                    .environmentObject(notesViewModel)
                    .environmentObject(gearViewModel)
                    .tag(1)
                
                GearListView()
                    .environmentObject(gearViewModel)
                    .tag(2)
                
                ChecklistsView()
                    .environmentObject(checklistViewModel)
                    .tag(3)
                
                SettingsView()
                    .environmentObject(notesViewModel)
                    .environmentObject(gearViewModel)
                    .environmentObject(checklistViewModel)
                    .tag(4)
            }
            
            // Custom Tab Bar
            DarkWaterTabBar(selectedTab: $selectedTab)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct DarkWaterTabBar: View {
    @Binding var selectedTab: Int
    @State private var tabAnimation = [false, false, false, false, false]
    
    let tabs = [
        TabItem(icon: "house.fill", title: "Home", activeColor: AppTheme.primaryAccent),
        TabItem(icon: "note.text", title: "Notes", activeColor: AppTheme.primaryAccent),
        TabItem(icon: "figure.fishing", title: "Gear", activeColor: AppTheme.secondaryAccent),
        TabItem(icon: "checklist", title: "Lists", activeColor: AppTheme.success),
        TabItem(icon: "gear", title: "Settings", activeColor: AppTheme.textSecondary)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                DarkTabButton(
                    item: tabs[index],
                    isSelected: selectedTab == index,
                    animate: tabAnimation[index]
                ) {
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                        tabAnimation[index] = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        tabAnimation[index] = false
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(AppTheme.primaryAccent.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: -5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct TabItem {
    let icon: String
    let title: String
    let activeColor: Color
}

struct DarkTabButton: View {
    let item: TabItem
    let isSelected: Bool
    let animate: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Neon glow when selected
                    if isSelected {
                        Circle()
                            .fill(item.activeColor.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .blur(radius: 10)
                    }
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 24, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? item.activeColor : AppTheme.textSecondary)
                        .scaleEffect(animate ? 1.3 : 1.0)
                        .shadow(color: isSelected ? item.activeColor.opacity(0.8) : Color.clear, radius: 8, x: 0, y: 0)
                }
                
                Text(item.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? item.activeColor : AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? item.activeColor.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}

enum StreamEvent {
    case boot
    case dataIngested([String: Any])
    case validationPassed
    case validationRejected
    case destinationFound(String)
    case connectivityLost
    case connectivityRestored
    case timeout
}
