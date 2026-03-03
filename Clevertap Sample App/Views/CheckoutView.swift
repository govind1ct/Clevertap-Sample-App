import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var orderService = OrderService()
    @State private var showSuccess = false
    @State private var addressFullName: String = ""
    @State private var addressStreet: String = ""
    @State private var addressCity: String = ""
    @State private var addressPincode: String = ""
    @State private var paymentMethod: String = "Cash on Delivery"
    @State private var showAddressEdit = false
    @State private var showPaymentEdit = false
    @State private var isPlacingOrder = false
    @State private var errorMessage: String?
    @State private var showBanner = false
    @State private var bannerType: BannerType = .success
    @State private var bannerTitle = ""
    @State private var bannerMessage = ""
    @State private var isValidatingPincode = false
    @State private var pincodeValidationError: String?
    @State private var pincodeValidationInfo: String?
    @State private var lastValidatedPincode: String = ""
    @State private var pendingPayUOrderContext: PendingPayUOrderContext?

    private struct PendingPayUOrderContext {
        let userId: String
        let userEmail: String?
        let normalizedPincode: String
    }

    // MARK: - Helpers
    private let supportedPaymentMethods: [String] = ["Cash on Delivery", "UPI", "Credit/Debit Card", "PayU (Online)"]
    private let taxRate: Double = 0.18

    private var subtotal: Double { cartManager.total }
    private var tax: Double { (subtotal * taxRate).rounded(.toNearestOrEven) }
    private var total: Double { (subtotal + tax).rounded(.toNearestOrEven) }

    private var currencyFormatter: NumberFormatter {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = "INR"
        nf.maximumFractionDigits = 0
        return nf
    }

    private var addressSummary: String {
        var lines: [String] = []
        if !addressFullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append(addressFullName.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if !addressStreet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append(addressStreet.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        var cityLineParts: [String] = []
        if !addressCity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            cityLineParts.append(addressCity.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if !addressPincode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            cityLineParts.append(addressPincode.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if !cityLineParts.isEmpty {
            lines.append(cityLineParts.joined(separator: " - "))
        }
        return lines.joined(separator: "\n")
    }

    private var sanitizedPincode: String {
        addressPincode.filter(\.isNumber)
    }

    private var localValidationError: String? {
        if cartManager.items.isEmpty {
            return "Your cart is empty."
        }
        if addressFullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Please enter full name."
        }
        if addressStreet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Please enter street address."
        }
        if addressCity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Please enter city."
        }
        if sanitizedPincode.count != 6 {
            return "Please enter a valid 6-digit pincode."
        }
        if !supportedPaymentMethods.contains(paymentMethod) {
            return "Please select a supported payment method."
        }
        return nil
    }

    private var isCheckoutValid: Bool {
        localValidationError == nil
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                BannerNotification(title: bannerTitle, message: bannerMessage, type: bannerType, isVisible: $showBanner)
                    .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Checkout")
                                .font(.largeTitle.bold())
                            Text("Review your order and confirm payment")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 10)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("\(cartManager.items.count) item\(cartManager.items.count == 1 ? "" : "s")", systemImage: "bag")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(currencyFormatter.string(from: NSNumber(value: total)) ?? "₹\(Int(total))")
                                    .font(.title3.bold())
                            }
                            .foregroundStyle(.primary)
                            Text("Total payable including tax")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Order Summary")
                                .font(.headline)
                            ForEach(cartManager.items) { item in
                                HStack(spacing: 12) {
                                    AppAsyncImage(urlString: item.product.images.first) { phase in
                                        if let image = phase.image {
                                            image.resizable().aspectRatio(1, contentMode: .fill)
                                        } else {
                                            Color(.systemGray5)
                                        }
                                    }
                                    .frame(width: 52, height: 52)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.product.name)
                                            .font(.subheadline.weight(.semibold))
                                            .lineLimit(1)
                                        Text("Qty \(item.quantity)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(currencyFormatter.string(from: NSNumber(value: item.product.price * Double(item.quantity))) ?? "₹\(Int(item.product.price * Double(item.quantity)))")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Delivery Address")
                                    .font(.headline)
                                Spacer()
                                Button("Edit") { showAddressEdit = true }
                                    .font(.subheadline.weight(.semibold))
                            }
                            if addressSummary.isEmpty {
                                Text("Add your delivery address")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text(addressSummary)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            if let pincodeInfo = pincodeValidationInfo {
                                Label(pincodeInfo, systemImage: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            if let pincodeError = pincodeValidationError {
                                Label(pincodeError, systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                        .sheet(isPresented: $showAddressEdit) {
                            EditAddressSheet(
                                fullName: $addressFullName,
                                street: $addressStreet,
                                city: $addressCity,
                                pincode: $addressPincode
                            )
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Payment Method")
                                    .font(.headline)
                                Spacer()
                                Button("Edit") { showPaymentEdit = true }
                                    .font(.subheadline.weight(.semibold))
                            }
                            Text(paymentMethod)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                        .sheet(isPresented: $showPaymentEdit) {
                            PaymentMethodSheet(selected: $paymentMethod)
                        }

                        VStack(spacing: 10) {
                            HStack {
                                Text("Subtotal")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(currencyFormatter.string(from: NSNumber(value: subtotal)) ?? "₹\(Int(subtotal))")
                            }
                            HStack {
                                Text("Shipping")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Free")
                                    .foregroundColor(.green)
                            }
                            HStack {
                                Text("Tax (18%)")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(currencyFormatter.string(from: NSNumber(value: tax)) ?? "₹\(Int(tax))")
                            }
                            Divider().padding(.vertical, 2)
                            HStack {
                                Text("Total")
                                    .font(.headline)
                                Spacer()
                                Text(currencyFormatter.string(from: NSNumber(value: total)) ?? "₹\(Int(total))")
                                    .font(.headline)
                            }
                        }
                        .font(.subheadline.weight(.medium))
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )

                        if let error = errorMessage {
                            Label(error, systemImage: "exclamationmark.circle.fill")
                                .font(.footnote)
                                .foregroundColor(.red)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 120)
                }
            }
        }
        .onAppear {
            // Optionally preload cached address/payment from local storage
            if addressFullName.isEmpty {
                addressFullName = UserDefaults.standard.string(forKey: "checkout.address.fullName") ?? ""
            }
            if addressStreet.isEmpty {
                addressStreet = UserDefaults.standard.string(forKey: "checkout.address.street") ?? ""
            }
            if addressCity.isEmpty {
                addressCity = UserDefaults.standard.string(forKey: "checkout.address.city") ?? ""
            }
            if addressPincode.isEmpty {
                addressPincode = UserDefaults.standard.string(forKey: "checkout.address.pincode") ?? ""
            }
            // Backwards compatibility: if old single-line address exists and no structured street yet
            if addressStreet.isEmpty,
               let legacyAddress = UserDefaults.standard.string(forKey: "checkout.address"),
               !legacyAddress.isEmpty {
                addressStreet = legacyAddress
            }
            if let cachedPayment = UserDefaults.standard.string(forKey: "checkout.paymentMethod"), supportedPaymentMethods.contains(cachedPayment) {
                paymentMethod = cachedPayment
            }
        }
        .onChange(of: addressPincode) { _, _ in
            pincodeValidationError = nil
            pincodeValidationInfo = nil
            lastValidatedPincode = ""
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                HStack {
                    Text("Payable")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(currencyFormatter.string(from: NSNumber(value: total)) ?? "₹\(Int(total))")
                        .font(.headline)
                }
                Button(action: placeOrder) {
                    if isPlacingOrder || isValidatingPincode {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        Text("Place Order")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(!isCheckoutValid || isPlacingOrder || isValidatingPincode)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $showSuccess) {
            OrderSuccessView()
        }
    }

    func placeOrder() {
        guard let user = authViewModel.user else {
            errorMessage = "You must be logged in to place an order."
            bannerType = .error
            bannerTitle = "Login Required"
            bannerMessage = "Please log in to place an order."
            showBanner = true
            return
        }
        guard localValidationError == nil else {
            errorMessage = localValidationError
            bannerType = .error
            bannerTitle = "Checkout Incomplete"
            bannerMessage = errorMessage ?? ""
            showBanner = true
            return
        }

        let normalizedPincode = sanitizedPincode
        isPlacingOrder = true
        isValidatingPincode = true
        errorMessage = nil
        pincodeValidationError = nil

        Task {
            do {
                let validationResult: PincodeValidationResult
                if lastValidatedPincode == normalizedPincode, let existingInfo = pincodeValidationInfo, !existingInfo.isEmpty {
                    validationResult = PincodeValidationResult(
                        pincode: normalizedPincode,
                        district: "",
                        state: "",
                        postOfficeName: ""
                    )
                } else {
                    validationResult = try await PincodeValidationService.shared.validatePincode(normalizedPincode)
                }

                await MainActor.run {
                    lastValidatedPincode = normalizedPincode
                    if !validationResult.district.isEmpty, !validationResult.state.isEmpty {
                        pincodeValidationInfo = "Pincode verified: \(validationResult.district), \(validationResult.state)"
                    } else {
                        pincodeValidationInfo = "Pincode verified."
                    }
                    isValidatingPincode = false
                }

                if paymentMethod == "PayU (Online)" {
                    await beginPayUCheckout(
                        userId: user.uid,
                        userEmail: user.email,
                        normalizedPincode: normalizedPincode
                    )
                } else {
                    placeOrderAfterValidation(
                        userId: user.uid,
                        userEmail: user.email,
                        normalizedPincode: normalizedPincode
                    )
                }
            } catch {
                await MainActor.run {
                    isPlacingOrder = false
                    isValidatingPincode = false
                    let message = error.localizedDescription
                    errorMessage = message
                    pincodeValidationError = message
                    bannerType = .error
                    bannerTitle = "Pincode Validation Failed"
                    bannerMessage = message
                    showBanner = true
                }
            }
        }
    }

    @MainActor
    private func handlePayUCheckoutResult(_ result: PayUCheckoutOutcome) {
        switch result {
        case .success:
            guard let context = pendingPayUOrderContext else {
                isPlacingOrder = false
                errorMessage = "Payment succeeded, but order context is missing."
                bannerType = .error
                bannerTitle = "Order Failed"
                bannerMessage = errorMessage ?? ""
                showBanner = true
                return
            }

            isPlacingOrder = true
            pendingPayUOrderContext = nil
            placeOrderAfterValidation(
                userId: context.userId,
                userEmail: context.userEmail,
                normalizedPincode: context.normalizedPincode
            )

        case .failure(let message):
            isPlacingOrder = false
            pendingPayUOrderContext = nil
            errorMessage = message
            bannerType = .error
            bannerTitle = "Payment Failed"
            bannerMessage = message
            showBanner = true

        case .cancelled:
            isPlacingOrder = false
            pendingPayUOrderContext = nil
            errorMessage = "Payment was cancelled."
            bannerType = .error
            bannerTitle = "Payment Cancelled"
            bannerMessage = errorMessage ?? ""
            showBanner = true
        }
    }

    private func beginPayUCheckout(userId: String, userEmail: String?, normalizedPincode: String) async {
        let primaryProductName = cartManager.items.first?.product.name ?? "Order Payment"
        let email = (userEmail?.isEmpty == false) ? (userEmail ?? "") : "customer@example.com"
        let phone = "9999999999"

        do {
            pendingPayUOrderContext = PendingPayUOrderContext(
                userId: userId,
                userEmail: userEmail,
                normalizedPincode: normalizedPincode
            )

            _ = try await PayUService.shared.startCheckout(
                amount: total,
                productInfo: primaryProductName,
                firstName: addressFullName,
                email: email,
                phone: phone,
                userIdentifier: userId
            ) { result in
                Task { @MainActor in
                    self.handlePayUCheckoutResult(result)
                }
            }
            await MainActor.run {
                isPlacingOrder = false
            }
        } catch {
            await MainActor.run {
                isPlacingOrder = false
                pendingPayUOrderContext = nil
                errorMessage = error.localizedDescription
                bannerType = .error
                bannerTitle = "PayU Setup Failed"
                bannerMessage = error.localizedDescription
                showBanner = true
            }
        }
    }

    private func placeOrderAfterValidation(userId: String, userEmail: String?, normalizedPincode: String) {
        let order = Order(
            id: nil,
            userId: userId,
            userEmail: userEmail,
            items: cartManager.items,
            address: addressSummary,
            shippingName: addressFullName,
            shippingStreet: addressStreet,
            shippingCity: addressCity,
            shippingPincode: normalizedPincode,
            paymentMethod: paymentMethod,
            total: total,
            status: "Placed",
            createdAt: Date()
        )
        // Persist user preferences locally
        UserDefaults.standard.set(addressFullName, forKey: "checkout.address.fullName")
        UserDefaults.standard.set(addressStreet, forKey: "checkout.address.street")
        UserDefaults.standard.set(addressCity, forKey: "checkout.address.city")
        UserDefaults.standard.set(normalizedPincode, forKey: "checkout.address.pincode")
        // Legacy combined address for backward compatibility
        UserDefaults.standard.set(addressSummary, forKey: "checkout.address")
        UserDefaults.standard.set(paymentMethod, forKey: "checkout.paymentMethod")

        orderService.placeOrder(order: order) { result in
            DispatchQueue.main.async {
                isPlacingOrder = false
                switch result {
                case .success(let persistedOrderId):
                    showSuccess = true
                    
                    // Track order placed with CleverTap
                    let products = cartManager.items.map { item in
                        return [
                            "Product ID": item.product.id ?? "",
                            "Product Name": item.product.name,
                            "Category": item.product.category,
                            "Price": item.product.price,
                            "Quantity": item.quantity
                        ]
                    }
                    
                    CleverTapService.shared.trackOrderPlaced(
                        orderId: persistedOrderId,
                        totalAmount: total,
                        itemCount: cartManager.items.count,
                        products: products
                    )
                    
                    // Keep only non-duplicative profile updates here.
                    // `trackOrderPlaced` already updates Total Orders/Total Spent/Last Order Date.
                    CleverTapService.shared.setUserProperty(key: "Preferred Payment Method", value: paymentMethod)
                    
                    bannerType = .success
                    bannerTitle = "Order Placed!"
                    bannerMessage = "Thank you for your order."
                    showBanner = true

                    cartManager.items.removeAll()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    bannerType = .error
                    bannerTitle = "Order Failed"
                    bannerMessage = error.localizedDescription
                    showBanner = true
                }
            }
        }
    }
}

struct EditAddressSheet: View {
    @Binding var fullName: String
    @Binding var street: String
    @Binding var city: String
    @Binding var pincode: String
    @Environment(\.presentationMode) var presentationMode
    @State private var isValidatingPincode = false
    @State private var pincodeInfoMessage: String?
    @State private var pincodeErrorMessage: String?
    @State private var suggestedCity: String?
    @State private var lastAutoValidatedPincode: String = ""
    @FocusState private var focusedField: AddressField?

    private enum AddressField {
        case fullName
        case street
        case city
        case pincode
    }

    private var normalizedFullName: String {
        fullName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedStreet: String {
        street.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedCity: String {
        city.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedPincode: String {
        pincode.filter(\.isNumber)
    }

    private var isFormValid: Bool {
        !normalizedFullName.isEmpty &&
        !normalizedStreet.isEmpty &&
        !normalizedCity.isEmpty &&
        normalizedPincode.count == 6
    }

    private var formValidationMessage: String? {
        if normalizedFullName.isEmpty { return "Full name is required." }
        if normalizedStreet.isEmpty { return "Street address is required." }
        if normalizedCity.isEmpty { return "City is required." }
        if normalizedPincode.count != 6 { return "Pincode must be 6 digits." }
        return nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Delivery Address")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Add accurate details for faster delivery.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Recipient")
                                .font(.headline)
                            
                            textField(
                                title: "Full Name",
                                text: $fullName,
                                contentType: .name,
                                keyboard: .default,
                                submitLabel: .next
                            )
                            .focused($focusedField, equals: .fullName)
                            .onSubmit { focusedField = .street }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Address Details")
                                .font(.headline)
                            
                            textField(
                                title: "Street Address",
                                text: $street,
                                contentType: .fullStreetAddress,
                                keyboard: .default,
                                submitLabel: .next
                            )
                            .focused($focusedField, equals: .street)
                            .onSubmit { focusedField = .city }
                            
                            textField(
                                title: "City",
                                text: $city,
                                contentType: .addressCity,
                                keyboard: .default,
                                submitLabel: .next
                            )
                            .focused($focusedField, equals: .city)
                            .onSubmit { focusedField = .pincode }
                            
                            textField(
                                title: "Pincode",
                                text: $pincode,
                                contentType: .postalCode,
                                keyboard: .numberPad,
                                submitLabel: .done
                            )
                            .focused($focusedField, equals: .pincode)
                            
                            Button {
                                verifyAndAutofillPincode(updateLastAutoValidated: true)
                            } label: {
                                HStack {
                                    if isValidatingPincode {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Image(systemName: "checkmark.seal")
                                    }
                                    Text(isValidatingPincode ? "Verifying..." : "Verify & Auto-fill City")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isValidatingPincode)
                            
                            if let info = pincodeInfoMessage {
                                Label(info, systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            
                            if let error = pincodeErrorMessage {
                                Label(error, systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            
                            if let suggestedCity {
                                Text("Suggested city: \(suggestedCity)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        
                        HStack(spacing: 10) {
                            Image(systemName: formValidationMessage == nil ? "checkmark.circle.fill" : "exclamationmark.circle")
                                .foregroundColor(formValidationMessage == nil ? .green : .orange)
                            Text(formValidationMessage ?? "Address looks good.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.tertiarySystemGroupedBackground))
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Edit Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        fullName = normalizedFullName
                        street = normalizedStreet
                        city = normalizedCity
                        pincode = normalizedPincode
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!isFormValid || isValidatingPincode)
                }
            }
        }
        .onChange(of: pincode) { _, newValue in
            autoValidatePincodeIfReady(newValue)
        }
    }

    private func autoValidatePincodeIfReady(_ rawValue: String) {
        let normalized = rawValue.filter(\.isNumber)
        if normalized != rawValue {
            pincode = normalized
            return
        }

        guard normalized.count == 6 else { return }
        guard normalized != lastAutoValidatedPincode else { return }
        guard !isValidatingPincode else { return }

        verifyAndAutofillPincode(updateLastAutoValidated: true)
    }

    private func verifyAndAutofillPincode(updateLastAutoValidated: Bool) {
        let normalizedPincode = pincode.filter(\.isNumber)
        pincode = normalizedPincode
        pincodeInfoMessage = nil
        pincodeErrorMessage = nil
        suggestedCity = nil

        guard normalizedPincode.count == 6 else {
            pincodeErrorMessage = "Please enter a valid 6-digit pincode."
            return
        }

        isValidatingPincode = true

        Task {
            do {
                let result = try await PincodeValidationService.shared.validatePincode(normalizedPincode)
                let autofillCity = "\(result.district), \(result.state)"

                await MainActor.run {
                    city = autofillCity
                    suggestedCity = autofillCity
                    pincodeInfoMessage = "Verified: \(result.postOfficeName), \(autofillCity)"
                    if updateLastAutoValidated {
                        lastAutoValidatedPincode = normalizedPincode
                    }
                    isValidatingPincode = false
                }
            } catch {
                await MainActor.run {
                    pincodeErrorMessage = error.localizedDescription
                    isValidatingPincode = false
                }
            }
        }
    }
    
    private func textField(
        title: String,
        text: Binding<String>,
        contentType: UITextContentType?,
        keyboard: UIKeyboardType,
        submitLabel: SubmitLabel
    ) -> some View {
        TextField(title, text: text)
            .textContentType(contentType)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .keyboardType(keyboard)
            .submitLabel(submitLabel)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
            )
    }
}

struct PaymentMethodSheet: View {
    @Binding var selected: String
    @Environment(\.presentationMode) var presentationMode
    let methods = ["Cash on Delivery", "UPI", "Credit/Debit Card", "PayU (Online)"]
    var body: some View {
        NavigationView {
            List {
                Section(footer: Text("Supported methods vary by region and availability.")) {
                    ForEach(methods, id: \.self) { method in
                        HStack {
                            Text(method)
                            Spacer()
                            if selected == method {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selected = method
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .navigationBarTitle("Select Payment Method", displayMode: .inline)
        }
    }
}

struct OrderSuccessView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
            Text("Order Placed!")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Thank you for shopping with us.\nYour order will be delivered soon.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            Spacer()
            Button("Continue Shopping") {
                presentationMode.wrappedValue.dismiss()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(14)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
} 
