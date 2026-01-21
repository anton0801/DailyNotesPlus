import Foundation

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
