import Foundation
import FirebaseFirestore

struct Order: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let userEmail: String?
    let items: [CartItem]
    let address: String
    let shippingName: String?
    let shippingStreet: String?
    let shippingCity: String?
    let shippingPincode: String?
    let paymentMethod: String
    let total: Double
    let status: String
    let createdAt: Date
} 
