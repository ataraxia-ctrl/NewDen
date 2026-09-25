import Foundation

struct CellSelection: Identifiable {
    let position: Int
    var id: Int { position }
}
