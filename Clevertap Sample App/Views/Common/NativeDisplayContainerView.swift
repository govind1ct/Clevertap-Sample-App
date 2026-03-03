import SwiftUI
import CleverTapSDK

struct NativeDisplayContainerView: View {
    let location: String
    let maxDisplayUnits: Int
    let layout: NativeDisplayLayout
    
    @StateObject private var nativeDisplayService = CleverTapNativeDisplayService.shared
    
    init(location: String = "home", maxDisplayUnits: Int = 3, layout: NativeDisplayLayout = .vertical) {
        self.location = location
        self.maxDisplayUnits = maxDisplayUnits
        self.layout = layout
    }
    
    var filteredDisplayUnits: [CleverTapDisplayUnit] {
        let units = nativeDisplayService.getDisplayUnitsForLocation(location)
        return Array(units.prefix(maxDisplayUnits))
    }
    
    var body: some View {
        Group {
            if !filteredDisplayUnits.isEmpty {
                switch layout {
                case .vertical:
                    LazyVStack(spacing: 16) {
                        ForEach(Array(filteredDisplayUnits.enumerated()), id: \.offset) { index, displayUnit in
                            NativeDisplayView(displayUnit: displayUnit)
                        }
                    }
                    
                case .horizontal:
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(Array(filteredDisplayUnits.enumerated()), id: \.offset) { index, displayUnit in
                                NativeDisplayView(displayUnit: displayUnit)
                                    .frame(width: 300)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                case .grid:
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(Array(filteredDisplayUnits.enumerated()), id: \.offset) { index, displayUnit in
                            NativeDisplayView(displayUnit: displayUnit)
                        }
                    }
                    
                case .carousel:
                    TabView {
                        ForEach(Array(filteredDisplayUnits.enumerated()), id: \.offset) { index, displayUnit in
                            NativeDisplayView(displayUnit: displayUnit)
                                .padding(.horizontal)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(height: 300)
                }
            } else if nativeDisplayService.isLoading {
                // Loading state
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Loading content...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
                .frame(height: 100)
            }
            // If no display units and not loading, show nothing (empty state)
        }
        .onAppear {
            nativeDisplayService.refreshDisplayUnits()
        }
    }
}

enum NativeDisplayLayout {
    case vertical
    case horizontal
    case grid
    case carousel
}

// MARK: - Specialized Native Display Views for different locations

struct HomeNativeDisplayView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Hero banner at top
            NativeDisplayContainerView(
                location: "hero",
                maxDisplayUnits: 1,
                layout: .carousel
            )
            
            // Promotional content in horizontal scroll
            if !CleverTapNativeDisplayService.shared.getDisplayUnitsForLocation("promotion").isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Special Offers")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    NativeDisplayContainerView(
                        location: "promotion",
                        maxDisplayUnits: 5,
                        layout: .horizontal
                    )
                }
            }
            
            // General home content
            NativeDisplayContainerView(
                location: "home",
                maxDisplayUnits: 3,
                layout: .vertical
            )
        }
    }
}

struct ProductListNativeDisplayView: View {
    var body: some View {
        NativeDisplayContainerView(
            location: "product_list",
            maxDisplayUnits: 2,
            layout: .vertical
        )
    }
}

struct CartNativeDisplayView: View {
    var body: some View {
        NativeDisplayContainerView(
            location: "cart",
            maxDisplayUnits: 1,
            layout: .vertical
        )
    }
}

struct ProfileNativeDisplayView: View {
    var body: some View {
        NativeDisplayContainerView(
            location: "profile",
            maxDisplayUnits: 2,
            layout: .vertical
        )
    }
}

// MARK: - Native Display Management View

struct NativeDisplayManagementView: View {
    @StateObject private var nativeDisplayService = CleverTapNativeDisplayService.shared
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Display Units Status")) {
                    HStack {
                        Text("Total Units")
                        Spacer()
                        Text("\(nativeDisplayService.displayUnits.count)")
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Loading")
                        Spacer()
                        if nativeDisplayService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(0.8)
                        } else {
                            Text("Ready")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Section(header: Text("Actions")) {
                    Button("Refresh Display Units") {
                        nativeDisplayService.refreshDisplayUnits()
                    }
                    
                    Button("Clear Cache") {
                        // This would clear any cached display units
                        nativeDisplayService.displayUnits.removeAll()
                    }
                }
                
                if !nativeDisplayService.displayUnits.isEmpty {
                    Section(header: Text("Active Display Units")) {
                        ForEach(Array(nativeDisplayService.displayUnits.enumerated()), id: \.offset) { index, displayUnit in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(displayUnit.unitID ?? "Unknown ID")
                                    .font(.headline)
                                
                                Text("Type: \(displayUnit.type ?? "Unknown")")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                if let customExtras = displayUnit.customExtras,
                                   let location = customExtras["location"] as? String {
                                    Text("Location: \(location)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Native Display")
            .refreshable {
                nativeDisplayService.refreshDisplayUnits()
            }
        }
    }
}

struct NativeDisplayContainerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            NativeDisplayContainerView(location: "home")
            Spacer()
        }
        .padding()
    }
} 