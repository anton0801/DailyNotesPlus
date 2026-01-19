import SwiftUI
import Firebase

@main
struct FishNotesPlusApp: App {
    
    @UIApplicationDelegateAdaptor(LifecyclePublisher.self) var lifecyclePublisher
    
    var body: some Scene {
        WindowGroup {
            NotesApplicationView()
        }
    }
}
