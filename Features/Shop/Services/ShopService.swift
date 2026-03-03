import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

class ShopService: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    // Fetch all products from Firestore
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
    
    // Filter products by category (String)
    func products(forCategory category: String) -> [Product] {
        products.filter { $0.category.lowercased() == category.lowercased() }
    }
    
    // Search products by keyword
    func searchProducts(keyword: String) -> [Product] {
        let lowerKeyword = keyword.lowercased()
        return products.filter {
            $0.name.lowercased().contains(lowerKeyword) ||
            $0.description.lowercased().contains(lowerKeyword) ||
            $0.category.lowercased().contains(lowerKeyword) ||
            $0.searchKeywords.contains(where: { $0.lowercased().contains(lowerKeyword) })
        }
    }
} 