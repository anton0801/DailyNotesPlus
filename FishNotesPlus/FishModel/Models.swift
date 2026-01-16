import SwiftUI

let backgroundColor = Color(red: 0.98, green: 0.96, blue: 0.94) // Light beige
let accentBlue = Color.blue
let accentGreen = Color.green

// Note model
struct Note: Identifiable, Codable {
    let id: UUID = UUID()
    var title: String
    var text: String
    var date: Date = Date()
    var relatedFish: String?
    var location: String?
    var season: Season
    var tags: [String]
    var isFavorite: Bool = false
}

enum Season: String, Codable {
    case spring, summer, autumn, winter
}
