import SwiftUI

struct DenCellLabel: View {
    let title: String
    let text: String
    let isTheme: Bool
    var hasChild = false
    @ScaledMetric(relativeTo: .body) private var minimumHeight = 160

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "タップして書く" : text)
                .font(isTheme ? .headline : .body)
                .foregroundStyle(text.isEmpty ? .secondary : .primary)
                .lineLimit(5)
            Spacer(minLength: 0)
            if hasChild { Label("子の田を開く", systemImage: "arrow.down.right").font(.caption) }
        }
        .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .topLeading)
        .padding(14)
        .background(isTheme ? Color.green.opacity(0.12) : Color(.cellBackground))
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
