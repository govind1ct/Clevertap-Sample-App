import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartManager: CartManager
    @State private var showCheckout = false
    @State private var showingDeleteAlert = false
    @State private var productToDelete: Product?
    @Environment(\.colorScheme) var colorScheme

    private let taxRate: Double = 0.18

    private var subtotal: Double { cartManager.total }
    private var tax: Double { (subtotal * taxRate).rounded(.toNearestOrEven) }
    private var total: Double { (subtotal + tax).rounded(.toNearestOrEven) }

    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                colors: [
                    Color("CleverTapPrimary").opacity(0.05),
                    Color("CleverTapSecondary").opacity(0.03),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Section
                headerSection
                
                if cartManager.items.isEmpty {
                    emptyCartView
                } else {
                    cartContentView
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            CleverTapService.shared.trackScreenViewed(screenName: "Cart")
        }
        .alert("Remove Item", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                if let product = productToDelete {
                    cartManager.removeFromCart(product)
                    CleverTapService.shared.setUserProperty(key: "Last Removed Product", value: product.name)
                }
            }
        } message: {
            Text("Are you sure you want to remove this item from your cart?")
        }
        .sheet(isPresented: $showCheckout) {
            CheckoutView()
                .environmentObject(cartManager)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shopping Cart")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("\(cartManager.itemCount) items in cart")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Cart Icon with Badge
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "cart.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                    
                    if cartManager.itemCount > 0 {
                        Text("\(cartManager.itemCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(.red, in: Circle())
                            .offset(x: 8, y: -8)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Empty Cart View
    private var emptyCartView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Empty cart illustration
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("CleverTapPrimary").opacity(0.2),
                                Color("CleverTapSecondary").opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "cart")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                Text("Your cart is empty")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Discover amazing crystals and add them to your cart to get started!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 20)
            }
            
            // Native Display for empty cart recommendations
            CartNativeDisplayView()
                .padding(.horizontal, 20)
            
            // Continue Shopping Button
            NavigationLink(destination: ProductListView()) {
                HStack(spacing: 12) {
                    Image(systemName: "diamond.fill")
                    Text("Start Shopping")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 25)
                )
                .shadow(color: Color("CleverTapPrimary").opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }
    
    // MARK: - Cart Content View
    private var cartContentView: some View {
        VStack(spacing: 0) {
            // Cart Items
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(cartManager.items) { item in
                        ModernCartItemRow(
                            item: item,
                            onQuantityChange: { newQuantity in
                                cartManager.updateQuantity(for: item.product, quantity: newQuantity)
                                CleverTapService.shared.setUserProperty(key: "Last Cart Update", value: Date())
                            },
                            onRemove: {
                                productToDelete = item.product
                                showingDeleteAlert = true
                            }
                        )
                    }
                    
                    // Native Display for cart recommendations
                    NativeDisplayContainerView(
                        location: "cart_recommendations",
                        maxDisplayUnits: 1,
                        layout: .vertical
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            
            // Cart Summary and Checkout
            cartSummarySection
        }
    }
    
    // MARK: - Cart Summary Section
    private var cartSummarySection: some View {
        VStack(spacing: 20) {
            // Summary Card
            VStack(spacing: 16) {
                HStack {
                    Text("Order Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    SummaryRow(title: "Subtotal", value: "₹\(Int(subtotal))")
                    SummaryRow(title: "Shipping", value: "Free")
                    SummaryRow(title: "Tax", value: "₹\(Int(tax))")
                    
                    Divider()
                        .background(.secondary.opacity(0.3))
                    
                    HStack {
                        Text("Total")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        Text("₹\(Int(total))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            
            // Checkout Button
            Button(action: {
                showCheckout = true
                CleverTapService.shared.setUserProperty(key: "Checkout Initiated", value: Date())
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "creditcard.fill")
                    Text("Proceed to Checkout")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 25)
                )
                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Supporting Views

struct ModernCartItemRow: View {
    let item: CartItem
    let onQuantityChange: (Int) -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Product Image
            AppAsyncImage(urlString: item.product.images.first) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                } else if phase.error != nil {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary.opacity(0.5))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Product Info
            VStack(alignment: .leading, spacing: 8) {
                Text(item.product.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text("₹\(Int(item.product.price)) each")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    // Quantity Controls
                    HStack(spacing: 12) {
                        Button(action: {
                            if item.quantity > 1 {
                                onQuantityChange(item.quantity - 1)
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .frame(width: 28, height: 28)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .disabled(item.quantity <= 1)
                        
                        Text("\(item.quantity)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(minWidth: 20)
                        
                        Button(action: {
                            if item.quantity < 99 {
                                onQuantityChange(item.quantity + 1)
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .frame(width: 28, height: 28)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .disabled(item.quantity >= 99)
                    }
                    
                    Spacer()
                    
                    // Remove Button
                    Button(action: onRemove) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(width: 28, height: 28)
                            .background(.red.opacity(0.1), in: Circle())
                    }
                }
            }
            
            // Total Price
            VStack(alignment: .trailing, spacing: 4) {
                Text("₹\(Int(item.product.price * Double(item.quantity)))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                if item.quantity > 1 {
                    Text("(\(item.quantity) items)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
} 
