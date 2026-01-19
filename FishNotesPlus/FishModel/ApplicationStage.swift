
import Foundation
import Combine
import Firebase
import FirebaseDatabase

enum ApplicationStage: Equatable {
    case dormant
    case starting
    case verifying
    case authorized
    case running(destination: String)
    case paused
    case offline
}

enum StreamEvent {
    case boot
    case dataIngested([String: Any])
    case validationPassed
    case validationRejected
    case destinationFound(String)
    case connectivityLost
    case connectivityRestored
    case timeout
}

final class StageMachine {
    
    private let eventSubject = PassthroughSubject<StreamEvent, Never>()
    private let stageSubject = CurrentValueSubject<ApplicationStage, Never>(.dormant)
    
    private var cancellables = Set<AnyCancellable>()
    
    var stagePublisher: AnyPublisher<ApplicationStage, Never> {
        stageSubject.eraseToAnyPublisher()
    }
    
    var currentStage: ApplicationStage {
        stageSubject.value
    }
    
    init() {
        setupStream()
    }
    
    func emit(_ event: StreamEvent) {
        eventSubject.send(event)
    }
    
    private func setupStream() {
        eventSubject
            .map { [weak self] event -> ApplicationStage? in
                guard let self = self else { return nil }
                return self.transform(event: event, from: self.currentStage)
            }
            .compactMap { $0 }
            .sink { [weak self] newStage in
                self?.stageSubject.send(newStage)
            }
            .store(in: &cancellables)
    }
    
    private func transform(event: StreamEvent, from stage: ApplicationStage) -> ApplicationStage? {
        switch (stage, event) {
        case (.dormant, .boot):
            return .starting
            
        case (.starting, .dataIngested):
            return .verifying
            
        case (.verifying, .validationPassed):
            return .authorized
            
        case (.verifying, .validationRejected):
            return .paused
            
        case (.authorized, .destinationFound(let destination)):
            return .running(destination: destination)
            
        case (_, .connectivityLost) where !stage.isFinal:
            return .offline
            
        case (.offline, .connectivityRestored):
            return .paused
            
        case (_, .timeout) where !stage.isFinal:
            return .paused
            
        default:
            return nil
        }
    }
}

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

final class FirebaseValidationGateway: ValidationGateway {
    
    private let reference = "users/log/data"
    
    func checkAccess() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            Database.database().reference().child(reference)
                .observeSingleEvent(of: .value) { snapshot in
                    if let value = snapshot.value as? String,
                       !value.isEmpty,
                       URL(string: value) != nil {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
}

// MARK: - Validation Error
enum ValidationError: Error {
    case accessDenied
    case gatewayFailure
}
