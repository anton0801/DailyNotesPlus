import Foundation
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    private let database = Database.database().reference()
    private var userId: String?
    
    @Published var isAuthenticated = false
    @Published var syncStatus: SyncStatus = .idle
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)
    }
    
    private init() {
        configureFirebase()
        authenticateAnonymously()
    }
    
    private func configureFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    func authenticateAnonymously() {
        Auth.auth().signInAnonymously { [weak self] result, error in
            if let error = error {
                print("Firebase auth error: \(error.localizedDescription)")
                self?.syncStatus = .error(error.localizedDescription)
                return
            }
            
            self?.userId = result?.user.uid
            self?.isAuthenticated = true
            print("Firebase authenticated with ID: \(self?.userId ?? "unknown")")
        }
    }
    
    // MARK: - Notes Operations
    
    func saveNote(_ note: FishingNote, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = userId else {
            completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        syncStatus = .syncing
        
        let notePath = "users/\(userId)/notes/\(note.id)"
        database.child(notePath).setValue(note.toDictionary()) { [weak self] error, _ in
            if let error = error {
                self?.syncStatus = .error(error.localizedDescription)
                completion(.failure(error))
            } else {
                self?.syncStatus = .success
                completion(.success(()))
            }
        }
    }
    
    func fetchNotes(completion: @escaping (Result<[FishingNote], Error>) -> Void) {
        guard let userId = userId else {
            completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        syncStatus = .syncing
        
        let notesPath = "users/\(userId)/notes"
        database.child(notesPath).observeSingleEvent(of: .value) { [weak self] snapshot in
            var notes: [FishingNote] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let note = FishingNote.fromDictionary(dict) {
                    notes.append(note)
                }
            }
            
            self?.syncStatus = .success
            completion(.success(notes))
        } withCancel: { [weak self] error in
            self?.syncStatus = .error(error.localizedDescription)
            completion(.failure(error))
        }
    }
    
    func deleteNote(_ noteId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = userId else {
            completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let notePath = "users/\(userId)/notes/\(noteId)"
        database.child(notePath).removeValue { [weak self] error, _ in
            if let error = error {
                self?.syncStatus = .error(error.localizedDescription)
                completion(.failure(error))
            } else {
                self?.syncStatus = .success
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Gear Operations
    
    func saveGearItem(_ item: GearItem, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = userId else {
            completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let gearPath = "users/\(userId)/gear/\(item.id)"
        database.child(gearPath).setValue(item.toDictionary()) { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func fetchGear(completion: @escaping (Result<[GearItem], Error>) -> Void) {
        guard let userId = userId else {
            completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let gearPath = "users/\(userId)/gear"
        database.child(gearPath).observeSingleEvent(of: .value) { snapshot in
            var items: [GearItem] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let item = GearItem.fromDictionary(dict) {
                    items.append(item)
                }
            }
            
            completion(.success(items))
        } withCancel: { error in
            completion(.failure(error))
        }
    }
    
    func deleteGearItem(_ itemId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = userId else {
            completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let gearPath = "users/\(userId)/gear/\(itemId)"
        database.child(gearPath).removeValue { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Checklist Operations
    
    func saveChecklist(_ checklist: Checklist, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = userId else {
            completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let checklistPath = "users/\(userId)/checklists/\(checklist.id)"
        database.child(checklistPath).setValue(checklist.toDictionary()) { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func fetchChecklists(completion: @escaping (Result<[Checklist], Error>) -> Void) {
        guard let userId = userId else {
            completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let checklistsPath = "users/\(userId)/checklists"
        database.child(checklistsPath).observeSingleEvent(of: .value) { snapshot in
            var checklists: [Checklist] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let checklist = Checklist.fromDictionary(dict) {
                    checklists.append(checklist)
                }
            }
            
            completion(.success(checklists))
        } withCancel: { error in
            completion(.failure(error))
        }
    }
    
    func deleteChecklist(_ checklistId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = userId else {
            completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let checklistPath = "users/\(userId)/checklists/\(checklistId)"
        database.child(checklistPath).removeValue { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
