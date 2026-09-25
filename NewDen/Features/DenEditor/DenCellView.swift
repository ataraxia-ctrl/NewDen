import SwiftUI

struct DenCellView: View {
    let title: String
    let text: String
    let isTheme: Bool
    let position: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            DenCellLabel(title: title, text: text, isTheme: isTheme)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("cell-\(position)")
        .accessibilityHint("テキストを編集します")
    }
}
