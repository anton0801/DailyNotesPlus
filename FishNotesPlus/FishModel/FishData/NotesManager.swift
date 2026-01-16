import Foundation

class NotesManager: ObservableObject {
    @Published var notes: [Note] {
        didSet {
            save()
        }
    }
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "notes") {
            if let decoded = try? JSONDecoder().decode([Note].self, from: data) {
                notes = decoded
                return
            }
        }
        notes = []
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: "notes")
        }
    }
}
