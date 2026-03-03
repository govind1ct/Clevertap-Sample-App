import Foundation
import CleverTapSDK
import SwiftUI

class CleverTapNativeDisplayService: NSObject, ObservableObject, CleverTapDisplayUnitDelegate {
    static let shared = CleverTapNativeDisplayService()
    
    @Published var displayUnits: [CleverTapDisplayUnit] = []
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    
    // Location-based display units cache
    private var locationBasedUnits: [String: [CleverTapDisplayUnit]] = [:]
    
    private override init() {
        super.init()
        setupDisplayUnitDelegate()
        refreshDisplayUnits()
    }
    
    // MARK: - Setup
    
    private func setupDisplayUnitDelegate() {
        CleverTap.sharedInstance()?.setDisplayUnitDelegate(self)
        print("✅ CleverTap Native Display delegate set up successfully")
    }
    
    // MARK: - CleverTapDisplayUnitDelegate
    
    func displayUnitsUpdated(_ displayUnits: [CleverTapDisplayUnit]) {
        DispatchQueue.main.async {
            self.displayUnits = displayUnits
            self.isLoading = false
            self.lastUpdated = Date()
            
            // Update location-based cache
            self.updateLocationBasedCache()
            
            // Track display units received
            let eventData: [String: Any] = [
                "Display Units Count": displayUnits.count,
                "Unit IDs": displayUnits.compactMap { $0.unitID },
                "Locations": self.getAvailableLocations()
            ]
            CleverTap.sharedInstance()?.recordEvent("Native Display Units Received", withProps: eventData)
            
            print("📱 Received \(displayUnits.count) native display units")
            self.logDisplayUnitsDetails()
        }
    }
    
    // MARK: - Public Methods
    
    func getAllDisplayUnits() -> [CleverTapDisplayUnit] {
        return CleverTap.sharedInstance()?.getAllDisplayUnits() ?? []
    }
    
    func getDisplayUnit(for unitID: String) -> CleverTapDisplayUnit? {
        return CleverTap.sharedInstance()?.getDisplayUnit(forID: unitID)
    }
    
    func recordDisplayUnitViewed(unitID: String) {
        CleverTap.sharedInstance()?.recordDisplayUnitViewedEvent(forID: unitID)
        
        // Track in our analytics
        let eventData: [String: Any] = [
            "Unit ID": unitID,
            "Action": "Viewed",
            "Timestamp": Date().timeIntervalSince1970
        ]
        CleverTap.sharedInstance()?.recordEvent("Native Display Interaction", withProps: eventData)
        print("👁️ Native Display Unit Viewed: \(unitID)")
    }
    
    func recordDisplayUnitClicked(unitID: String) {
        CleverTap.sharedInstance()?.recordDisplayUnitClickedEvent(forID: unitID)
        
        // Track in our analytics
        let eventData: [String: Any] = [
            "Unit ID": unitID,
            "Action": "Clicked",
            "Timestamp": Date().timeIntervalSince1970
        ]
        CleverTap.sharedInstance()?.recordEvent("Native Display Interaction", withProps: eventData)
        print("🖱️ Native Display Unit Clicked: \(unitID)")
    }
    
    func refreshDisplayUnits() {
        isLoading = true
        displayUnits = getAllDisplayUnits()
        updateLocationBasedCache()
        isLoading = false
        print("🔄 Native Display Units refreshed")
    }
    
    // MARK: - Location-based Methods
    
    func getDisplayUnitsForLocation(_ location: String) -> [CleverTapDisplayUnit] {
        return locationBasedUnits[location] ?? []
    }
    
    func hasDisplayUnitsForLocation(_ location: String) -> Bool {
        return !getDisplayUnitsForLocation(location).isEmpty
    }
    
    func getAvailableLocations() -> [String] {
        return Array(locationBasedUnits.keys).sorted()
    }
    
    // MARK: - Type-based Methods
    
    func getDisplayUnitsForType(_ type: String) -> [CleverTapDisplayUnit] {
        return displayUnits.filter { $0.type == type }
    }
    
    // MARK: - Content Analysis Methods
    
    func getDisplayUnitsWithImages() -> [CleverTapDisplayUnit] {
        return displayUnits.filter { unit in
            guard let contents = unit.contents else { return false }
            return contents.contains { content in
                content.mediaIsImage || content.mediaIsGif
            }
        }
    }
    
    func getDisplayUnitsWithVideos() -> [CleverTapDisplayUnit] {
        return displayUnits.filter { unit in
            guard let contents = unit.contents else { return false }
            return contents.contains { $0.mediaIsVideo }
        }
    }
    
    // MARK: - Convenience Tracking Methods
    
    func trackDisplayUnitViewed(_ displayUnit: CleverTapDisplayUnit) {
        guard let unitID = displayUnit.unitID else {
            print("⚠️ Cannot track view for display unit without ID")
            return
        }
        recordDisplayUnitViewed(unitID: unitID)
    }
    
    func trackDisplayUnitClicked(_ displayUnit: CleverTapDisplayUnit, content: CleverTapDisplayUnitContent? = nil) {
        guard let unitID = displayUnit.unitID else {
            print("⚠️ Cannot track click for display unit without ID")
            return
        }
        recordDisplayUnitClicked(unitID: unitID)
        
        // Additional tracking for content-specific clicks
        if let content = content {
            let eventData: [String: Any] = [
                "Unit ID": unitID,
                "Content Title": content.title ?? "N/A",
                "Content Action URL": content.actionUrl ?? "N/A",
                "Action": "Content Clicked",
                "Timestamp": Date().timeIntervalSince1970
            ]
            CleverTap.sharedInstance()?.recordEvent("Native Display Content Interaction", withProps: eventData)
            print("🖱️ Native Display Content Clicked: \(content.title ?? "Unknown")")
        }
    }
    
    // MARK: - Private Methods
    
    private func updateLocationBasedCache() {
        locationBasedUnits.removeAll()
        
        for unit in displayUnits {
            // Check custom extras for location
            if let customExtras = unit.customExtras,
               let location = customExtras["location"] as? String {
                if locationBasedUnits[location] == nil {
                    locationBasedUnits[location] = []
                }
                locationBasedUnits[location]?.append(unit)
            }
            
            // Also check unit type as potential location
            if let type = unit.type {
                if locationBasedUnits[type] == nil {
                    locationBasedUnits[type] = []
                }
                locationBasedUnits[type]?.append(unit)
            }
        }
    }
    
    private func logDisplayUnitsDetails() {
        print("📊 Native Display Units Details:")
        for (index, unit) in displayUnits.enumerated() {
            print("  Unit \(index + 1):")
            print("    ID: \(unit.unitID ?? "N/A")")
            print("    Type: \(unit.type ?? "N/A")")
            print("    Background: \(unit.bgColor ?? "N/A")")
            print("    Contents: \(unit.contents?.count ?? 0)")
            
            if let customExtras = unit.customExtras {
                print("    Custom Extras: \(customExtras)")
            }
            
            if let contents = unit.contents {
                for (contentIndex, content) in contents.enumerated() {
                    print("      Content \(contentIndex + 1):")
                    print("        Title: \(content.title ?? "N/A")")
                    print("        Message: \(content.message ?? "N/A")")
                    print("        Media URL: \(content.mediaUrl ?? "N/A")")
                    print("        Action URL: \(content.actionUrl ?? "N/A")")
                }
            }
        }
    }
    
    // MARK: - Testing Methods (for development)
    
    func triggerTestEvent(for location: String) {
        let eventData: [String: Any] = [
            "location": location,
            "timestamp": Date().timeIntervalSince1970,
            "user_type": "premium"
        ]
        CleverTap.sharedInstance()?.recordEvent("Native Display Test", withProps: eventData)
        print("🧪 Test event triggered for location: \(location)")
    }
} 