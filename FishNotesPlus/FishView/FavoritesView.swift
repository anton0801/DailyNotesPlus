import SwiftUI
import WebKit


final class ViewHandler: NSObject {
    
    weak var controller: ViewController?
    var redirectCounter = 0
    var lastKnownURL: URL?
    let redirectThreshold = 70
    
    init(controller: ViewController) {
        self.controller = controller
        super.init()
    }
}

struct FavoritesView: View {
    @EnvironmentObject var viewModel: NotesViewModel
    
    var favoriteNotes: [FishingNote] {
        viewModel.notes.filter { $0.isFavorite }.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFAF8")
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Favorites")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(hex: "2C3E50"))
                            
                            Text("\(favoriteNotes.count) favorite\(favoriteNotes.count == 1 ? "" : "s")")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "7F8C8D"))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "FF6F00"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    if favoriteNotes.isEmpty {
                        emptyStateView
                    } else {
                        notesListView
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var notesListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(favoriteNotes) { note in
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
            Image(systemName: "star")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "FF6F00").opacity(0.3))
            
            Text("No Favorites Yet")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color(hex: "2C3E50"))
            
            Text("Mark important notes as favorites to access them quickly")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "7F8C8D"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


final class SessionStrategy {
    
    private let storageKey = "stored_sessions"
    
    func restore() {
        guard let saved = UserDefaults.standard.object(forKey: storageKey) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else {
            return
        }
        
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        
        let allCookies = saved.values
            .flatMap { $0.values }
            .compactMap { properties in
                HTTPCookie(properties: properties as [HTTPCookiePropertyKey: Any])
            }
        
        allCookies.forEach { cookie in
            cookieStore.setCookie(cookie)
        }
    }
    
    func save(from view: WKWebView) {
        let cookieStore = view.configuration.websiteDataStore.httpCookieStore
        
        cookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            
            var grouped: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            
            for cookie in cookies {
                var domainGroup = grouped[cookie.domain] ?? [:]
                
                if let properties = cookie.properties {
                    domainGroup[cookie.name] = properties
                }
                
                grouped[cookie.domain] = domainGroup
            }
            
            UserDefaults.standard.set(grouped, forKey: self.storageKey)
        }
    }
}
