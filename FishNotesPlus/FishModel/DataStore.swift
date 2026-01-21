import Foundation
import AppsFlyerLib
import Firebase
import WebKit
import FirebaseMessaging

struct Config {
    static let appsFlyerKey = "B2FwkD3tj9TouMN5258CV7"
    static let appsFlyerId = "6757920328"
    static let bundle = "com.sdadplusnott.FishNotesPlus"
    static let end = "https://dailynotesplus.com/config.php"
}

protocol DataStore {
    func storeAttribution(_ data: [String: Any])
    func storeDeeplink(_ data: [String: Any])
    func getAttribution() -> [String: Any]
    func getDeeplink() -> [String: Any]
    func cacheDestination(_ destination: String)
    func getCachedDestination() -> String?
    func setStatus(_ status: String)
    func getStatus() -> String?
    func isFirstTime() -> Bool
    func markFirstTimeComplete()
    func recordPermissionDismissal(_ date: Date)
    func getLastPermissionRequest() -> Date?
    func savePermissionState(granted: Bool, denied: Bool)
    func wasPermissionGranted() -> Bool
    func wasPermissionDenied() -> Bool
}

protocol APIClient {
    func fetchAttribution(deviceID: String) async throws -> [String: Any]
    func resolveDestination(attribution: [String: Any]) async throws -> String
}

enum APIError: Error {
    case malformedURL
    case serverError
    case invalidDestination
}

struct SystemInfo {
    
    static var notificationToken: String? {
        if let saved = UserDefaults.standard.string(forKey: "push_token") {
            return saved
        }
        return Messaging.messaging().fcmToken
    }
    
    static var bundleIdentifier: String {
        return Config.bundle
    }
    
    
    static var localeCode: String {
        return Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
    }
    
    static var firebaseProjectID: String? {
        return FirebaseApp.app()?.options.gcmSenderID
    }
    
    static var storeIdentifier: String {
        return "id\(Config.appsFlyerId)"
    }
    
}
