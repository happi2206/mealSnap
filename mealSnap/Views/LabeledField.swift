import SwiftUI

struct LabeledField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .none
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(autocapitalization)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
        }
    }
}

#Preview {
    LabeledField(
        title: "Name",
        placeholder: "Enter your name",
        text: .constant("Happiness")
    )
}
