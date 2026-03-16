import Foundation
import FirebaseFirestore

struct AdminAuditEvent: Identifiable {
    let id: String
    let action: String
    let entityType: String
    let entityId: String?
    let timestamp: Date
    let userId: String
    let userEmail: String
    let metadata: [String: String]

    init?(document: QueryDocumentSnapshot) {
        let data = document.data()

        guard
            let action = data["action"] as? String,
            let entityType = data["entityType"] as? String,
            let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
            let userId = data["userId"] as? String
        else {
            return nil
        }

        self.id = document.documentID
        self.action = action
        self.entityType = entityType
        self.entityId = data["entityId"] as? String
        self.timestamp = timestamp
        self.userId = userId
        self.userEmail = data["userEmail"] as? String ?? ""
        self.metadata = AdminAuditEvent.stringifyMetadata(data["metadata"] as? [String: Any] ?? [:])
    }

    var normalizedAction: String {
        action.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var normalizedEntityType: String {
        entityType.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private static func stringifyMetadata(_ metadata: [String: Any]) -> [String: String] {
        var formatted: [String: String] = [:]

        for (key, value) in metadata {
            switch value {
            case let text as String:
                formatted[key] = text
            case let number as NSNumber:
                formatted[key] = number.stringValue
            case let array as [String]:
                formatted[key] = array.joined(separator: ", ")
            case let array as [Any]:
                formatted[key] = array.map { String(describing: $0) }.joined(separator: ", ")
            default:
                formatted[key] = String(describing: value)
            }
        }

        return formatted
    }
}

@MainActor
final class AdminAuditLogService: ObservableObject {
    @Published private(set) var logs: [AdminAuditEvent] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func fetchLogs(limit: Int = 100) async {
        isLoading = true
        errorMessage = nil

        do {
            let snapshot = try await db.collection("audit_logs")
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .getDocuments()

            logs = snapshot.documents.compactMap(AdminAuditEvent.init(document:))
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
