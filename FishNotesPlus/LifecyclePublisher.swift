import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import Combine
import AppsFlyerLib

final class LifecyclePublisher: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    private let eventPublisher = EventPublisher()
    private let messageProcessor = MessageProcessor()
    private let attributionBridge = AttributionBridge()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        bootstrapApplication()
        wireUpDelegation()
        registerForNotifications()
        
        if let message = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            messageProcessor.handle(message)
        }
        
        attributionBridge.configure(
            onAttributionSuccess: { [weak self] data in
                self?.eventPublisher.publishAttributionData(data)
            },
            onDeeplinkSuccess: { [weak self] data in
                self?.eventPublisher.publishDeeplinkData(data)
            },
            onFailure: { [weak self] in
                self?.eventPublisher.publishAttributionData([:])
            }
        )
        
        watchLifecycleEvents()
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    private func bootstrapApplication() {
        FirebaseApp.configure()
    }
    
    private func wireUpDelegation() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }
    
    private func registerForNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private func watchLifecycleEvents() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleActivation() {
        attributionBridge.activate()
    }
    
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, error in
            guard error == nil, let token = token else { return }
            TokenCache.shared.store(token)
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        messageProcessor.handle(notification.request.content.userInfo)
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        messageProcessor.handle(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        messageProcessor.handle(userInfo)
        completionHandler(.newData)
    }
    
}

final class EventPublisher {
    
    private var attributionData: [AnyHashable: Any] = [:]
    private var deeplinkData: [AnyHashable: Any] = [:]
    private var mergeTimer: Timer?
    private let publishedKey = "trackingDataSent"
    
    func publishAttributionData(_ data: [AnyHashable: Any]) {
        attributionData = data
        
//        scheduleMerge()
//        
//        if !deeplinkData.isEmpty {
//            mergeAndPublish()
//        }
    }
    
    func publishDeeplinkData(_ data: [AnyHashable: Any]) {
        deeplinkData = data
        
//        emitDeeplink(data)
//        
//        cancelMerge()
//        
//        if !attributionData.isEmpty {
//            mergeAndPublish()
//        }
    }
    
    private func scheduleMerge() {
        mergeTimer?.invalidate()
        
        mergeTimer = Timer.scheduledTimer(
            withTimeInterval: 3.0,
            repeats: false
        ) { [weak self] _ in
            self?.mergeAndPublish()
        }
    }
    
    private func cancelMerge() {
        mergeTimer?.invalidate()
    }
    
    private func mergeAndPublish() {
        var merged = attributionData
        
        deeplinkData.forEach { key, value in
            if merged[key] == nil {
                merged[key] = value
            }
        }
        
        emitAttribution(merged)
        markPublished()
    }
    
    private func emitAttribution(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": data]
        )
    }
    
    private func emitDeeplink(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("deeplink_values"),
            object: nil,
            userInfo: ["deeplinksData": data]
        )
    }
    
    private func wasPublished() -> Bool {
        return UserDefaults.standard.bool(forKey: publishedKey)
    }
    
    private func markPublished() {
        UserDefaults.standard.set(true, forKey: publishedKey)
    }
}



final class AttributionBridge: NSObject {
    
    private var onAttributionSuccess: (([AnyHashable: Any]) -> Void)?
    private var onDeeplinkSuccess: (([AnyHashable: Any]) -> Void)?
    private var onFailure: (() -> Void)?
    
    func configure(
        onAttributionSuccess: @escaping ([AnyHashable: Any]) -> Void,
        onDeeplinkSuccess: @escaping ([AnyHashable: Any]) -> Void,
        onFailure: @escaping () -> Void
    ) {
        self.onAttributionSuccess = onAttributionSuccess
        self.onDeeplinkSuccess = onDeeplinkSuccess
        self.onFailure = onFailure
        
        initializeSDK()
    }
    
    private func initializeSDK() {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = Config.appsFlyerKey
        sdk.appleAppID = Config.appsFlyerId
        sdk.delegate = self
        sdk.deepLinkDelegate = self
    }
    
    func activate() {
        if #available(iOS 14.0, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
}

extension AttributionBridge: AppsFlyerLibDelegate {
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        onAttributionSuccess?(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        onFailure?()
    }
}

extension AttributionBridge: DeepLinkDelegate {
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status,
              let deeplink = result.deepLink else {
            return
        }
        
        onDeeplinkSuccess?(deeplink.clickEvent)
    }
}

final class MessageProcessor {
    
    func handle(_ payload: [AnyHashable: Any]) {
        guard let urlString = extractURL(from: payload) else {
            return
        }
        
        UserDefaults.standard.set(urlString, forKey: "temp_url")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            NotificationCenter.default.post(
                name: Notification.Name("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": urlString]
            )
        }
    }
    
    private func extractURL(from payload: [AnyHashable: Any]) -> String? {
        // First level
        if let url = payload["url"] as? String {
            return url
        }
        
        // Second level
        if let data = payload["data"] as? [String: Any],
           let url = data["url"] as? String {
            return url
        }
        
        return nil
    }
}

// MARK: - Token Cache
final class TokenCache {
    
    static let shared = TokenCache()
    
    private init() {}
    
    func store(_ token: String) {
        let defaults = UserDefaults.standard
        defaults.set(token, forKey: "fcm_token")
        defaults.set(token, forKey: "push_token")
    }
    
    func fetch() -> String? {
        return UserDefaults.standard.string(forKey: "push_token")
    }
}
