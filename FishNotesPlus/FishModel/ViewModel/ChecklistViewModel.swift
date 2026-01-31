import SwiftUI
import Combine

class ChecklistViewModel: ObservableObject {
    @Published var checklists: [Checklist] = []
    @Published var filteredChecklists: [Checklist] = []
    @Published var searchText = ""
    @Published var selectedCategory: Checklist.ChecklistCategory?
    @Published var showCompletedOnly = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let firebaseService = FirebaseService.shared
    
    var templates: [Checklist] {
        checklists.filter { $0.isTemplate }
    }
    
    var userChecklists: [Checklist] {
        checklists.filter { !$0.isTemplate }
    }
    
    init() {
        setupObservers()
        loadChecklists()
        createDefaultTemplates()
    }
    
    private func setupObservers() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest3($selectedCategory, $showCompletedOnly, $checklists)
            .sink { [weak self] _, _, _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    func loadChecklists() {
        isLoading = true
        errorMessage = nil
        
        firebaseService.fetchChecklists { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let checklists):
                    self?.checklists = checklists
                    self?.applyFilters()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func saveChecklist(_ checklist: Checklist) {
        firebaseService.saveChecklist(checklist) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if let index = self?.checklists.firstIndex(where: { $0.id == checklist.id }) {
                        self?.checklists[index] = checklist
                    } else {
                        self?.checklists.append(checklist)
                    }
                    self?.applyFilters()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func deleteChecklist(_ checklist: Checklist) {
        firebaseService.deleteChecklist(checklist.id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.checklists.removeAll { $0.id == checklist.id }
                    self?.applyFilters()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func toggleItemCompletion(_ checklist: Checklist, itemId: String) {
        var updatedChecklist = checklist
        if let index = updatedChecklist.items.firstIndex(where: { $0.id == itemId }) {
            updatedChecklist.items[index].isCompleted.toggle()
            updatedChecklist.updatedAt = Date()
            saveChecklist(updatedChecklist)
        }
    }
    
    func resetChecklist(_ checklist: Checklist) {
        var updatedChecklist = checklist
        updatedChecklist.items = updatedChecklist.items.map {
            var item = $0
            item.isCompleted = false
            return item
        }
        updatedChecklist.updatedAt = Date()
        saveChecklist(updatedChecklist)
    }
    
    private func applyFilters() {
        var filtered = checklists.filter { !$0.isTemplate }
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.items.contains { $0.text.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Completion filter
        if showCompletedOnly {
            filtered = filtered.filter { $0.isCompleted }
        }
        
        filteredChecklists = filtered.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    private func createDefaultTemplates() {
        let hasTemplates = UserDefaults.standard.bool(forKey: "hasCreatedDefaultTemplates")
        guard !hasTemplates else { return }
        
        // Pre-Trip Preparation Template
        let preparationTemplate = Checklist(
            title: "Pre-Trip Preparation",
            category: .preparation,
            items: [
                ChecklistItem(text: "Check weather forecast", priority: .high),
                ChecklistItem(text: "Check fishing regulations", priority: .high),
                ChecklistItem(text: "Plan fishing location", priority: .medium),
                ChecklistItem(text: "Charge electronics", priority: .medium),
                ChecklistItem(text: "Prepare bait", priority: .low)
            ],
            isTemplate: true
        )
        
        // Packing Template
        let packingTemplate = Checklist(
            title: "Packing Checklist",
            category: .packing,
            items: [
                ChecklistItem(text: "Fishing rods", priority: .high),
                ChecklistItem(text: "Reels and line", priority: .high),
                ChecklistItem(text: "Tackle box", priority: .high),
                ChecklistItem(text: "Bait and lures", priority: .high),
                ChecklistItem(text: "Fishing license", priority: .high),
                ChecklistItem(text: "Sunscreen", priority: .medium),
                ChecklistItem(text: "Hat and sunglasses", priority: .medium),
                ChecklistItem(text: "Water and snacks", priority: .medium),
                ChecklistItem(text: "First aid kit", priority: .low),
                ChecklistItem(text: "Camera", priority: .low)
            ],
            isTemplate: true
        )
        
        // Cleanup Template
        let cleanupTemplate = Checklist(
            title: "After Trip Cleanup",
            category: .cleanup,
            items: [
                ChecklistItem(text: "Clean and dry rods", priority: .high),
                ChecklistItem(text: "Rinse reels", priority: .high),
                ChecklistItem(text: "Organize tackle box", priority: .medium),
                ChecklistItem(text: "Store gear properly", priority: .medium),
                ChecklistItem(text: "Dispose of trash", priority: .low)
            ],
            isTemplate: true
        )
        
        saveChecklist(preparationTemplate)
        saveChecklist(packingTemplate)
        saveChecklist(cleanupTemplate)
        
        UserDefaults.standard.set(true, forKey: "hasCreatedDefaultTemplates")
    }
}
