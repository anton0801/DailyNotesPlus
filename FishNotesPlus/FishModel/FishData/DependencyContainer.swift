import Foundation
import Combine
import Network
import UIKit
import UserNotifications
import AppsFlyerLib

final class DependencyContainer {
    
    let dataStore: DataStore
    let apiClient: APIClient
    var networkWatcher: NetworkWatcher
    
    init(
        dataStore: DataStore = LocalDataStore(),
        apiClient: APIClient = HTTPAPIClient(),
        networkWatcher: NetworkWatcher = PathWatcher()
    ) {
        self.dataStore = dataStore
        self.apiClient = apiClient
        self.networkWatcher = networkWatcher
    }
}

@MainActor
final class ApplicationCoordinator: ObservableObject {
    
    @Published private(set) var presentationState: PresentationState = .initializing
    @Published private(set) var endpoint: String?
    @Published private(set) var requestingPermission = false
    
    private let stageMachine = StageMachine()
    private var dependencies: DependencyContainer
    
    private var subscriptions = Set<AnyCancellable>()
    private var timeoutWork: DispatchWorkItem?
    private var isLocked = false
    
    init(dependencies: DependencyContainer = DependencyContainer()) {
        self.dependencies = dependencies
        
        bindStageChanges()
        monitorNetworkChanges()
        startBootSequence()
    }
    
    func ingest(attribution: [String: Any]) {
        dependencies.dataStore.storeAttribution(attribution)
        stageMachine.emit(.dataIngested(attribution))
        
        Task {
            await executeValidationFlow()
        }
    }
    
    func ingest(deeplink: [String: Any]) {
        dependencies.dataStore.storeDeeplink(deeplink)
    }
    
    func rejectPermission() {
        dependencies.dataStore.recordPermissionDismissal(Date())
        requestingPermission = false
        finalizeActivation()
    }
    
    func grantPermission() {
        requestPermissionAuthorization { [weak self] granted in
            Task { @MainActor in
                guard let self = self else { return }
                
                self.dependencies.dataStore.savePermissionState(granted: granted, denied: !granted)
                
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                
                self.requestingPermission = false
                self.finalizeActivation()
            }
        }
    }
    
    // MARK: - Private Setup
    
    private func bindStageChanges() {
        stageMachine.stagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stage in
                self?.handleStageTransition(stage)
            }
            .store(in: &subscriptions)
    }
    
    private func handleStageTransition(_ stage: ApplicationStage) {
        guard !isLocked else { return }
        
        switch stage {
        case .dormant, .starting, .verifying, .authorized:
            presentationState = .initializing
            
        case .running(let destination):
            endpoint = destination
            presentationState = .active
            isLocked = true
            
        case .paused:
            presentationState = .standby
            
        case .offline:
            presentationState = .disconnected
        }
    }
    
    private func monitorNetworkChanges() {
        dependencies.networkWatcher.onChange = { [weak self] connected in
            guard let self = self, !self.isLocked else { return }
            
            if connected {
                self.stageMachine.emit(.connectivityRestored)
            } else {
                self.stageMachine.emit(.connectivityLost)
            }
        }
        dependencies.networkWatcher.start()
    }
    
    private func startBootSequence() {
        stageMachine.emit(.boot)
        scheduleTimeoutHandler()
    }
    
    private func scheduleTimeoutHandler() {
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, !self.isLocked else { return }
            self.stageMachine.emit(.timeout)
        }
        
        timeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: work)
    }
    
    // MARK: - Validation Flow
    
    private func executeValidationFlow() async {
        let gateway = FirebaseValidationGateway()
        
        do {
            let hasAccess = try await gateway.checkAccess()
            
            if hasAccess {
                stageMachine.emit(.validationPassed)
                await continueFlow()
            } else {
                stageMachine.emit(.validationRejected)
            }
        } catch {
            stageMachine.emit(.validationRejected)
        }
    }
    
    private func continueFlow() async {
        if let temp = loadTemporaryDestination() {
            activate(destination: temp)
            return
        }
        
        let attribution = dependencies.dataStore.getAttribution()
        
        guard !attribution.isEmpty else {
            loadCachedDestination()
            return
        }
        
        if dependencies.dataStore.getStatus() == "Inactive" {
            stageMachine.emit(.timeout)
            return
        }
        
        if shouldExecuteFirstTime() {
            await executeFirstTimeFlow()
            return
        }
        
        await resolveDestination()
    }
    
    private func shouldExecuteFirstTime() -> Bool {
        return dependencies.dataStore.isFirstTime() &&
               dependencies.dataStore.getAttribution()["af_status"] as? String == "Organic"
    }
    
    private func executeFirstTimeFlow() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        do {
            let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
            let attribution = try await dependencies.apiClient.fetchAttribution(deviceID: deviceID)
            
            var merged = attribution
            let deeplink = dependencies.dataStore.getDeeplink()
            deeplink.forEach { key, value in
                if merged[key] == nil {
                    merged[key] = value
                }
            }
            
            dependencies.dataStore.storeAttribution(merged)
            await resolveDestination()
        } catch {
            stageMachine.emit(.timeout)
        }
    }
    
    private func loadTemporaryDestination() -> String? {
        return UserDefaults.standard.string(forKey: "temp_url")
    }
    
    private func resolveDestination() async {
        do {
            let attribution = dependencies.dataStore.getAttribution()
            let destination = try await dependencies.apiClient.resolveDestination(attribution: attribution)
            
            dependencies.dataStore.cacheDestination(destination)
            dependencies.dataStore.setStatus("Active")
            dependencies.dataStore.markFirstTimeComplete()
            
            activate(destination: destination)
        } catch {
            loadCachedDestination()
        }
    }
    
    private func loadCachedDestination() {
        if let cached = dependencies.dataStore.getCachedDestination() {
            activate(destination: cached)
        } else {
            stageMachine.emit(.timeout)
        }
    }
    
    private func activate(destination: String) {
        guard !isLocked else { return }
        
        stageMachine.emit(.destinationFound(destination))
        
        if shouldShowPermissionRequest() {
            requestingPermission = true
        }
    }
    
    private func shouldShowPermissionRequest() -> Bool {
        if dependencies.dataStore.wasPermissionGranted() || 
           dependencies.dataStore.wasPermissionDenied() {
            return false
        }
        
        if let lastRequest = dependencies.dataStore.getLastPermissionRequest(),
           Date().timeIntervalSince(lastRequest) < 259200 {
            return false
        }
        
        return true
    }
    
    private func finalizeActivation() {
        // Already handled by stage machine
    }
    
    private func requestPermissionAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            completion(granted)
        }
    }
}

// MARK: - Presentation State
enum PresentationState {
    case initializing
    case active
    case standby
    case disconnected
}

// MARK: - Network Watcher Protocol
protocol NetworkWatcher {
    var onChange: ((Bool) -> Void)? { get set }
    func start()
    func stop()
}

// MARK: - Path Watcher
final class PathWatcher: NetworkWatcher {
    
    private let monitor = NWPathMonitor()
    var onChange: ((Bool) -> Void)?
    
    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            self?.onChange?(isConnected)
        }
        monitor.start(queue: .global(qos: .background))
    }
    
    func stop() {
        monitor.cancel()
    }
}
