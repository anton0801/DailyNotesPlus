import Foundation
import FirebaseDatabase
import SwiftUI

struct GearItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var type: GearType
    var brand: String?
    var model: String?
    var photoData: String? // base64 encoded image
    var effectivenessRating: Double // 0-5 stars
    var usageCount: Int
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    enum GearType: String, Codable, CaseIterable {
        case rod = "Rod"
        case reel = "Reel"
        case lure = "Lure"
        case bait = "Bait"
        case line = "Line"
        case hook = "Hook"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .rod: return "figure.fishing"
            case .reel: return "circle.hexagonpath"
            case .lure: return "triangle.fill"
            case .bait: return "circle.fill"
            case .line: return "line.diagonal"
            case .hook: return "j.circle.fill"
            case .other: return "questionmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .rod: return AppTheme.primaryAccent
            case .reel: return AppTheme.secondaryAccent
            case .lure: return Color(hex: "4ADE80")
            case .bait: return Color(hex: "FF6B35")
            case .line: return Color(hex: "00D9FF")
            case .hook: return Color(hex: "FFA726")
            case .other: return AppTheme.textSecondary
            }
        }
    }
    
    init(
        id: String = UUID().uuidString,
        name: String,
        type: GearType,
        brand: String? = nil,
        model: String? = nil,
        photoData: String? = nil,
        effectivenessRating: Double = 0,
        usageCount: Int = 0,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.brand = brand
        self.model = model
        self.photoData = photoData
        self.effectivenessRating = effectivenessRating
        self.usageCount = usageCount
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "type": type.rawValue,
            "brand": brand ?? "",
            "model": model ?? "",
            "photoData": photoData ?? "",
            "effectivenessRating": effectivenessRating,
            "usageCount": usageCount,
            "notes": notes ?? "",
            "createdAt": createdAt.timeIntervalSince1970,
            "updatedAt": updatedAt.timeIntervalSince1970
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> GearItem? {
        guard
            let id = dict["id"] as? String,
            let name = dict["name"] as? String,
            let typeString = dict["type"] as? String,
            let type = GearType(rawValue: typeString),
            let effectivenessRating = dict["effectivenessRating"] as? Double,
            let usageCount = dict["usageCount"] as? Int,
            let createdAtTimestamp = dict["createdAt"] as? TimeInterval,
            let updatedAtTimestamp = dict["updatedAt"] as? TimeInterval
        else {
            return nil
        }
        
        return GearItem(
            id: id,
            name: name,
            type: type,
            brand: dict["brand"] as? String,
            model: dict["model"] as? String,
            photoData: dict["photoData"] as? String,
            effectivenessRating: effectivenessRating,
            usageCount: usageCount,
            notes: dict["notes"] as? String,
            createdAt: Date(timeIntervalSince1970: createdAtTimestamp),
            updatedAt: Date(timeIntervalSince1970: updatedAtTimestamp)
        )
    }
}

struct Checklist: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var category: ChecklistCategory
    var items: [ChecklistItem]
    var createdAt: Date
    var updatedAt: Date
    var isTemplate: Bool
    
    enum ChecklistCategory: String, Codable, CaseIterable {
        case preparation = "Preparation"
        case packing = "Packing"
        case cleanup = "Cleanup"
        case custom = "Custom"
        
        var icon: String {
            switch self {
            case .preparation: return "list.clipboard"
            case .packing: return "bag.fill"
            case .cleanup: return "trash.fill"
            case .custom: return "star.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .preparation: return AppTheme.primaryAccent
            case .packing: return AppTheme.secondaryAccent
            case .cleanup: return AppTheme.success
            case .custom: return Color(hex: "FF6B35")
            }
        }
    }
    
    static func ==(lhs: Checklist, rhs: Checklist) -> Bool {
        lhs.id == rhs.id
    }
    
    var completionPercentage: Double {
        guard !items.isEmpty else { return 0 }
        let completed = items.filter { $0.isCompleted }.count
        return Double(completed) / Double(items.count) * 100
    }
    
    var isCompleted: Bool {
        !items.isEmpty && items.allSatisfy { $0.isCompleted }
    }
    
    init(
        id: String = UUID().uuidString,
        title: String,
        category: ChecklistCategory = .custom,
        items: [ChecklistItem] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isTemplate: Bool = false
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.items = items
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isTemplate = isTemplate
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "category": category.rawValue,
            "items": items.map { $0.toDictionary() },
            "createdAt": createdAt.timeIntervalSince1970,
            "updatedAt": updatedAt.timeIntervalSince1970,
            "isTemplate": isTemplate
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> Checklist? {
        guard
            let id = dict["id"] as? String,
            let title = dict["title"] as? String,
            let categoryString = dict["category"] as? String,
            let category = ChecklistCategory(rawValue: categoryString),
            let itemsArray = dict["items"] as? [[String: Any]],
            let createdAtTimestamp = dict["createdAt"] as? TimeInterval,
            let updatedAtTimestamp = dict["updatedAt"] as? TimeInterval,
            let isTemplate = dict["isTemplate"] as? Bool
        else {
            return nil
        }
        
        let items = itemsArray.compactMap { ChecklistItem.fromDictionary($0) }
        
        return Checklist(
            id: id,
            title: title,
            category: category,
            items: items,
            createdAt: Date(timeIntervalSince1970: createdAtTimestamp),
            updatedAt: Date(timeIntervalSince1970: updatedAtTimestamp),
            isTemplate: isTemplate
        )
    }
}

// ChecklistItem.swift
struct ChecklistItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    var text: String
    var isCompleted: Bool
    var priority: Priority?
    
    enum Priority: String, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: Color {
            switch self {
            case .low: return AppTheme.success
            case .medium: return AppTheme.warning
            case .high: return AppTheme.danger
            }
        }
    }
    
    init(
        id: String = UUID().uuidString,
        text: String,
        isCompleted: Bool = false,
        priority: Priority? = nil
    ) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.priority = priority
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "text": text,
            "isCompleted": isCompleted,
            "priority": priority?.rawValue ?? ""
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> ChecklistItem? {
        guard
            let id = dict["id"] as? String,
            let text = dict["text"] as? String,
            let isCompleted = dict["isCompleted"] as? Bool
        else {
            return nil
        }
        
        let priorityString = dict["priority"] as? String
        let priority = priorityString.flatMap { Priority(rawValue: $0) }
        
        return ChecklistItem(
            id: id,
            text: text,
            isCompleted: isCompleted,
            priority: priority
        )
    }
}

// NotePhoto.swift
struct NotePhoto: Identifiable, Codable {
    var id: String = UUID().uuidString
    var imageData: String // base64
    var caption: String?
    var timestamp: Date
    
    init(
        id: String = UUID().uuidString,
        imageData: String,
        caption: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.imageData = imageData
        self.caption = caption
        self.timestamp = timestamp
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "imageData": imageData,
            "caption": caption ?? "",
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> NotePhoto? {
        guard
            let id = dict["id"] as? String,
            let imageData = dict["imageData"] as? String,
            let timestampValue = dict["timestamp"] as? TimeInterval
        else {
            return nil
        }
        
        return NotePhoto(
            id: id,
            imageData: imageData,
            caption: dict["caption"] as? String,
            timestamp: Date(timeIntervalSince1970: timestampValue)
        )
    }
}

struct FishingNote: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var noteText: String
    var relatedFish: String?
    var location: String?
    var season: Season
    var tags: [String]
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // NEW: Extended properties
    var photos: [NotePhoto] // До 3 фото
    var gearUsed: [String] // IDs снастей
    var checklistId: String? // ID прикрепленного чек-листа
    
    static func == (lhs: FishingNote, rhs: FishingNote) -> Bool {
        lhs.id == rhs.id
    }
    
    enum Season: String, Codable, CaseIterable {
        case spring = "Spring"
        case summer = "Summer"
        case autumn = "Autumn"
        case winter = "Winter"
        
        var icon: String {
            switch self {
            case .spring: return "leaf.fill"
            case .summer: return "sun.max.fill"
            case .autumn: return "leaf"
            case .winter: return "snowflake"
            }
        }
        
        var color: Color {
            switch self {
            case .spring: return AppTheme.springColor
            case .summer: return AppTheme.summerColor
            case .autumn: return AppTheme.autumnColor
            case .winter: return AppTheme.winterColor
            }
        }
    }
    
    init(
        id: String = UUID().uuidString,
        title: String = "",
        noteText: String = "",
        relatedFish: String? = nil,
        location: String? = nil,
        season: Season = .spring,
        tags: [String] = [],
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        photos: [NotePhoto] = [],
        gearUsed: [String] = [],
        checklistId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.noteText = noteText
        self.relatedFish = relatedFish
        self.location = location
        self.season = season
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.photos = photos
        self.gearUsed = gearUsed
        self.checklistId = checklistId
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "noteText": noteText,
            "relatedFish": relatedFish ?? "",
            "location": location ?? "",
            "season": season.rawValue,
            "tags": tags,
            "isFavorite": isFavorite,
            "createdAt": createdAt.timeIntervalSince1970,
            "updatedAt": updatedAt.timeIntervalSince1970,
            "photos": photos.map { $0.toDictionary() },
            "gearUsed": gearUsed,
            "checklistId": checklistId ?? ""
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> FishingNote? {
        guard
            let id = dict["id"] as? String,
            let title = dict["title"] as? String,
            let noteText = dict["noteText"] as? String,
            let seasonString = dict["season"] as? String,
            let season = Season(rawValue: seasonString),
            let tags = dict["tags"] as? [String],
            let isFavorite = dict["isFavorite"] as? Bool,
            let createdAtTimestamp = dict["createdAt"] as? TimeInterval,
            let updatedAtTimestamp = dict["updatedAt"] as? TimeInterval
        else {
            return nil
        }
        
        let photosArray = dict["photos"] as? [[String: Any]] ?? []
        let photos = photosArray.compactMap { NotePhoto.fromDictionary($0) }
        
        let gearUsed = dict["gearUsed"] as? [String] ?? []
        
        return FishingNote(
            id: id,
            title: title,
            noteText: noteText,
            relatedFish: dict["relatedFish"] as? String,
            location: dict["location"] as? String,
            season: season,
            tags: tags,
            isFavorite: isFavorite,
            createdAt: Date(timeIntervalSince1970: createdAtTimestamp),
            updatedAt: Date(timeIntervalSince1970: updatedAtTimestamp),
            photos: photos,
            gearUsed: gearUsed,
            checklistId: dict["checklistId"] as? String
        )
    }
}

enum AppState: Equatable {
    case idle
    case loading
    case validating
    case validated
    case active(url: String)
    case inactive
    case offline
}

struct AttributionData {
    var data: [String: Any]
    
    var isEmpty: Bool {
        return data.isEmpty
    }
    
    var isOrganic: Bool {
        return data["af_status"] as? String == "Organic"
    }
    
    subscript(key: String) -> Any? {
        return data[key]
    }
}

struct DeeplinkData {
    var data: [String: Any]
    
    var isEmpty: Bool {
        return data.isEmpty
    }
    
    subscript(key: String) -> Any? {
        return data[key]
    }
}

struct AppConfiguration {
    var url: String?
    var mode: String?
    var isFirstLaunch: Bool
    var permissionGranted: Bool
    var permissionDenied: Bool
    var lastPermissionRequest: Date?
    
    var shouldShowPermissionPrompt: Bool {
        if permissionGranted || permissionDenied {
            return false
        }
        
        if let lastRequest = lastPermissionRequest {
            let daysSinceRequest = Date().timeIntervalSince(lastRequest) / 86400
            return daysSinceRequest >= 3
        }
        
        return true
    }
}
