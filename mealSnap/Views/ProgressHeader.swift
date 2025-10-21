import SwiftUI

struct ProgressHeader: View {
    var title: String
    var subtitle: String?
    var step: Int
    var total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressView(value: Double(step), total: Double(total))
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                .frame(height: 6)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.weight(.semibold))
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Text("Step \(step) of \(total)")
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal)
    }
}

#Preview {
    ProgressHeader(
        title: "Welcome to MealSnap",
        subtitle: "Let’s tailor your nutrition plan before your first snap.",
        step: 1,
        total: 3
    )
}

