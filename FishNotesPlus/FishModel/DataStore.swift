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

// MARK: - Local Data Store
final class LocalDataStore: DataStore {
    
    private let storage = UserDefaults.standard
    private var attributionMemory: [String: Any] = [:]
    private var deeplinkMemory: [String: Any] = [:]
    
    private enum StorageKey {
        static let destination = "cached_endpoint"
        static let status = "app_status"
        static let firstTime = "launchedBefore"
        static let permissionRequest = "permission_request_time"
        static let permissionGranted = "permissions_accepted"
        static let permissionDenied = "permissions_denied"
    }
    
    func storeAttribution(_ data: [String: Any]) {
        attributionMemory = data
    }
    
    func storeDeeplink(_ data: [String: Any]) {
        deeplinkMemory = data
    }
    
    func getAttribution() -> [String: Any] {
        return attributionMemory
    }
    
    func getDeeplink() -> [String: Any] {
        return deeplinkMemory
    }
    
    func cacheDestination(_ destination: String) {
        storage.set(destination, forKey: StorageKey.destination)
    }
    
    func getCachedDestination() -> String? {
        return storage.string(forKey: StorageKey.destination)
    }
    
    func setStatus(_ status: String) {
        storage.set(status, forKey: StorageKey.status)
    }
    
    func getStatus() -> String? {
        return storage.string(forKey: StorageKey.status)
    }
    
    func isFirstTime() -> Bool {
        return !storage.bool(forKey: StorageKey.firstTime)
    }
    
    func markFirstTimeComplete() {
        storage.set(true, forKey: StorageKey.firstTime)
    }
    
    func recordPermissionDismissal(_ date: Date) {
        storage.set(date, forKey: StorageKey.permissionRequest)
    }
    
    func getLastPermissionRequest() -> Date? {
        return storage.object(forKey: StorageKey.permissionRequest) as? Date
    }
    
    func savePermissionState(granted: Bool, denied: Bool) {
        storage.set(granted, forKey: StorageKey.permissionGranted)
        storage.set(denied, forKey: StorageKey.permissionDenied)
    }
    
    func wasPermissionGranted() -> Bool {
        return storage.bool(forKey: StorageKey.permissionGranted)
    }
    
    func wasPermissionDenied() -> Bool {
        return storage.bool(forKey: StorageKey.permissionDenied)
    }
}

protocol APIClient {
    func fetchAttribution(deviceID: String) async throws -> [String: Any]
    func resolveDestination(attribution: [String: Any]) async throws -> String
}

final class HTTPAPIClient: APIClient {
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchAttribution(deviceID: String) async throws -> [String: Any] {
        let url = try constructAttributionURL(deviceID: deviceID)
        let request = URLRequest(url: url, timeoutInterval: 30)
        
        let (data, response) = try await session.data(for: request)
        try validateHTTPResponse(response)
        
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
    
    func resolveDestination(attribution: [String: Any]) async throws -> String {
        let url = URL(string: Config.end)!
        let payload = assemblePayload(from: attribution)
        let request = try constructPOSTRequest(url: url, payload: payload)
        
        let (data, _) = try await session.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        guard let success = json["ok"] as? Bool, success,
              let destination = json["url"] as? String else {
            throw APIError.invalidDestination
        }
        
        return destination
    }
    
    private func constructAttributionURL(deviceID: String) throws -> URL {
        let baseURL = "https://gcdsdk.appsflyer.com/install_data/v4.0/"
        let appIdentifier = "id\(Config.appsFlyerId)"
        
        guard var components = URLComponents(string: baseURL + appIdentifier) else {
            throw APIError.malformedURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "devkey", value: Config.appsFlyerKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        
        guard let url = components.url else {
            throw APIError.malformedURL
        }
        
        return url
    }
    
    private var user: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    private func assemblePayload(from data: [String: Any]) -> [String: Any] {
        var payload = data
        
        payload["os"] = "iOS"
        payload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        payload["bundle_id"] = SystemInfo.bundleIdentifier
        payload["firebase_project_id"] = SystemInfo.firebaseProjectID
        payload["store_id"] = SystemInfo.storeIdentifier
        payload["push_token"] = SystemInfo.notificationToken
        payload["locale"] = SystemInfo.localeCode
        
        return payload
    }
    
    private func constructPOSTRequest(url: URL, payload: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(user, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        return request
    }
    
    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw APIError.serverError
        }
    }
}

enum APIError: Error {
    case malformedURL
    case serverError
    case invalidDestination
}

struct SystemInfo {
    
    static var bundleIdentifier: String {
        return Config.bundle
    }
    
    static var firebaseProjectID: String? {
        return FirebaseApp.app()?.options.gcmSenderID
    }
    
    static var storeIdentifier: String {
        return "id\(Config.appsFlyerId)"
    }
    
    static var notificationToken: String? {
        if let saved = UserDefaults.standard.string(forKey: "push_token") {
            return saved
        }
        return Messaging.messaging().fcmToken
    }
    
    static var localeCode: String {
        return Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
    }
}
