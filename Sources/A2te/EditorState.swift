import A2teCore
import Foundation
import SwiftUI

@MainActor
final class EditorState: ObservableObject {
    static let defaultTileCapacity = TileSetConstants.defaultTileCapacity
    static let maxTileCapacity = TileSetConstants.maxTileCapacity
    static let tileWidth = TileSetConstants.tileWidth
    static let tileHeight = TileSetConstants.tileHeight

    let slots: [TileSlot]
    @Published var tileCapacity = TileSetConstants.defaultTileCapacity
    @Published var referenceSelectedSlotIndices: Set<Int> = [0]
    @Published var selectedSlotIndex = 0
    @Published var focusedPane: PaneFocus = .editor

    @Published var editorCursorX = 0
    @Published var editorCursorY = 0

    @Published var incLabelName = "hgr_tiles"
    @Published var activeSlotHexText = "00"
    @Published var statusMessage = "Ready"
    @Published var alertMessage = ""
    @Published var showAlert = false
    /// URL of the document on disk (from SwiftUI environment when using `DocumentGroup`).
    @Published var documentFileURL: URL? {
        didSet {
            let oldPath = oldValue?.standardizedFileURL.path
            let newPath = documentFileURL?.standardizedFileURL.path
            guard oldPath != newPath else { return }
        }
    }
    @Published var lastLoadedSourceURL: URL?

    /// When non-nil, tile edits are written back into the SwiftUI `FileDocument` binding.
    let documentBinding: Binding<A2teProjectDocument>?
    var persistTask: Task<Void, Never>?
    var isApplyingSnapshot = false

    var isReferenceAllSelected: Bool {
        tileCapacity > 0 && referenceSelectedSlotIndices.count == tileCapacity
    }

    var isEditorReadOnly: Bool {
        isReferenceAllSelected
    }

    init(document: Binding<A2teProjectDocument>) {
        self.documentBinding = document
        var initial: [TileSlot] = []
        for slotIndex in 0..<Self.maxTileCapacity {
            initial.append(TileSlot(id: slotIndex, code: UInt8(slotIndex)))
        }
        self.slots = initial
        applySnapshot(document.wrappedValue.snapshot)
    }

    /// SwiftUI previews only (no persistence).
    init(previewSnapshot: A2teProjectSnapshot) {
        self.documentBinding = nil
        var initial: [TileSlot] = []
        for slotIndex in 0..<Self.maxTileCapacity {
            initial.append(TileSlot(id: slotIndex, code: UInt8(slotIndex)))
        }
        self.slots = initial
        applySnapshot(previewSnapshot)
    }

    func showWarning(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
