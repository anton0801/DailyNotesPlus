import Foundation
import AppsFlyerLib
import WebKit

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
