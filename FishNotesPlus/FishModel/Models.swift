import Foundation
import FirebaseDatabase
import SwiftUI

struct FishingNote: Identifiable, Codable {
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
            case .spring: return Color(hex: "8BC34A")
            case .summer: return Color(hex: "FFC107")
            case .autumn: return Color(hex: "FF6F00")
            case .winter: return Color(hex: "03A9F4")
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
        updatedAt: Date = Date()
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
            "updatedAt": updatedAt.timeIntervalSince1970
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
            updatedAt: Date(timeIntervalSince1970: updatedAtTimestamp)
        )
    }
}
