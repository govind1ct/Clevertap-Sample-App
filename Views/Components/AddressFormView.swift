import SwiftUI

struct AddressFormView: View {
    @Binding var address: Address
    var onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Full Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Enter your full name", text: $address.fullName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Street Address
            VStack(alignment: .leading, spacing: 8) {
                Text("Street Address")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Enter your street address", text: $address.streetAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // City
            VStack(alignment: .leading, spacing: 8) {
                Text("City")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Enter your city", text: $address.city)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // State and ZIP
            HStack {
                // State
                VStack(alignment: .leading, spacing: 8) {
                    Text("State")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("State", text: $address.state)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // ZIP Code
                VStack(alignment: .leading, spacing: 8) {
                    Text("ZIP Code")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("ZIP", text: $address.zipCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
            }
            
            // Phone Number
            VStack(alignment: .leading, spacing: 8) {
                Text("Phone Number")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Enter your phone number", text: $address.phoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.phonePad)
            }
            
            // Submit Button
            Button(action: onSubmit) {
                Text("Save Address")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct Address {
    var fullName: String = ""
    var streetAddress: String = ""
    var city: String = ""
    var state: String = ""
    var zipCode: String = ""
    var phoneNumber: String = ""
}

#Preview {
    AddressFormView(
        address: .constant(Address()),
        onSubmit: {}
    )
} 