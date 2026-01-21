import Foundation
import SwiftUI
import Network

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
