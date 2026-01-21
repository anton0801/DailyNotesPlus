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
    @StateObject private var viewModel = NotesViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                mainTabView
            }
        }
    }
    
    private var mainTabView: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NotesListView()
                    .environmentObject(viewModel)
                    .tag(0)
                
                TagsView()
                    .environmentObject(viewModel)
                    .tag(1)
                
                FavoritesView()
                    .environmentObject(viewModel)
                    .tag(2)
                
                SettingsView()
                    .environmentObject(viewModel)
                    .tag(3)
            }
            
            CustomTabBar(selectedTab: $selectedTab)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

// CustomTabBar.swift
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @State private var tabAnimation = [false, false, false, false]
    
    let tabs = [
        TabItem(icon: "note.text", title: "Notes"),
        TabItem(icon: "tag.fill", title: "Tags"),
        TabItem(icon: "star.fill", title: "Favorites"),
        TabItem(icon: "gear", title: "Settings")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                TabButton(
                    item: tabs[index],
                    isSelected: selectedTab == index,
                    animate: tabAnimation[index]
                ) {
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
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct TabItem {
    let icon: String
    let title: String
}

struct TabButton: View {
    let item: TabItem
    let isSelected: Bool
    let animate: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: item.icon)
                    .font(.system(size: 24, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color(hex: "1E88E5") : Color(hex: "7F8C8D"))
                    .scaleEffect(animate ? 1.2 : 1.0)
                
                Text(item.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color(hex: "1E88E5") : Color(hex: "7F8C8D"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(hex: "1E88E5").opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(ScaleButtonStyle())
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
