import SwiftUI

struct UnitToggle<Option: Identifiable & Hashable>: View {
    let title: String
    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(options) { option in
                    Button(action: {
                        selection = option
                    }) {
                        Text(label(option))
                            .font(.subheadline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(selection.id == option.id ? Color.accentColor : Color(.systemGray5))
                            .foregroundColor(selection.id == option.id ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}

