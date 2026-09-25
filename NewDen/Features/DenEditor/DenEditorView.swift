import SwiftUI

struct DenEditorView: View {
    let den: Den
    let store: DenStore
    @State private var selection: CellSelection?
    @State private var errorMessage = ""
    @State private var showsError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Menu {
                        ForEach(DenKind.allCases) { kind in
                            Button(kind.title) { changeKind(kind) }
                        }
                    } label: {
                        Label(den.kind.title, systemImage: "square.grid.2x2")
                    }
                    .disabled(!den.isIncomplete || store.saveError != nil)
                    .accessibilityIdentifier("kindPicker")
                    Spacer()
                    Label(den.isIncomplete ? "未完" : "完成", systemImage: den.isIncomplete ? "circle.dashed" : "checkmark.circle")
                        .font(.subheadline)
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 1), GridItem(.flexible(), spacing: 1)], spacing: 1) {
                    DenCellView(title: den.kind.themePrompt, text: den.theme?.text ?? "", isTheme: true, position: 0) {
                        selection = CellSelection(position: 0)
                    }
                    ForEach(den.orderedSlots) { slot in
                        if let child = slot.child {
                            NavigationLink(value: child.id) {
                                DenCellLabel(title: "\(den.kind.elementPrompt) \(slot.position)", text: slot.content?.text ?? "", isTheme: false, hasChild: true)
                            }
                            .buttonStyle(.plain)
                        } else {
                            DenCellView(title: "\(den.kind.elementPrompt) \(slot.position)", text: slot.content?.text ?? "", isTheme: false, position: slot.position) {
                                selection = CellSelection(position: slot.position)
                            }
                        }
                    }
                }
                .background(.secondary.opacity(0.3))
                .overlay {
                    Rectangle().strokeBorder(.secondary, style: StrokeStyle(lineWidth: 1, dash: den.isIncomplete ? [5, 4] : []))
                        .allowsHitTesting(false)
                }
                Text(den.isIncomplete ? "マスをタップして、考えを書いてみましょう。3つの要素がそろうと、子の田を作れます。" : "3つの要素がそろいました。マスを開くと、子の田を作れます。")
                    .font(.callout).foregroundStyle(.secondary)
                Text("作成：\(den.createdAt.formatted(.dateTime.year().month().day().hour().minute()))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(den.kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selection) { selection in
            CellEditorView(den: den, position: selection.position, store: store)
        }
        .alert("型を変更できません", isPresented: $showsError) { } message: { Text(errorMessage) }
    }

    private func changeKind(_ kind: DenKind) {
        do { try store.changeKind(den, to: kind) }
        catch { errorMessage = error.localizedDescription; showsError = true }
    }
}
