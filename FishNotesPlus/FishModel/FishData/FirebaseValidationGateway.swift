import Foundation
import Firebase
import FirebaseDatabase

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
