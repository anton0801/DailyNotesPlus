import SwiftUI
import Combine

class GearViewModel: ObservableObject {
    @Published var gearItems: [GearItem] = []
    @Published var filteredGearItems: [GearItem] = []
    @Published var searchText = ""
    @Published var selectedType: GearItem.GearType?
    @Published var sortBy: SortOption = .name
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let firebaseService = FirebaseService.shared
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case rating = "Rating"
        case usage = "Usage"
        case recent = "Recent"
    }
    
    var gearByType: [GearItem.GearType: [GearItem]] {
        Dictionary(grouping: gearItems) { $0.type }
    }
    
    init() {
        setupObservers()
        loadGear()
    }
    
    private func setupObservers() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest3($selectedType, $sortBy, $gearItems)
            .sink { [weak self] _, _, _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    func loadGear() {
        isLoading = true
        errorMessage = nil
        
        firebaseService.fetchGear { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let items):
                    self?.gearItems = items
                    self?.applyFilters()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func saveGearItem(_ item: GearItem) {
        firebaseService.saveGearItem(item) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if let index = self?.gearItems.firstIndex(where: { $0.id == item.id }) {
                        self?.gearItems[index] = item
                    } else {
                        self?.gearItems.append(item)
                    }
                    self?.applyFilters()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func deleteGearItem(_ item: GearItem) {
        firebaseService.deleteGearItem(item.id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.gearItems.removeAll { $0.id == item.id }
                    self?.applyFilters()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func incrementUsage(_ item: GearItem) {
        var updatedItem = item
        updatedItem.usageCount += 1
        updatedItem.updatedAt = Date()
        saveGearItem(updatedItem)
    }
    
    private func applyFilters() {
        var filtered = gearItems
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.brand?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.model?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Type filter
        if let type = selectedType {
            filtered = filtered.filter { $0.type == type }
        }
        
        // Sort
        switch sortBy {
        case .name:
            filtered.sort { $0.name < $1.name }
        case .rating:
            filtered.sort { $0.effectivenessRating > $1.effectivenessRating }
        case .usage:
            filtered.sort { $0.usageCount > $1.usageCount }
        case .recent:
            filtered.sort { $0.updatedAt > $1.updatedAt }
        }
        
        filteredGearItems = filtered
    }
}
