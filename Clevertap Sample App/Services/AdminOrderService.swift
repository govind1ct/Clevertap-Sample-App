import Foundation
import FirebaseFirestore

@MainActor
final class AdminOrderService: ObservableObject {
    @Published private(set) var orders: [Order] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func fetchOrders() async {
        isLoading = true
        errorMessage = nil

        do {
            let snapshot = try await db.collection("orders")
                .order(by: "createdAt", descending: true)
                .getDocuments()

            orders = snapshot.documents.compactMap { try? $0.data(as: Order.self) }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func updateOrderStatus(order: Order, status: String) async {
        guard let orderId = order.id else { return }

        do {
            try await updateOrderStatus(orderId: orderId, userId: order.userId, status: status)
            AdminAuditLogger.log(
                action: "order_status_update",
                entityType: "order",
                entityId: orderId,
                metadata: [
                    "status": status,
                    "userId": order.userId,
                    "userEmail": order.userEmail ?? ""
                ]
            )
            await fetchOrders()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateOrderStatus(orderId: String, userId: String, status: String) async throws {
        let updates: [String: Any] = [
            "status": status,
            "updatedAt": Timestamp(date: Date())
        ]

        let batch = db.batch()
        let globalRef = db.collection("orders").document(orderId)
        let userRef = db.collection("users").document(userId).collection("orders").document(orderId)

        batch.updateData(updates, forDocument: globalRef)
        batch.updateData(updates, forDocument: userRef)
        try await batch.commit()
    }
}
