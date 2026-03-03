import SwiftUI

struct CategoryFilterButton: View {
    let category: ProductCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: category.icon)
                Text(category.rawValue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
            .foregroundColor(isSelected ? .white : .accentColor)
            .cornerRadius(20)
        }
    }
}

#Preview {
    HStack {
        CategoryFilterButton(
            category: .crystals,
            isSelected: true,
            action: {}
        )
        
        CategoryFilterButton(
            category: .jewelry,
            isSelected: false,
            action: {}
        )
    }
    .padding()
} 