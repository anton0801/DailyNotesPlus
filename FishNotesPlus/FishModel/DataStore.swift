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

// MARK: - Storage Service
protocol StorageServiceProtocol {
    func saveAttribution(_ data: [String: Any])
    func loadAttribution() -> [String: Any]
    func saveDeeplink(_ data: [String: Any])
    func loadDeeplink() -> [String: Any]
    func saveURL(_ url: String)
    func loadURL() -> String?
    func saveMode(_ mode: String)
    func loadMode() -> String?
    func saveFirstLaunch(_ value: Bool)
    func isFirstLaunch() -> Bool
    func savePermissionGranted(_ value: Bool)
    func isPermissionGranted() -> Bool
    func savePermissionDenied(_ value: Bool)
    func isPermissionDenied() -> Bool
    func saveLastPermissionRequest(_ date: Date)
    func loadLastPermissionRequest() -> Date?
}

final class StorageService: StorageServiceProtocol {
    
    private let defaults = UserDefaults.standard
    private var attributionCache: [String: Any] = [:]
    private var deeplinkCache: [String: Any] = [:]
    
    func saveAttribution(_ data: [String: Any]) {
        attributionCache = data
    }
    
    func loadAttribution() -> [String: Any] {
        return attributionCache
    }
    
    func saveDeeplink(_ data: [String: Any]) {
        deeplinkCache = data
    }
    
    func loadDeeplink() -> [String: Any] {
        return deeplinkCache
    }
    
    func saveURL(_ url: String) {
        defaults.set(url, forKey: "cached_endpoint")
    }
    
    func loadURL() -> String? {
        return defaults.string(forKey: "cached_endpoint")
    }
    
    func saveMode(_ mode: String) {
        defaults.set(mode, forKey: "app_status")
    }
    
    func loadMode() -> String? {
        return defaults.string(forKey: "app_status")
    }
    
    func saveFirstLaunch(_ value: Bool) {
        defaults.set(value, forKey: "launchedBefore")
    }
    
    func isFirstLaunch() -> Bool {
        return !defaults.bool(forKey: "launchedBefore")
    }
    
    func savePermissionGranted(_ value: Bool) {
        defaults.set(value, forKey: "permissions_accepted")
    }
    
    func isPermissionGranted() -> Bool {
        return defaults.bool(forKey: "permissions_accepted")
    }
    
    func savePermissionDenied(_ value: Bool) {
        defaults.set(value, forKey: "permissions_denied")
    }
    
    func isPermissionDenied() -> Bool {
        return defaults.bool(forKey: "permissions_denied")
    }
    
    func saveLastPermissionRequest(_ date: Date) {
        defaults.set(date, forKey: "permission_request_time")
    }
    
    func loadLastPermissionRequest() -> Date? {
        return defaults.object(forKey: "permission_request_time") as? Date
    }
}

protocol NetworkServiceProtocol {
    func fetchAttribution(deviceID: String) async throws -> [String: Any]
    func fetchURL(attribution: [String: Any]) async throws -> String
}

final class NetworkService: NetworkServiceProtocol {
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchAttribution(deviceID: String) async throws -> [String: Any] {
        let urlString = "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(Config.appsFlyerId)?devkey=\(Config.appsFlyerKey)&device_id=\(deviceID)"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let request = URLRequest(url: url, timeoutInterval: 30)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NetworkError.invalidResponse
        }
        
        return json
    }
    
    private var user: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func fetchURL(attribution: [String: Any]) async throws -> String {
        guard let url = URL(string: Config.end) else {
            throw NetworkError.invalidURL
        }
        
        var payload = attribution
        payload["os"] = "iOS"
        payload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        payload["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        payload["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        payload["store_id"] = "id\(Config.appsFlyerId)"
        payload["push_token"] = UserDefaults.standard.string(forKey: "push_token") ?? Messaging.messaging().fcmToken
        payload["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(user, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, _) = try await session.data(for: request)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["ok"] as? Bool,
              success,
              let resultURL = json["url"] as? String else {
            throw NetworkError.invalidResponse
        }
        
        return resultURL
    }
}

enum NetworkError: Error {
    case invalidURL
    case serverError
    case invalidResponse
}
