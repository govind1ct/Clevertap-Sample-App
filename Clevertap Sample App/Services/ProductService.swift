import Foundation
import FirebaseFirestore
import Combine

class ProductService: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load sample data if Firebase is not configured
       // loadSampleData()
    }
    
    func fetchProducts() {
        isLoading = true
        errorMessage = nil

        // Try to fetch from Firebase first
        db.collection("products").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false

                if let error {
                    print("Firebase error: \(error.localizedDescription)")
                    self.errorMessage = "Unable to load products right now. Please try again."
                    self.products = []
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.errorMessage = "No product data was returned."
                    self.products = []
                    return
                }

                let decodedProducts = documents.compactMap { doc in
                    try? doc.data(as: Product.self)
                }

                self.products = decodedProducts

                if documents.isEmpty {
                    self.errorMessage = "No products are available at the moment."
                } else if decodedProducts.isEmpty {
                    self.errorMessage = "Products could not be parsed. Please verify product schema."
                }
            }
        }
    }
}
