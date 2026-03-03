import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import SwiftUI

// MARK: - User Profile Model
struct UserProfile {
    var name: String = ""
    var phone: String = ""
    var location: String = ""
    var dateOfBirth: Date?
    var gender: String = ""
    var photoURL: String = ""
    var pushNotificationsEnabled: Bool = true
    var emailNotificationsEnabled: Bool = true
    var smsNotificationsEnabled: Bool = true
    var loyaltyPoints: Int = 0
    var membershipTier: String = "Bronze"
    var customerType: String = "Regular"
    var preferredLanguage: String = "English"
    
    init() {}
    
    init(from data: [String: Any]) {
        self.name = data["name"] as? String ?? ""
        self.phone = data["phone"] as? String ?? ""
        self.location = data["location"] as? String ?? ""
        self.gender = data["gender"] as? String ?? ""
        self.photoURL = data["photoURL"] as? String ?? ""
        self.pushNotificationsEnabled = data["pushNotificationsEnabled"] as? Bool ?? true
        self.emailNotificationsEnabled = data["emailNotificationsEnabled"] as? Bool ?? true
        self.smsNotificationsEnabled = data["smsNotificationsEnabled"] as? Bool ?? true
        self.loyaltyPoints = data["loyaltyPoints"] as? Int ?? 0
        self.membershipTier = data["membershipTier"] as? String ?? "Bronze"
        self.customerType = data["customerType"] as? String ?? "Regular"
        self.preferredLanguage = data["preferredLanguage"] as? String ?? "English"
        
        if let timestamp = data["dateOfBirth"] as? Timestamp {
            self.dateOfBirth = timestamp.dateValue()
        }
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "phone": phone,
            "location": location,
            "gender": gender,
            "photoURL": photoURL,
            "pushNotificationsEnabled": pushNotificationsEnabled,
            "emailNotificationsEnabled": emailNotificationsEnabled,
            "smsNotificationsEnabled": smsNotificationsEnabled,
            "loyaltyPoints": loyaltyPoints,
            "membershipTier": membershipTier,
            "preferredLanguage": preferredLanguage,
            "customerType": customerType,
            "lastUpdated": Timestamp(date: Date())
        ]
        
        if let dateOfBirth = dateOfBirth {
            dict["dateOfBirth"] = Timestamp(date: dateOfBirth)
        }
        
        return dict
    }
}

// MARK: - Profile Service
class ProfileService: ObservableObject {
    @Published var userProfile = UserProfile()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isUploadingImage = false
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }

    private func userProfileDocument(for userID: String) -> DocumentReference {
        db.collection("users").document(userID)
    }

    private func legacyUserProfileDocument(for userID: String) -> DocumentReference {
        db.collection("userProfiles").document(userID)
    }

    private func cachedPhotoURLKey(for userID: String) -> String {
        "profile.cachedPhotoURL.\(userID)"
    }
    
    // MARK: - Fetch User Profile
    func fetchUserProfile(completion: @escaping (Bool) -> Void) {
        guard let userID = currentUserID else {
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        if userProfile.photoURL.isEmpty,
           let cachedPhotoURL = UserDefaults.standard.string(forKey: cachedPhotoURLKey(for: userID)),
           !cachedPhotoURL.isEmpty {
            userProfile.photoURL = cachedPhotoURL
        }

        userProfileDocument(for: userID).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                guard let self else { completion(false); return }
                
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                
                let primaryData = (document?.exists == true) ? (document?.data() ?? [:]) : [:]

                // Backward-compatibility fallback: older builds wrote into userProfiles/{uid}
                self.legacyUserProfileDocument(for: userID).getDocument { legacyDocument, legacyError in
                    DispatchQueue.main.async {
                        self.isLoading = false

                        if let legacyError = legacyError {
                            self.errorMessage = legacyError.localizedDescription
                            completion(false)
                            return
                        }

                        let legacyData = (legacyDocument?.exists == true) ? (legacyDocument?.data() ?? [:]) : [:]

                        if primaryData.isEmpty && legacyData.isEmpty {
                            // Create default profile if doesn't exist in either location.
                            self.createDefaultProfile()
                            completion(true)
                            return
                        }

                        var mergedProfile = self.userProfile
                        // Merge legacy first, then primary so users/{uid} wins where present.
                        self.mergeProfile(&mergedProfile, with: legacyData)
                        self.mergeProfile(&mergedProfile, with: primaryData)

                        if mergedProfile.photoURL.isEmpty,
                           let authPhotoURL = Auth.auth().currentUser?.photoURL?.absoluteString,
                           !authPhotoURL.isEmpty {
                            mergedProfile.photoURL = authPhotoURL
                        }

                        self.userProfile = mergedProfile

                        if !mergedProfile.photoURL.isEmpty {
                            UserDefaults.standard.set(mergedProfile.photoURL, forKey: self.cachedPhotoURLKey(for: userID))
                        }

                        // Migrate legacy into users/{uid} for consistency.
                        if primaryData.isEmpty && !legacyData.isEmpty {
                            self.userProfileDocument(for: userID).setData(mergedProfile.toDictionary(), merge: true) { _ in }
                        }

                        completion(true)
                    }
                }
            }
        }
    }
    
    // MARK: - Simple Image URL Update (for now, user can provide image URL)
    func updateProfileImageURL(_ imageURL: String, completion: @escaping (Bool, String?) -> Void) {
        guard let userID = currentUserID else {
            completion(false, "User not authenticated")
            return
        }
        
        isUploadingImage = true
        
        // Update profile with new image URL
        userProfile.photoURL = imageURL
        saveUserProfile { [weak self] success in
            DispatchQueue.main.async {
                guard let self else {
                    completion(false, "Profile service unavailable")
                    return
                }

                self.isUploadingImage = false
                
                if success {
                    UserDefaults.standard.set(imageURL, forKey: self.cachedPhotoURLKey(for: userID))
                    // Update CleverTap profile with new photo
                    CleverTapService.shared.updateFullUserProfile(
                        photo: imageURL
                    )
                    completion(true, imageURL)
                } else {
                    completion(false, "Failed to save profile")
                }
            }
        }
    }

    // MARK: - Image Upload from Device (Local Persistence)
    func updateProfileImage(_ image: UIImage, completion: @escaping (Bool, String?) -> Void) {
        guard let userID = currentUserID else {
            completion(false, "User not authenticated")
            return
        }

        isUploadingImage = true

        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            isUploadingImage = false
            completion(false, "Failed to process selected image")
            return
        }

        let profileImageRef = storage.reference().child("profile_images/\(userID).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        profileImageRef.putData(imageData, metadata: metadata) { [weak self] _, error in
            guard let self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.isUploadingImage = false
                    completion(false, error.localizedDescription)
                }
                return
            }

            profileImageRef.downloadURL { url, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.isUploadingImage = false
                        completion(false, error.localizedDescription)
                        return
                    }

                    guard let downloadURL = url else {
                        self.isUploadingImage = false
                        completion(false, "Could not fetch uploaded image URL")
                        return
                    }

                    let imageURLString = downloadURL.absoluteString
                    self.userProfile.photoURL = imageURLString
                    self.saveUserProfile { success in
                        DispatchQueue.main.async {
                            self.isUploadingImage = false
                            if success {
                                UserDefaults.standard.set(imageURLString, forKey: self.cachedPhotoURLKey(for: userID))
                                if let user = Auth.auth().currentUser {
                                    let request = user.createProfileChangeRequest()
                                    request.photoURL = downloadURL
                                    request.commitChanges(completion: nil)
                                }

                                CleverTapService.shared.updateFullUserProfile(photo: imageURLString)
                                completion(true, imageURLString)
                            } else {
                                completion(false, "Failed to save profile")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Update User Profile
    func updateUserProfile(
        name: String? = nil,
        phone: String? = nil,
        location: String? = nil,
        dateOfBirth: Date? = nil,
        gender: String? = nil,
        photoURL: String? = nil,
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        guard currentUserID != nil else {
            completion(false)
            return
        }
        
        // Update local profile
        if let name = name { userProfile.name = name }
        if let phone = phone { userProfile.phone = phone }
        if let location = location { userProfile.location = location }
        if let dateOfBirth = dateOfBirth { userProfile.dateOfBirth = dateOfBirth }
        if let gender = gender { userProfile.gender = gender }
        if let photoURL = photoURL { userProfile.photoURL = photoURL }
        
        // Save to Firebase
        saveUserProfile(completion: completion)
        
        // Sync with CleverTap
        syncWithCleverTap()
    }
    
    // MARK: - Update Notification Preferences
    func updateNotificationPreference(type: String, enabled: Bool) {
        switch type {
        case "push":
            userProfile.pushNotificationsEnabled = enabled
        case "email":
            userProfile.emailNotificationsEnabled = enabled
        case "sms":
            userProfile.smsNotificationsEnabled = enabled
        default:
            break
        }
        
        saveUserProfile()
        syncWithCleverTap()
    }
    
    // MARK: - Update Loyalty Points
    func updateLoyaltyPoints(_ points: Int) {
        userProfile.loyaltyPoints = points
        
        // Update membership tier based on points
        if points >= 1000 {
            userProfile.membershipTier = "Gold"
        } else if points >= 500 {
            userProfile.membershipTier = "Silver"
        } else {
            userProfile.membershipTier = "Bronze"
        }
        
        saveUserProfile()
        syncWithCleverTap()
    }
    
    // MARK: - Private Methods
    private func createDefaultProfile() {
        guard let user = Auth.auth().currentUser else { return }
        
        userProfile = UserProfile()
        userProfile.name = user.displayName ?? ""
        userProfile.photoURL = user.photoURL?.absoluteString ?? ""
        
        saveUserProfile()
    }
    
    private func saveUserProfile(completion: @escaping (Bool) -> Void = { _ in }) {
        guard let userID = currentUserID else {
            completion(false)
            return
        }
        
        let data = userProfile.toDictionary()
        
        userProfileDocument(for: userID).setData(data, merge: true) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    if !self.userProfile.photoURL.isEmpty {
                        UserDefaults.standard.set(self.userProfile.photoURL, forKey: self.cachedPhotoURLKey(for: userID))
                    }
                    completion(true)
                }
            }
        }
    }

    private func mergeProfile(_ profile: inout UserProfile, with data: [String: Any]) {
        guard !data.isEmpty else { return }

        if let name = data["name"] as? String, !name.isEmpty { profile.name = name }
        if let phone = data["phone"] as? String, !phone.isEmpty { profile.phone = phone }
        if let location = data["location"] as? String, !location.isEmpty { profile.location = location }
        if let gender = data["gender"] as? String, !gender.isEmpty { profile.gender = gender }
        if let photoURL = data["photoURL"] as? String, !photoURL.isEmpty { profile.photoURL = photoURL }

        if let push = data["pushNotificationsEnabled"] as? Bool { profile.pushNotificationsEnabled = push }
        if let email = data["emailNotificationsEnabled"] as? Bool { profile.emailNotificationsEnabled = email }
        if let sms = data["smsNotificationsEnabled"] as? Bool { profile.smsNotificationsEnabled = sms }
        if let points = data["loyaltyPoints"] as? Int { profile.loyaltyPoints = points }
        if let tier = data["membershipTier"] as? String, !tier.isEmpty { profile.membershipTier = tier }
        if let customerType = data["customerType"] as? String, !customerType.isEmpty { profile.customerType = customerType }
        if let preferredLanguage = data["preferredLanguage"] as? String, !preferredLanguage.isEmpty { profile.preferredLanguage = preferredLanguage }
        if let dob = data["dateOfBirth"] as? Timestamp { profile.dateOfBirth = dob.dateValue() }
    }

    private func syncWithCleverTap() {
        guard let user = Auth.auth().currentUser else { return }
        
        // Use the enhanced validation method for better data quality
        CleverTapService.shared.validateAndUpdateProfile(
            name: userProfile.name.isEmpty ? nil : userProfile.name,
            email: user.email,
            phone: userProfile.phone.isEmpty ? nil : userProfile.phone,
            gender: userProfile.gender.isEmpty ? nil : userProfile.gender,
            dateOfBirth: userProfile.dateOfBirth,
            location: userProfile.location.isEmpty ? nil : userProfile.location
        )
        
        // Specific DOB update if available
        if let dateOfBirth = userProfile.dateOfBirth {
            CleverTapService.shared.updateDateOfBirth(dateOfBirth)
        }
        
        // Update additional profile properties
        CleverTapService.shared.updateFullUserProfile(
            customerType: userProfile.customerType,
            preferredLanguage: userProfile.preferredLanguage,
            customProperties: [
                "Firebase UID": user.uid,
                "Loyalty Points": userProfile.loyaltyPoints,
                "Membership Tier": userProfile.membershipTier,
                "Profile Completion": calculateProfileCompletion(),
                "Last Profile Update": Date(),
                "Push Notifications": userProfile.pushNotificationsEnabled,
                "Email Notifications": userProfile.emailNotificationsEnabled,
                "SMS Notifications": userProfile.smsNotificationsEnabled
            ]
        )
        
        // Update notification preferences in CleverTap
        CleverTapService.shared.updateEngagementProfile(
            pushOptIn: userProfile.pushNotificationsEnabled,
            emailOptIn: userProfile.emailNotificationsEnabled
        )
        
        // Set DND preferences
        CleverTapService.shared.setPushDND(enabled: !userProfile.pushNotificationsEnabled)
        CleverTapService.shared.setEmailDND(enabled: !userProfile.emailNotificationsEnabled)
        CleverTapService.shared.setSMSDND(enabled: !userProfile.smsNotificationsEnabled)
        
        // Track profile completion
        CleverTapService.shared.trackProfileCompletion()
        
        // Debug profile data (for development)
        #if DEBUG
        CleverTapService.shared.debugProfileData()
        #endif
    }
    
    // MARK: - Force Sync with CleverTap
    func forceCleverTapSync() {
        CleverTapService.shared.forceProfileSync()
        syncWithCleverTap()
    }
    
    private func calculateProfileCompletion() -> Int {
        var completion = 0
        
        if !userProfile.name.isEmpty { completion += 20 }
        if !userProfile.phone.isEmpty { completion += 20 }
        if !userProfile.location.isEmpty { completion += 20 }
        if userProfile.dateOfBirth != nil { completion += 20 }
        if !userProfile.gender.isEmpty { completion += 20 }
        
        return completion
    }
} 
