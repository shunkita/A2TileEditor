import A2teCore
import SwiftUI

enum PaneFocus: String, CaseIterable {
    case editor = "Editor"
    case reference = "Reference"
}

@MainActor
final class TileSlot: ObservableObject, Identifiable {
    let id: Int
    @Published var code: UInt8
    @Published var bytes: [UInt8]        // Always 8 bytes
    @Published var pixels: [UInt8]       // 7 * 8 logical color indexes (0...7)
    @Published var xParityDisplay: XParityDisplay
    @Published var paletteInverted: Bool

    init(id: Int, code: UInt8) {
        self.id = id
        self.code = code
        self.bytes = Array(repeating: 0, count: 8)
        self.pixels = Array(repeating: 0, count: 56)
        self.xParityDisplay = .even
        self.paletteInverted = false
    }
}
