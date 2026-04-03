import Foundation
import FirebaseFirestore

final class AdminProductService: ObservableObject {
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func createProduct(from data: AdminProductFormData, completion: @escaping (Result<String, Error>) -> Void) {
        isSaving = true
        errorMessage = nil

        let docRef = db.collection("products").document()
        let payload = data.toFirestoreData(includeCreatedAt: true)

        docRef.setData(payload) { [weak self] error in
            DispatchQueue.main.async {
                self?.isSaving = false
                if let error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else {
                    AdminAuditLogger.log(
                        action: "create",
                        entityType: "product",
                        entityId: docRef.documentID,
                        metadata: ["name": data.name]
                    )
                    completion(.success(docRef.documentID))
                }
            }
        }
    }

    func updateProduct(productId: String, data: AdminProductFormData, completion: @escaping (Result<Void, Error>) -> Void) {
        isSaving = true
        errorMessage = nil

        let docRef = db.collection("products").document(productId)
        let payload = data.toFirestoreData(includeCreatedAt: false)

        docRef.setData(payload, merge: true) { [weak self] error in
            DispatchQueue.main.async {
                self?.isSaving = false
                if let error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else {
                    AdminAuditLogger.log(
                        action: "update",
                        entityType: "product",
                        entityId: productId,
                        metadata: ["name": data.name]
                    )
                    completion(.success(()))
                }
            }
        }
    }

    func deleteProduct(productId: String, productName: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        isSaving = true
        errorMessage = nil

        db.collection("products").document(productId).delete { [weak self] error in
            DispatchQueue.main.async {
                self?.isSaving = false
                if let error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else {
                    AdminAuditLogger.log(
                        action: "delete",
                        entityType: "product",
                        entityId: productId,
                        metadata: ["name": productName ?? ""]
                    )
                    completion(.success(()))
                }
            }
        }
    }

    func updateProductFields(
        productId: String,
        productName: String,
        fields: [String: Any],
        auditAction: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        isSaving = true
        errorMessage = nil

        db.collection("products").document(productId).setData(fields, merge: true) { [weak self] error in
            DispatchQueue.main.async {
                self?.isSaving = false
                if let error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else {
                    AdminAuditLogger.log(
                        action: auditAction,
                        entityType: "product",
                        entityId: productId,
                        metadata: ["name": productName]
                    )
                    completion(.success(()))
                }
            }
        }
    }

    func bulkUpdateProducts(
        productIDs: [String],
        fields: [String: Any],
        auditAction: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard !productIDs.isEmpty else {
            completion(.success(()))
            return
        }

        isSaving = true
        errorMessage = nil

        let batch = db.batch()
        for productId in productIDs {
            let ref = db.collection("products").document(productId)
            batch.setData(fields, forDocument: ref, merge: true)
        }

        batch.commit { [weak self] error in
            DispatchQueue.main.async {
                self?.isSaving = false
                if let error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else {
                    AdminAuditLogger.log(
                        action: auditAction,
                        entityType: "product_bulk",
                        entityId: nil,
                        metadata: [
                            "count": productIDs.count,
                            "productIDs": productIDs
                        ]
                    )
                    completion(.success(()))
                }
            }
        }
    }

    func bulkDeleteProducts(
        products: [(id: String, name: String)],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard !products.isEmpty else {
            completion(.success(()))
            return
        }

        isSaving = true
        errorMessage = nil

        let batch = db.batch()
        for product in products {
            let ref = db.collection("products").document(product.id)
            batch.deleteDocument(ref)
        }

        batch.commit { [weak self] error in
            DispatchQueue.main.async {
                self?.isSaving = false
                if let error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else {
                    AdminAuditLogger.log(
                        action: "bulk_delete",
                        entityType: "product_bulk",
                        entityId: nil,
                        metadata: [
                            "count": products.count,
                            "productIDs": products.map(\.id),
                            "names": products.map(\.name)
                        ]
                    )
                    completion(.success(()))
                }
            }
        }
    }
}

struct AdminProductFormData: Codable, Equatable {
    var name: String = ""
    var description: String = ""
    var shortDescription: String = ""
    var price: Double = 0
    var originalPrice: Double = 0
    var purposesText: String = ""
    var category: String = ""
    var chakrasText: String = ""
    var energyLevel: Int = 0
    var imagesText: String = ""
    var imageURL: String = ""
    var benefitsText: String = ""
    var careInstructions: String = ""
    var isNewLaunch: Bool = false
    var isFeatured: Bool = false
    var merchandisingPriority: Int = 0
    var isCategoryPinned: Bool = false
    var categorySortPriority: Int = 0
    var homePlacementSlot: Int = 0
    var campaignTagsText: String = ""
    var hasFeaturedSchedule: Bool = false
    var featuredStartAt: Date = Date()
    var featuredEndAt: Date = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    var hasNewLaunchSchedule: Bool = false
    var newLaunchStartAt: Date = Date()
    var newLaunchEndAt: Date = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    var specificationsText: String = ""
    var searchKeywordsText: String = ""
    var status: String = "active"
    var stockQuantity: Int = 0
    var lowStockThreshold: Int = 3
    var availabilityMessage: String = ""

    init() {}

    init(from product: Product) {
        name = product.name
        description = product.description
        shortDescription = product.shortDescription ?? ""
        price = product.price
        originalPrice = product.originalPrice
        purposesText = product.purposes.joined(separator: ", ")
        category = product.category
        chakrasText = product.chakras.joined(separator: ", ")
        energyLevel = product.energyLevel
        imagesText = product.images.joined(separator: ", ")
        imageURL = product.imageURL ?? ""
        benefitsText = product.benefits.joined(separator: ", ")
        careInstructions = product.careInstructions
        isNewLaunch = product.isNewLaunch
        isFeatured = product.isFeatured
        merchandisingPriority = product.resolvedMerchandisingPriority
        isCategoryPinned = product.resolvedCategoryPinned
        categorySortPriority = product.resolvedCategorySortPriority
        homePlacementSlot = product.resolvedHomePlacementSlot ?? 0
        campaignTagsText = product.resolvedCampaignTags.joined(separator: ", ")
        hasFeaturedSchedule = product.featuredStartAt != nil || product.featuredEndAt != nil
        featuredStartAt = product.featuredStartAt ?? Date()
        featuredEndAt = product.featuredEndAt ?? (Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date())
        hasNewLaunchSchedule = product.newLaunchStartAt != nil || product.newLaunchEndAt != nil
        newLaunchStartAt = product.newLaunchStartAt ?? Date()
        newLaunchEndAt = product.newLaunchEndAt ?? (Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date())
        specificationsText = product.specifications?.map { "\($0.key):\($0.value)" }.joined(separator: ", ") ?? ""
        searchKeywordsText = product.searchKeywords.joined(separator: ", ")
        status = product.effectiveStatus
        stockQuantity = product.resolvedStockQuantity
        lowStockThreshold = product.resolvedLowStockThreshold
        availabilityMessage = product.availabilityMessage ?? ""
    }

    func toFirestoreData(includeCreatedAt: Bool) -> [String: Any] {
        var data: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "description": description.trimmingCharacters(in: .whitespacesAndNewlines),
            "price": price,
            "originalPrice": originalPrice,
            "purposes": parseList(purposesText),
            "category": category.trimmingCharacters(in: .whitespacesAndNewlines),
            "chakras": parseList(chakrasText),
            "energyLevel": energyLevel,
            "images": parseList(imagesText),
            "benefits": parseList(benefitsText),
            "careInstructions": careInstructions.trimmingCharacters(in: .whitespacesAndNewlines),
            "isNewLaunch": isNewLaunch,
            "isFeatured": isFeatured,
            "merchandisingPriority": merchandisingPriority,
            "isCategoryPinned": isCategoryPinned,
            "categorySortPriority": categorySortPriority,
            "campaignTags": parseList(campaignTagsText),
            "searchKeywords": parseList(searchKeywordsText),
            "status": normalizedStatus,
            "stockQuantity": max(stockQuantity, 0),
            "lowStockThreshold": max(lowStockThreshold, 1)
        ]

        let shortValue = shortDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !shortValue.isEmpty {
            data["shortDescription"] = shortValue
        }

        let imageValue = imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !imageValue.isEmpty {
            data["imageURL"] = imageValue
        }

        let specs = parseSpecifications(specificationsText)
        if !specs.isEmpty {
            data["specifications"] = specs
        }

        let availabilityValue = availabilityMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        if !availabilityValue.isEmpty {
            data["availabilityMessage"] = availabilityValue
        }

        if homePlacementSlot > 0 {
            data["homePlacementSlot"] = homePlacementSlot
        } else {
            data["homePlacementSlot"] = FieldValue.delete()
        }

        if hasFeaturedSchedule {
            data["featuredStartAt"] = featuredStartAt
            data["featuredEndAt"] = featuredEndAt
        } else {
            data["featuredStartAt"] = FieldValue.delete()
            data["featuredEndAt"] = FieldValue.delete()
        }

        if hasNewLaunchSchedule {
            data["newLaunchStartAt"] = newLaunchStartAt
            data["newLaunchEndAt"] = newLaunchEndAt
        } else {
            data["newLaunchStartAt"] = FieldValue.delete()
            data["newLaunchEndAt"] = FieldValue.delete()
        }

        if includeCreatedAt {
            data["createdAt"] = Date()
        }

        return data
    }

    private var normalizedStatus: String {
        let allowed = ["draft", "active", "archived"]
        let normalized = status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allowed.contains(normalized) ? normalized : "active"
    }

    private func parseList(_ raw: String) -> [String] {
        raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func parseSpecifications(_ raw: String) -> [String: String] {
        var result: [String: String] = [:]
        let pairs = raw.split(separator: ",")

        for pair in pairs {
            let parts = pair.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty, !value.isEmpty {
                result[key] = value
            }
        }

        return result
    }
}
