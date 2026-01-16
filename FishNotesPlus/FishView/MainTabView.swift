import SwiftUI

struct MainTabView: View {
    @StateObject private var notesManager = NotesManager()
    
    var body: some View {
        TabView {
            NotesView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
            
            TagsView()
                .tabItem {
                    Label("Tags", systemImage: "tag")
                }
            
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "star")
                }
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environmentObject(notesManager)
        .accentColor(accentBlue)
        .background(backgroundColor)
    }
}

#Preview {
    MainTabView()
}
