import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

class ProductService: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchProducts() {
        isLoading = true
        db.collection("products").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                guard let documents = snapshot?.documents else {
                    self?.products = []
                    return
                }
                self?.products = documents.compactMap { doc in
                    try? doc.data(as: Product.self)
                }
            }
        }
    }
} 