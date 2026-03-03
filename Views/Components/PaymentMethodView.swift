import SwiftUI

struct PaymentMethodView: View {
    @Binding var selectedMethod: PaymentMethod
    var onSelect: (PaymentMethod) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(PaymentMethod.allCases, id: \.self) { method in
                PaymentMethodRow(
                    method: method,
                    isSelected: selectedMethod == method,
                    onSelect: {
                        selectedMethod = method
                        onSelect(method)
                    }
                )
            }
        }
        .padding()
    }
}

struct PaymentMethodRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                // Payment Method Icon
                Image(systemName: method.icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 40)
                
                // Payment Method Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.title)
                        .font(.headline)
                    
                    Text(method.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum PaymentMethod: CaseIterable {
    case creditCard
    case paypal
    case applePay
    
    var title: String {
        switch self {
        case .creditCard:
            return "Credit Card"
        case .paypal:
            return "PayPal"
        case .applePay:
            return "Apple Pay"
        }
    }
    
    var description: String {
        switch self {
        case .creditCard:
            return "Pay with your credit card"
        case .paypal:
            return "Pay with your PayPal account"
        case .applePay:
            return "Pay with Apple Pay"
        }
    }
    
    var icon: String {
        switch self {
        case .creditCard:
            return "creditcard.fill"
        case .paypal:
            return "p.circle.fill"
        case .applePay:
            return "apple.logo"
        }
    }
}

#Preview {
    PaymentMethodView(
        selectedMethod: .constant(.creditCard),
        onSelect: { _ in }
    )
} 