import SwiftUI
import Combine

class NotesViewModel: ObservableObject {
    @Published var notes: [FishingNote] = []
    @Published var filteredNotes: [FishingNote] = []
    @Published var searchText = ""
    @Published var selectedSeason: FishingNote.Season?
    @Published var selectedTags: Set<String> = []
    @Published var showFavoritesOnly = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let firebaseService = FirebaseService.shared
    
    var allTags: [String] {
        Array(Set(notes.flatMap { $0.tags })).sorted()
    }
    
    var tagCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for note in notes {
            for tag in note.tags {
                counts[tag, default: 0] += 1
            }
        }
        return counts
    }
    
    init() {
        setupObservers()
        loadNotes()
    }
    
    private func setupObservers() {
        // Observe search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Observe filter changes
        Publishers.CombineLatest4($selectedSeason, $selectedTags, $showFavoritesOnly, $notes)
            .sink { [weak self] _, _, _, _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    func loadNotes() {
        isLoading = true
        errorMessage = nil
        
        firebaseService.fetchNotes { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let notes):
                    self?.notes = notes.sorted { $0.createdAt > $1.createdAt }
                    self?.applyFilters()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func saveNote(_ note: FishingNote) {
        firebaseService.saveNote(note) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if let index = self?.notes.firstIndex(where: { $0.id == note.id }) {
                        self?.notes[index] = note
                    } else {
                        self?.notes.insert(note, at: 0)
                    }
                    self?.applyFilters()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func deleteNote(_ note: FishingNote) {
        firebaseService.deleteNote(note.id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.notes.removeAll { $0.id == note.id }
                    self?.applyFilters()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func toggleFavorite(_ note: FishingNote) {
        var updatedNote = note
        updatedNote.isFavorite.toggle()
        updatedNote.updatedAt = Date()
        saveNote(updatedNote)
    }
    
    private func applyFilters() {
        var filtered = notes
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.noteText.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Season filter
        if let season = selectedSeason {
            filtered = filtered.filter { $0.season == season }
        }
        
        // Tags filter
        if !selectedTags.isEmpty {
            filtered = filtered.filter { note in
                !Set(note.tags).isDisjoint(with: selectedTags)
            }
        }
        
        // Favorites filter
        if showFavoritesOnly {
            filtered = filtered.filter { $0.isFavorite }
        }
        
        filteredNotes = filtered
    }
    
    func exportNotes(format: ExportFormat) -> URL? {
        let fileName = "fishing_notes_\(Date().timeIntervalSince1970).\(format.fileExtension)"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        var content = ""
        
        switch format {
        case .txt:
            content = generateTXTContent()
        case .csv:
            content = generateCSVContent()
        }
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
            return nil
        }
    }
    
    private func generateTXTContent() -> String {
        var content = "FISHING NOTES EXPORT\n"
        content += "Generated: \(DateFormatter.longFormatter.string(from: Date()))\n"
        content += String(repeating: "=", count: 50) + "\n\n"
        
        for note in filteredNotes {
            content += "TITLE: \(note.title)\n"
            content += "DATE: \(DateFormatter.longFormatter.string(from: note.createdAt))\n"
            content += "SEASON: \(note.season.rawValue)\n"
            if let fish = note.relatedFish, !fish.isEmpty {
                content += "FISH: \(fish)\n"
            }
            if let location = note.location, !location.isEmpty {
                content += "LOCATION: \(location)\n"
            }
            if !note.tags.isEmpty {
                content += "TAGS: \(note.tags.joined(separator: ", "))\n"
            }
            content += "\nNOTE:\n\(note.noteText)\n"
            content += String(repeating: "-", count: 50) + "\n\n"
        }
        
        return content
    }
    
    private func generateCSVContent() -> String {
        var content = "Title,Date,Season,Fish,Location,Tags,Note,Favorite\n"
        
        for note in filteredNotes {
            let fields = [
                escapeCSV(note.title),
                escapeCSV(DateFormatter.shortFormatter.string(from: note.createdAt)),
                escapeCSV(note.season.rawValue),
                escapeCSV(note.relatedFish ?? ""),
                escapeCSV(note.location ?? ""),
                escapeCSV(note.tags.joined(separator: "; ")),
                escapeCSV(note.noteText),
                note.isFavorite ? "Yes" : "No"
            ]
            content += fields.joined(separator: ",") + "\n"
        }
        
        return content
    }
    
    private func escapeCSV(_ field: String) -> String {
        let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escapedField)\""
    }
}

enum ExportFormat {
    case txt
    case csv
    
    var fileExtension: String {
        switch self {
        case .txt: return "txt"
        case .csv: return "csv"
        }
    }
}

extension DateFormatter {
    static let longFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}
