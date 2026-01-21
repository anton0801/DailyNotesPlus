
import Foundation
import Combine
import Firebase
import FirebaseDatabase


extension ApplicationStage {
    var isFinal: Bool {
        switch self {
        case .running, .paused:
            return true
        default:
            return false
        }
    }
}

protocol ValidationGateway {
    func checkAccess() async throws -> Bool
}

// MARK: - Validation Error
enum ValidationError: Error {
    case accessDenied
    case gatewayFailure
}
