import Foundation
import CleverTapSDK

class CleverTapService: ObservableObject {
    static let shared = CleverTapService()
    
    private init() {}

    private enum SharedPushIdentityConfig {
        static let appGroupID = "group.com.govind.clevertap-sample-app"
        static let identityKey = "ct_identity"
        static let emailKey = "ct_email"
    }

    // MARK: - SDK Diagnostics

    func sdkVersionString() -> String {
        // Prefer explicit SDK API if exposed by the binary.
        let selectors = ["sdkVersion", "version", "getSdkVersion", "sdkVersionString"]

        for name in selectors {
            let selector = NSSelectorFromString(name)

            if (CleverTap.self as AnyObject).responds(to: selector),
               let unmanaged = (CleverTap.self as AnyObject).perform(selector) {
                let value = String(describing: unmanaged.takeUnretainedValue()).trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty, value.caseInsensitiveCompare("unknown") != .orderedSame {
                    return value
                }
            }

            if let instance = CleverTap.sharedInstance() as AnyObject?,
               instance.responds(to: selector),
               let unmanaged = instance.perform(selector) {
                let value = String(describing: unmanaged.takeUnretainedValue()).trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty, value.caseInsensitiveCompare("unknown") != .orderedSame {
                    return value
                }
            }
        }

        // Fallback to known framework bundles.
        let bundleCandidates: [Bundle?] = [
            Bundle(identifier: "com.clevertap.CleverTapSDK"),
            Bundle(identifier: "org.cocoapods.CleverTap-iOS-SDK"),
            Bundle(identifier: "com.clevertap.sdk"),
            Bundle(for: CleverTap.self)
        ]

        for bundle in bundleCandidates.compactMap({ $0 }) {
            if let value = bundle.infoDictionary?["CFBundleShortVersionString"] as? String,
               !value.isEmpty,
               value != "1.0" {
                return value
            }
            if let value = bundle.infoDictionary?["CFBundleVersion"] as? String,
               !value.isEmpty,
               value != "1.0" {
                return value
            }
        }

        // Final fallback if the package does not expose version metadata at runtime.
        return "Installed (runtime version not exposed)"
    }

    func accountIdString() -> String {
        let info = Bundle.main.infoDictionary ?? [:]
        let keys = ["CleverTapAccountID", "CLEVERTAP_ACCOUNT_ID", "CT_ACCOUNT_ID"]
        for key in keys {
            if let value = info[key] as? String, !value.isEmpty {
                return value
            }
        }
        return "Not Found"
    }

    func regionString() -> String {
        let info = Bundle.main.infoDictionary ?? [:]
        let keys = ["CleverTapRegion", "CLEVERTAP_REGION", "CT_REGION"]
        for key in keys {
            if let value = info[key] as? String, !value.isEmpty {
                return value
            }
        }
        return "Default"
    }

    func tokenStatusString() -> String {
        let info = Bundle.main.infoDictionary ?? [:]
        let keys = ["CleverTapToken", "CLEVERTAP_TOKEN", "CT_TOKEN"]
        for key in keys {
            if let value = info[key] as? String, !value.isEmpty {
                return "Configured"
            }
        }
        return "Not Found"
    }

    private func refreshProductExperiences() {
        Task { @MainActor in
            CleverTapProductExperiencesService.shared.fetchVariables()
        }
    }

    private func cachedPushTokenData() -> Data? {
        UserDefaults.standard.data(forKey: "deviceToken")
    }

    private func rebindCachedPushTokenIfAvailable(userId: String) {
        guard let deviceToken = cachedPushTokenData() else {
            return
        }

        CleverTap.sharedInstance()?.setPushToken(deviceToken)

        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        CleverTap.sharedInstance()?.profilePush([
            "Device Token": tokenString,
            "Push Enabled": true,
            "Last Token Update": Date()
        ])

        CleverTap.sharedInstance()?.recordEvent("Device Token Rebound", withProps: [
            "User ID": userId,
            "Platform": "iOS"
        ])
    }
    
    // MARK: - User Profile Management
    
    func createUserProfile(email: String, userId: String, name: String, isNewUser: Bool = false) {
        let trimmedUserID = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUserID.isEmpty else { return }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        var profile: [String: Any] = [
            "Identity": trimmedUserID
        ]

        if !trimmedEmail.isEmpty {
            profile["Email"] = trimmedEmail
        }

        if !trimmedName.isEmpty {
            profile["Name"] = trimmedName
        }

        if isNewUser {
            profile["Customer Type"] = "New User"
            profile["Registration Date"] = Date()
        }

        // Always switch explicitly using Identity-first payload to avoid profile merge issues.
        CleverTap.sharedInstance()?.onUserLogin(profile)
        CleverTap.sharedInstance()?.profilePush(profile)
        rebindCachedPushTokenIfAvailable(userId: trimmedUserID)
        syncPushIdentityForExtensions(identity: trimmedUserID, email: trimmedEmail)
        refreshProductExperiences()

        // Check notification permissions after user login
        NotificationDelegate.shared.checkNotificationPermissions()
    }

    func syncPushIdentityForExtensions(identity: String? = nil, email: String? = nil) {
        guard let sharedDefaults = UserDefaults(suiteName: SharedPushIdentityConfig.appGroupID) else {
            return
        }

        if let providedIdentity = identity, !providedIdentity.isEmpty {
            sharedDefaults.set(providedIdentity, forKey: SharedPushIdentityConfig.identityKey)
        } else if let existingIdentity = CleverTap.sharedInstance()?.profileGet("Identity") as? String, !existingIdentity.isEmpty {
            sharedDefaults.set(existingIdentity, forKey: SharedPushIdentityConfig.identityKey)
        }

        if let providedEmail = email, !providedEmail.isEmpty {
            sharedDefaults.set(providedEmail, forKey: SharedPushIdentityConfig.emailKey)
        } else if let existingEmail = CleverTap.sharedInstance()?.profileGet("Email") as? String, !existingEmail.isEmpty {
            sharedDefaults.set(existingEmail, forKey: SharedPushIdentityConfig.emailKey)
        }
    }

    func clearPushIdentityForExtensions() {
        guard let sharedDefaults = UserDefaults(suiteName: SharedPushIdentityConfig.appGroupID) else {
            return
        }

        sharedDefaults.removeObject(forKey: SharedPushIdentityConfig.identityKey)
        sharedDefaults.removeObject(forKey: SharedPushIdentityConfig.emailKey)
    }

    func logoutCurrentUser(firebaseUserID: String? = nil) {
        guard let sdk = CleverTap.sharedInstance() else {
            clearPushIdentityForExtensions()
            return
        }

        let previousIdentity = sdk.profileGet("Identity") as? String ?? ""
        let previousEmail = sdk.profileGet("Email") as? String ?? ""

        var logoutEventProps: [String: Any] = [
            "Platform": "iOS",
            "Timestamp": Date()
        ]

        if !previousIdentity.isEmpty {
            logoutEventProps["Previous Identity"] = previousIdentity
        }
        if !previousEmail.isEmpty {
            logoutEventProps["Previous Email"] = previousEmail
        }
        if let firebaseUserID, !firebaseUserID.isEmpty {
            logoutEventProps["Firebase User ID"] = firebaseUserID
        }

        sdk.recordEvent("User Logged Out", withProps: logoutEventProps)

        // Important: switch to a fresh guest identity so identified profile remains isolated
        // and future login does not merge into an in-between anonymous state.
        let guestIdentity = "guest_\(UUID().uuidString)"
        sdk.onUserLogin([
            "Identity": guestIdentity,
            "Customer Type": "Guest",
            "Session State": "Logged Out"
        ])
        sdk.profilePush([
            "Session State": "Logged Out",
            "Last Logout": Date()
        ])

        clearPushIdentityForExtensions()
        refreshProductExperiences()
    }
    
    func updateUserProfile(with data: [String: Any]) {
        CleverTap.sharedInstance()?.profilePush(data)
        refreshProductExperiences()
    }
    
    // MARK: - Comprehensive Profile Management (Based on CleverTap iOS Documentation)
    
    func updateFullUserProfile(
        name: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        gender: String? = nil,
        dateOfBirth: Date? = nil,
        age: Int? = nil,
        photo: String? = nil,
        customerType: String? = nil,
        preferredLanguage: String? = nil,
        location: String? = nil,
        customProperties: [String: Any]? = nil
    ) {
        var profile: [String: Any] = [:]
        
        // Standard CleverTap profile fields (exact names as per documentation)
        if let name = name { profile["Name"] = name }
        if let email = email { profile["Email"] = email }
        if let phone = phone { profile["Phone"] = phone }
        if let gender = gender { profile["Gender"] = gender }
        
        // Fix DOB format - CleverTap expects NSDate object as per documentation
        if let dateOfBirth = dateOfBirth { 
            profile["DOB"] = dateOfBirth as NSDate
        }
        
        if let age = age { profile["Age"] = age }
        if let photo = photo { profile["Photo"] = photo }
        
        // Custom properties
        if let customerType = customerType { profile["Customer Type"] = customerType }
        if let preferredLanguage = preferredLanguage { profile["Preferred Language"] = preferredLanguage }
        if let location = location { profile["Location"] = location }
        
        // Add custom properties
        if let customProperties = customProperties {
            for (key, value) in customProperties {
                profile[key] = value
            }
        }
        
        // Update last profile update timestamp
        profile["Last Profile Update"] = Date() as NSDate
        
        CleverTap.sharedInstance()?.profilePush(profile)
        refreshProductExperiences()
    }
    
    // MARK: - Multi-Value Properties
    
    func setMultiValueProperty(key: String, values: [String]) {
        CleverTap.sharedInstance()?.profileSetMultiValues(values, forKey: key)
    }
    
    func addToMultiValueProperty(key: String, value: String) {
        CleverTap.sharedInstance()?.profileAddMultiValue(value, forKey: key)
    }
    
    func addToMultiValueProperty(key: String, values: [String]) {
        CleverTap.sharedInstance()?.profileAddMultiValues(values, forKey: key)
    }
    
    func removeFromMultiValueProperty(key: String, value: String) {
        CleverTap.sharedInstance()?.profileRemoveMultiValue(value, forKey: key)
    }
    
    func removeFromMultiValueProperty(key: String, values: [String]) {
        CleverTap.sharedInstance()?.profileRemoveMultiValues(values, forKey: key)
    }
    
    func removeProperty(key: String) {
        CleverTap.sharedInstance()?.profileRemoveValue(forKey: key)
    }
    
    // MARK: - Increment/Decrement Operations (As per CleverTap documentation)
    
    func incrementUserProperty(key: String, by value: NSNumber) {
        CleverTap.sharedInstance()?.profileIncrementValue(by: value, forKey: key)
    }
    
    func decrementUserProperty(key: String, by value: NSNumber) {
        CleverTap.sharedInstance()?.profileDecrementValue(by: value, forKey: key)
    }
    
    // MARK: - DND (Do Not Disturb) Management (As per CleverTap documentation)
    
    func setEmailDND(enabled: Bool) {
        let profile = ["MSG-email": !enabled]
        CleverTap.sharedInstance()?.profilePush(profile)
    }
    
    func setPushDND(enabled: Bool) {
        let profile = ["MSG-push": !enabled]
        CleverTap.sharedInstance()?.profilePush(profile)
    }
    
    func setSMSDND(enabled: Bool) {
        let profile = ["MSG-sms": !enabled]
        CleverTap.sharedInstance()?.profilePush(profile)
    }
    
    func setPhoneDND(enabled: Bool) {
        let profile = ["MSG-dndPhone": enabled]
        CleverTap.sharedInstance()?.profilePush(profile)
    }
    
    func setEmailAddressDND(enabled: Bool) {
        let profile = ["MSG-dndEmail": enabled]
        CleverTap.sharedInstance()?.profilePush(profile)
    }
    
    // MARK: - User Preferences and Behavior Tracking
    
    func trackUserPreferences(
        favoriteCategories: [String]? = nil,
        priceRange: String? = nil,
        shoppingFrequency: String? = nil,
        preferredPaymentMethod: String? = nil,
        notificationPreferences: [String: Bool]? = nil
    ) {
        var profile: [String: Any] = [:]
        
        if let favoriteCategories = favoriteCategories {
            setMultiValueProperty(key: "Favorite Categories", values: favoriteCategories)
        }
        
        if let priceRange = priceRange {
            profile["Price Range Preference"] = priceRange
        }
        
        if let shoppingFrequency = shoppingFrequency {
            profile["Shopping Frequency"] = shoppingFrequency
        }
        
        if let preferredPaymentMethod = preferredPaymentMethod {
            profile["Preferred Payment Method"] = preferredPaymentMethod
        }
        
        if let notificationPreferences = notificationPreferences {
            for (key, value) in notificationPreferences {
                profile[key] = value
            }
        }
        
        if !profile.isEmpty {
            CleverTap.sharedInstance()?.profilePush(profile)
        }
    }
    
    // MARK: - E-commerce Specific Profile Updates (Fixed property names)
    
    func updateEcommerceProfile(
        totalOrders: Int? = nil,
        totalSpent: Double? = nil,
        averageOrderValue: Double? = nil,
        lastOrderDate: Date? = nil,
        favoriteProducts: [String]? = nil,
        loyaltyPoints: Int? = nil,
        membershipTier: String? = nil
    ) {
        var profile: [String: Any] = [:]
        
        // Use increment operations for cumulative values
        if let totalOrders = totalOrders {
            profile["Total Orders"] = totalOrders
        }
        
        if let totalSpent = totalSpent {
            profile["Total Spent"] = totalSpent
        }
        
        if let averageOrderValue = averageOrderValue {
            profile["Average Order Value"] = averageOrderValue
        }
        
        if let lastOrderDate = lastOrderDate {
            profile["Last Order Date"] = lastOrderDate as NSDate
        }
        
        if let favoriteProducts = favoriteProducts {
            setMultiValueProperty(key: "Favorite Products", values: favoriteProducts)
        }
        
        if let loyaltyPoints = loyaltyPoints {
            profile["Loyalty Points"] = loyaltyPoints
        }
        
        if let membershipTier = membershipTier {
            profile["Membership Tier"] = membershipTier
        }
        
        if !profile.isEmpty {
            CleverTap.sharedInstance()?.profilePush(profile)
        }
    }
    
    // MARK: - App Engagement Profile Updates (Fixed property names)
    
    func updateEngagementProfile(
        appLaunches: Int? = nil,
        sessionDuration: TimeInterval? = nil,
        lastActiveDate: Date? = nil,
        featuresUsed: [String]? = nil,
        pushOptIn: Bool? = nil,
        emailOptIn: Bool? = nil
    ) {
        var profile: [String: Any] = [:]
        
        if let appLaunches = appLaunches {
            profile["App Launches"] = appLaunches
        }
        
        if let sessionDuration = sessionDuration {
            profile["Average Session Duration"] = sessionDuration
        }
        
        if let lastActiveDate = lastActiveDate {
            profile["Last Active Date"] = lastActiveDate as NSDate
        }
        
        if let featuresUsed = featuresUsed {
            setMultiValueProperty(key: "Features Used", values: featuresUsed)
        }
        
        if let pushOptIn = pushOptIn {
            setPushDND(enabled: !pushOptIn)
        }
        
        if let emailOptIn = emailOptIn {
            setEmailDND(enabled: !emailOptIn)
        }
        
        if !profile.isEmpty {
            CleverTap.sharedInstance()?.profilePush(profile)
        }
    }
    
    // MARK: - Profile Getters
    
    func getUserID() -> String? {
        return CleverTap.sharedInstance()?.profileGetID()
    }
    
    func getUserProperty(key: String) -> Any? {
        return CleverTap.sharedInstance()?.profileGet(key)
    }
    
    // MARK: - Push Notification Methods
    
    func registerDeviceToken(_ deviceToken: Data) {
        CleverTap.sharedInstance()?.setPushToken(deviceToken)
        
        // Convert to string for tracking
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        // Update user profile
        setUserProperty(key: "Device Token", value: tokenString)
        setUserProperty(key: "Push Enabled", value: true)
        setUserProperty(key: "Last Token Update", value: Date())
        
        // Track event
        let eventData: [String: Any] = [
            "Device Token": tokenString,
            "Platform": "iOS",
            "App Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        ]
        
        CleverTap.sharedInstance()?.recordEvent("Device Token Registered", withProps: eventData)
    }
    
    func trackPushNotificationPermission(granted: Bool) {
        let eventData: [String: Any] = [
            "Permission Granted": granted,
            "Platform": "iOS"
        ]
        
        CleverTap.sharedInstance()?.recordEvent("Push Permission Requested", withProps: eventData)
        
        // Update user profile
        setUserProperty(key: "Push Permission Granted", value: granted)
        setUserProperty(key: "Push Permission Date", value: Date())
        setPushDND(enabled: !granted)
    }
    
    func trackPushNotificationOpened(campaignId: String?, campaignName: String?) {
        var eventData: [String: Any] = [
            "Platform": "iOS"
        ]
        
        if let campaignId = campaignId {
            eventData["Campaign ID"] = campaignId
        }
        
        if let campaignName = campaignName {
            eventData["Campaign Name"] = campaignName
        }
        
        CleverTap.sharedInstance()?.recordEvent("Push Notification Opened", withProps: eventData)
    }
    
    // MARK: - E-commerce Events
    
    func trackProductViewed(productId: String, productName: String, category: String, price: Double) {
        let eventData: [String: Any] = [
            "Product ID": productId,
            "Product Name": productName,
            "Category": category,
            "Price": price,
            "Currency": "INR"
        ]
        
        CleverTap.sharedInstance()?.recordEvent("Product Viewed", withProps: eventData)
        
        // Update user profile with recently viewed products
        addToMultiValueProperty(key: "Recently Viewed Products", value: productName)
        addToMultiValueProperty(key: "Viewed Categories", value: category)
    }
    
    func trackProductAddedToCart(productId: String, productName: String, category: String, price: Double, quantity: Int) {
        let eventData: [String: Any] = [
            "Product ID": productId,
            "Product Name": productName,
            "Category": category,
            "Price": price,
            "Quantity": quantity,
            "Currency": "INR"
        ]
        
        CleverTap.sharedInstance()?.recordEvent("Product Added to Cart", withProps: eventData)
        
        // Update user profile
        incrementUserProperty(key: "Cart Additions", by: 1)
        setUserProperty(key: "Last Cart Addition", value: Date())
    }
    
    func trackOrderPlaced(orderId: String, totalAmount: Double, itemCount: Int, products: [[String: Any]]) {
        let eventData: [String: Any] = [
            "Order ID": orderId,
            "Total Amount": totalAmount,
            "Item Count": itemCount,
            "Products": products,
            "Currency": "INR"
        ]
        
        CleverTap.sharedInstance()?.recordEvent("Order Placed", withProps: eventData)
        
        // Also fire CleverTap's standard Charged event so it can be used as a conversion event
        let chargeDetails: [String: Any] = [
            "Amount": totalAmount,
            "Charged ID": orderId,
            "Item Count": itemCount,
            "Currency": "INR",
            "Charged Date": Date()
        ]
        
        CleverTap.sharedInstance()?.recordChargedEvent(withDetails: chargeDetails, andItems: products)
        
        // Update comprehensive e-commerce profile
        incrementUserProperty(key: "Total Orders", by: 1)
        incrementUserProperty(key: "Total Spent", by: NSNumber(value: totalAmount))
        setUserProperty(key: "Last Order Date", value: Date())
        setUserProperty(key: "Last Order Amount", value: totalAmount)
        
        // Calculate and update average order value
        if let currentTotal = getUserProperty(key: "Total Spent") as? Double,
           let currentOrders = getUserProperty(key: "Total Orders") as? Int {
            let averageOrderValue = currentTotal / Double(currentOrders)
            setUserProperty(key: "Average Order Value", value: averageOrderValue)
        }
    }
    
    func trackSearchPerformed(searchTerm: String, resultCount: Int) {
        let eventData: [String: Any] = [
            "Search Term": searchTerm,
            "Result Count": resultCount
        ]
        
        CleverTap.sharedInstance()?.recordEvent("Search Performed", withProps: eventData)
        
        // Update user profile with search behavior
        addToMultiValueProperty(key: "Search Terms", value: searchTerm)
        incrementUserProperty(key: "Total Searches", by: 1)
        setUserProperty(key: "Last Search Date", value: Date())
    }
    
    // MARK: - App Events
    
    func trackAppLaunched() {
        CleverTap.sharedInstance()?.recordEvent("App Launched", withProps: [:])
        
        // Update user engagement profile
        incrementUserProperty(key: "App Launches", by: 1)
        setUserProperty(key: "Last App Launch", value: Date() as NSDate)
    }
    
    func trackScreenViewed(screenName: String) {
        let eventData: [String: Any] = [
            "Screen Name": screenName
        ]
        
        CleverTap.sharedInstance()?.recordEvent("Screen Viewed", withProps: eventData)
        
        // Update user profile with screen views
        addToMultiValueProperty(key: "Screens Viewed", value: screenName)
        incrementUserProperty(key: "Total Screen Views", by: 1)
        setUserProperty(key: "Last Screen Viewed", value: screenName)
        setUserProperty(key: "Last Activity", value: Date() as NSDate)
    }
    
    // MARK: - User Engagement
    
    func setUserProperty(key: String, value: Any) {
        let profile = [key: value]
        CleverTap.sharedInstance()?.profilePush(profile)
    }
    
    // MARK: - Enhanced Profile Tracking Methods
    
    func trackCartAddition() {
        incrementUserProperty(key: "Cart Additions", by: 1)
        setUserProperty(key: "Last Cart Addition", value: Date() as NSDate)
    }
    
    func trackSearch() {
        incrementUserProperty(key: "Total Searches", by: 1)
        setUserProperty(key: "Last Search", value: Date() as NSDate)
    }
    
    // MARK: - Profile Validation and Enhanced Tracking
    
    func validateAndUpdateProfile(
        name: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        gender: String? = nil,
        dateOfBirth: Date? = nil,
        location: String? = nil
    ) {
        var profile: [String: Any] = [:]
        
        // Validate and set name
        if let name = name, !name.isEmpty {
            profile["Name"] = name
        }
        
        // Validate and set email
        if let email = email, !email.isEmpty, isValidEmail(email) {
            profile["Email"] = email
        }
        
        // Validate and set phone
        if let phone = phone, !phone.isEmpty {
            // Clean phone number (remove spaces, dashes, etc.)
            let cleanPhone = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
            if cleanPhone.count >= 10 {
                profile["Phone"] = cleanPhone
            }
        }
        
        // Validate and set gender
        if let gender = gender, !gender.isEmpty {
            profile["Gender"] = gender
        }
        
        // Validate and set DOB - CleverTap expects NSDate object
        if let dateOfBirth = dateOfBirth {
            // CleverTap expects DOB as NSDate object for proper dashboard display
            profile["DOB"] = dateOfBirth as NSDate
            
            // Also calculate and set age
            let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
            if age > 0 {
                profile["Age"] = age
            }
        }
        
        // Validate and set location
        if let location = location, !location.isEmpty {
            profile["Location"] = location
        }
        
        // Add profile update timestamp
        profile["Profile Last Updated"] = Date()
        
        // Push to CleverTap
        CleverTap.sharedInstance()?.profilePush(profile)
        
        // Track profile update event
        let eventData: [String: Any] = [
            "Fields Updated": profile.keys.joined(separator: ", "),
            "Update Time": Date(),
            "Profile Completion": calculateProfileCompletionPercentage(profile: profile)
        ]
        
        CleverTap.sharedInstance()?.recordEvent("Profile Updated", withProps: eventData)
        refreshProductExperiences()
    }
    
    // MARK: - Profile Analytics and Insights
    
    func trackProfileCompletion() {
        guard let cleverTapID = CleverTap.sharedInstance()?.profileGetID() else { return }
        
        var completionScore = 0
        var missingFields: [String] = []
        
        // Check essential fields
        if let name = CleverTap.sharedInstance()?.profileGet("Name") as? String, !name.isEmpty {
            completionScore += 20
        } else {
            missingFields.append("Name")
        }
        
        if let email = CleverTap.sharedInstance()?.profileGet("Email") as? String, !email.isEmpty {
            completionScore += 20
        } else {
            missingFields.append("Email")
        }
        
        if let phone = CleverTap.sharedInstance()?.profileGet("Phone") as? String, !phone.isEmpty {
            completionScore += 20
        } else {
            missingFields.append("Phone")
        }
        
        if let dob = CleverTap.sharedInstance()?.profileGet("DOB") {
            completionScore += 20
        } else {
            missingFields.append("Date of Birth")
        }
        
        if let gender = CleverTap.sharedInstance()?.profileGet("Gender") as? String, !gender.isEmpty {
            completionScore += 20
        } else {
            missingFields.append("Gender")
        }
        
        // Update profile with completion data
        let profileData: [String: Any] = [
            "Profile Completion": completionScore,
            "Missing Fields": missingFields,
            "Profile Complete": completionScore == 100,
            "Last Completion Check": Date()
        ]
        
        CleverTap.sharedInstance()?.profilePush(profileData)
        
        // Track completion event
        let eventData: [String: Any] = [
            "Completion Percentage": completionScore,
            "Missing Fields Count": missingFields.count,
            "Missing Fields": missingFields.joined(separator: ", "),
            "CleverTap ID": cleverTapID
        ]
        
        CleverTap.sharedInstance()?.recordEvent("Profile Completion Checked", withProps: eventData)
    }
    
    @discardableResult
    func forceProfileSync() -> Bool {
        // Force sync all profile data to ensure dashboard reflects current state.
        guard let sdk = CleverTap.sharedInstance() else { return false }
        guard let cleverTapID = sdk.profileGetID(), !cleverTapID.isEmpty else { return false }

        let currentProfile: [String: Any] = [
            "Force Sync": true,
            "Sync Timestamp": Date(),
            "CleverTap ID": cleverTapID,
            "Platform": "iOS",
            "App Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        ]

        sdk.profilePush(currentProfile)
        sdk.recordEvent("Profile Force Sync", withProps: currentProfile)
        syncPushIdentityForExtensions()

        // Trigger profile completion check after the profile write is queued.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.trackProfileCompletion()
        }

        return true
    }
    
    // MARK: - Specific DOB Update Method
    
    func updateDateOfBirth(_ dateOfBirth: Date) {
        // Create a focused DOB update
        let profile: [String: Any] = [
            "DOB": dateOfBirth as NSDate,
            "Age": Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0,
            "DOB Updated": Date() as NSDate
        ]
        
        CleverTap.sharedInstance()?.profilePush(profile)
        
        // Track DOB update event
        let eventData: [String: Any] = [
            "DOB": dateOfBirth as NSDate,
            "Age": Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0,
            "Update Time": Date()
        ]
        
        CleverTap.sharedInstance()?.recordEvent("DOB Updated", withProps: eventData)
        
        // Debug log
        print("🎂 DOB Updated in CleverTap:")
        print("📅 Date: \(dateOfBirth)")
        print("🎯 Age: \(Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0)")
    }
    
    // MARK: - Helper Methods

    // MARK: - Test / Debug: Reminder Trigger Event (Safe to remove)
    // This wrapper centralizes event tracking from this service without altering existing logic.
    // Keeping it here avoids direct CleverTap SDK usage from outside.
    func trackEvent(_ name: String, withProps props: [String: Any] = [:]) {
        CleverTap.sharedInstance()?.recordEvent(name, withProps: props)
    }

    /// Fires a deterministic, test-only event to validate CleverTap Reminder campaigns.
    ///
    /// CleverTap Reminder Mapping:
    /// - Event Name: "Reminder Test Triggered"
    /// - Properties:
    ///   - reminder_id : String (identifier to filter/group test runs)
    ///   - due_date    : Date (set to now + 5 minutes)
    ///   - test_mode   : Bool (always true for safety)
    ///   - app_version : String (from app bundle)
    ///
    /// Usage:
    /// Call `CleverTapService.shared.fireReminderTestEvent(reminderId: "test_001")`
    /// then configure a CleverTap Reminder to trigger based on `due_date`
    /// (e.g., send reminder when due_date is within the next few minutes).
    ///
    /// Notes:
    /// - This is a test-only helper and can be safely removed later.
    /// - Does not modify existing profile or authentication logic.
    @discardableResult
    func fireReminderTestEvent(reminderId: String = "test_001") -> Bool {
        guard CleverTap.sharedInstance() != nil else { return false }

        // Calculate due date: current time + 5 minutes, as a Date object for CleverTap Reminders
        let fiveMinutesAhead = Date().addingTimeInterval(5 * 60)
        let dueDate: Date = fiveMinutesAhead

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

        let props: [String: Any] = [
            "reminder_id": reminderId,
            "due_date": dueDate, // Send as Date so CleverTap detects date/time type
            "test_mode": true,
            "app_version": appVersion
        ]

        // Fire the event via the service's wrapper for consistency
        trackEvent("Reminder Test Triggered", withProps: props)
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func calculateProfileCompletionPercentage(profile: [String: Any]) -> Int {
        let essentialFields = ["Name", "Email", "Phone", "DOB", "Gender"]
        let completedFields = essentialFields.filter { profile[$0] != nil }
        return Int((Double(completedFields.count) / Double(essentialFields.count)) * 100)
    }
    
    // MARK: - Debug and Testing Methods
    
    func debugProfileData() {
        guard let cleverTapID = CleverTap.sharedInstance()?.profileGetID() else {
            print("❌ CleverTap ID not found")
            return
        }
        
        print("🔍 CleverTap Profile Debug:")
        print("📱 CleverTap ID: \(cleverTapID)")
        
        let fieldsToCheck = ["Name", "Email", "Phone", "DOB", "Age", "Gender", "Location", "Customer Type"]
        
        for field in fieldsToCheck {
            if let value = CleverTap.sharedInstance()?.profileGet(field) {
                if field == "DOB" {
                    // Special handling for DOB to show format
                    if let dobDate = value as? Date {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        print("✅ \(field): \(formatter.string(from: dobDate)) (NSDate format)")
                    } else {
                        print("✅ \(field): \(value) (Type: \(type(of: value)))")
                    }
                } else {
                    print("✅ \(field): \(value)")
                }
            } else {
                print("❌ \(field): Not set")
            }
        }
        
        // Track debug event
        let debugData: [String: Any] = [
            "Debug Time": Date(),
            "CleverTap ID": cleverTapID,
            "Fields Checked": fieldsToCheck.joined(separator: ", ")
        ]
        
        CleverTap.sharedInstance()?.recordEvent("Profile Debug", withProps: debugData)
    }
} 
