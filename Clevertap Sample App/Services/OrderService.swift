import Foundation
import FirebaseFirestore

import FirebaseAuth

class OrderService: ObservableObject {
    private let db = Firestore.firestore()

    func placeOrder(order: Order, completion: @escaping (Result<String, Error>) -> Void) {
        let orderId = db.collection("orders").document().documentID
        let userId = order.userId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !userId.isEmpty else {
            completion(.failure(NSError(
                domain: "OrderService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Missing user ID"]
            )))
            return
        }

        var orderWithId = order
        orderWithId.id = orderId

        let batch = db.batch()
        let globalRef = db.collection("orders").document(orderId)
        let userRef = db.collection("users").document(userId).collection("orders").document(orderId)

        do {
            try batch.setData(from: orderWithId, forDocument: globalRef)
            try batch.setData(from: orderWithId, forDocument: userRef)
        } catch {
            completion(.failure(error))
            return
        }

        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(orderId))
            }
        }
    }

    func fetchOrders(for userId: String, completion: @escaping ([Order]) -> Void) {
        db.collection("users").document(userId).collection("orders").order(by: "createdAt", descending: true).getDocuments { snapshot, error in
            if let docs = snapshot?.documents {
                let orders = docs.compactMap { try? $0.data(as: Order.self) }
                completion(orders)
            } else {
                completion([])
            }
        }
    }

    func updateOrderStatus(orderId: String, userId: String, status: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let updates: [String: Any] = [
            "status": status,
            "updatedAt": Timestamp(date: Date())
        ]
        
        let batch = db.batch()
        let globalRef = db.collection("orders").document(orderId)
        let userRef = db.collection("users").document(userId).collection("orders").document(orderId)
        
        batch.updateData(updates, forDocument: globalRef)
        batch.updateData(updates, forDocument: userRef)
        
        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
} 
