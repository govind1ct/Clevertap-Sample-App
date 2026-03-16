import Foundation
import FirebaseAuth
import FirebaseFirestore

struct AdminAuditLogger {
    static func log(action: String, entityType: String, entityId: String?, metadata: [String: Any] = [:]) {
        guard let user = Auth.auth().currentUser else { return }

        var payload: [String: Any] = [
            "action": action,
            "entityType": entityType,
            "timestamp": Date(),
            "userId": user.uid,
            "userEmail": user.email ?? ""
        ]

        if let entityId, !entityId.isEmpty {
            payload["entityId"] = entityId
        }

        if !metadata.isEmpty {
            payload["metadata"] = metadata
        }

        Firestore.firestore().collection("audit_logs").addDocument(data: payload)
    }
}
