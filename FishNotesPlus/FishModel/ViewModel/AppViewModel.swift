import Foundation
import Combine
import UIKit
import UserNotifications
import Network
import AppsFlyerLib

@MainActor
final class AppViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var state: AppState = .idle
    @Published private(set) var targetURL: String?
    @Published var showPermissionPrompt: Bool = false
    
    // MARK: - Private Properties
    private let storageService: StorageServiceProtocol
    private let validationService: ValidationServiceProtocol
    private let networkService: NetworkServiceProtocol
    
    private var attributionData = AttributionData(data: [:])
    private var deeplinkData = DeeplinkData(data: [:])
    private var configuration = AppConfiguration(
        url: nil,
        mode: nil,
        isFirstLaunch: true,
        permissionGranted: false,
        permissionDenied: false,
        lastPermissionRequest: nil
    )
    
    private var cancellables = Set<AnyCancellable>()
    private var timeoutTask: Task<Void, Never>?
    private var isLocked = false
    
    private let networkMonitor = NWPathMonitor()
    
    // MARK: - Initialization
    init(
        storageService: StorageServiceProtocol = StorageService(),
        validationService: ValidationServiceProtocol = ValidationService(),
        networkService: NetworkServiceProtocol = NetworkService()
    ) {
        self.storageService = storageService
        self.validationService = validationService
        self.networkService = networkService
        
        
        
//        loadConfiguration()
//        setupNetworkMonitoring()
        bootstrap()
    }
    
    // MARK: - Public Methods
    func handleAttribution(_ data: [String: Any]) {
        attributionData = AttributionData(data: data)
        storageService.saveAttribution(data)
        
        Task {
            await performValidation()
        }
    }
    
    func handleDeeplink(_ data: [String: Any]) {
        deeplinkData = DeeplinkData(data: data)
        storageService.saveDeeplink(data)
    }
    
    func grantPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            Task { @MainActor in
                self?.storageService.savePermissionGranted(granted)
                self?.storageService.savePermissionDenied(!granted)
                self?.configuration.permissionGranted = granted
                self?.configuration.permissionDenied = !granted
                
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                
                self?.showPermissionPrompt = false
            }
        }
    }
    
    func denyPermission() {
        storageService.saveLastPermissionRequest(Date())
        configuration.lastPermissionRequest = Date()
        showPermissionPrompt = false
    }
    
    private func loadConfiguration() {
        configuration = AppConfiguration(
            url: storageService.loadURL(),
            mode: storageService.loadMode(),
            isFirstLaunch: storageService.isFirstLaunch(),
            permissionGranted: storageService.isPermissionGranted(),
            permissionDenied: storageService.isPermissionDenied(),
            lastPermissionRequest: storageService.loadLastPermissionRequest()
        )
    }
    
    private func bootstrap() {
        state = .loading
        scheduleTimeout()
    }
    
    private func scheduleTimeout() {
        timeoutTask = Task {
            // time changable
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            if !isLocked {
                await MainActor.run {
                    self.state = .inactive
                }
            }
        }
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self = self, !self.isLocked else { return }
                
                if path.status == .satisfied {
                    if self.state == .offline {
                        self.state = .inactive
                    }
                } else {
                    self.state = .offline
                }
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
    private func performValidation() async {
        if targetURL == nil {
            state = .validating
            
            do {
                let isValid = try await validationService.validate()
                
                if isValid {
                    state = .validated
                    await continueFlow()
                } else {
                    state = .inactive
                }
            } catch {
                state = .inactive
            }
        }
    }
    
    private func continueFlow() async {
        if attributionData.isEmpty {
            loadCachedURL()
            return
        }
        
        if configuration.mode == "Inactive" {
            state = .inactive
            return
        }
        
        if shouldPerformFirstLaunch() {
            await performFirstLaunch()
            return
        }
        
        if let tempURL = UserDefaults.standard.string(forKey: "temp_url") {
            activateWithURL(tempURL)
            return
        }
        
        await resolveURL()
    }
    
    private func activateWithURL(_ url: String) {
        guard !isLocked else { return }
        
        timeoutTask?.cancel()
        targetURL = url
        state = .active(url: url)
        isLocked = true
        
        if configuration.shouldShowPermissionPrompt {
            showPermissionPrompt = true
        }
    }
    
    private func shouldPerformFirstLaunch() -> Bool {
        return configuration.isFirstLaunch && attributionData.isOrganic
    }
    
    private func performFirstLaunch() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        do {
            let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
            let fetchedAttribution = try await networkService.fetchAttribution(deviceID: deviceID)
            
            var mergedData = fetchedAttribution
            for (key, value) in deeplinkData.data {
                if mergedData[key] == nil {
                    mergedData[key] = value
                }
            }
            
            attributionData = AttributionData(data: mergedData)
            storageService.saveAttribution(mergedData)
            
            await resolveURL()
        } catch {
            state = .inactive
        }
    }
    
    private func resolveURL() async {
        do {
            let url = try await networkService.fetchURL(attribution: attributionData.data)
            
            storageService.saveURL(url)
            storageService.saveMode("Active")
            storageService.saveFirstLaunch(true)
            
            configuration.url = url
            configuration.mode = "Active"
            configuration.isFirstLaunch = false
            
            activateWithURL(url)
        } catch {
            loadCachedURL()
        }
    }
    
    private func loadCachedURL() {
        if let cachedURL = configuration.url {
            activateWithURL(cachedURL)
        } else {
            state = .inactive
        }
    }
    
}
