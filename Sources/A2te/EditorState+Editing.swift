import A2teCore
import Foundation
// swiftlint:disable identifier_name

extension EditorState {
    // MARK: - Editing

    func moveEditorCursor(dx: Int, dy: Int) {
        editorCursorX = max(0, min(Self.tileWidth - 1, editorCursorX + dx))
        editorCursorY = max(0, min(Self.tileHeight - 1, editorCursorY + dy))
    }

    func currentPixelColor(x: Int, y: Int) -> UInt8 {
        let i = y * Self.tileWidth + x
        guard slots.indices.contains(selectedSlotIndex), (0..<56).contains(i) else { return 0 }
        return slots[selectedSlotIndex].pixels[i]
    }

    func bitIsOn(x: Int, y: Int) -> Bool {
        guard slots.indices.contains(selectedSlotIndex),
              (0..<Self.tileWidth).contains(x),
              (0..<Self.tileHeight).contains(y) else { return false }
        let row = slots[selectedSlotIndex].bytes[y]
        return (row & (1 << x)) != 0
    }

    func setBitAt(x: Int, y: Int, on: Bool) {
        guard !isEditorReadOnly else { return }
        guard slots.indices.contains(selectedSlotIndex),
              (0..<Self.tileWidth).contains(x),
              (0..<Self.tileHeight).contains(y) else { return }
        var row = slots[selectedSlotIndex].bytes[y]
        if on {
            row |= (1 << x)
        } else {
            row &= ~(1 << x)
        }
        slots[selectedSlotIndex].bytes[y] = row
        syncPixelsFromBytes(slotIndex: selectedSlotIndex)
    }

    func toggleBitAt(x: Int, y: Int) {
        setBitAt(x: x, y: y, on: !bitIsOn(x: x, y: y))
        editorCursorX = x
        editorCursorY = y
    }

    func toggleCurrentBit() {
        toggleBitAt(x: editorCursorX, y: editorCursorY)
    }

    func setCurrentBit(_ on: Bool) {
        setBitAt(x: editorCursorX, y: editorCursorY, on: on)
    }

    func rowUsesGroup2(_ row: Int) -> Bool {
        guard slots.indices.contains(selectedSlotIndex),
              (0..<Self.tileHeight).contains(row) else { return false }
        return (slots[selectedSlotIndex].bytes[row] & 0x80) != 0
    }

    func toggleRowGroup(_ row: Int) {
        guard !isEditorReadOnly else { return }
        guard slots.indices.contains(selectedSlotIndex),
              (0..<Self.tileHeight).contains(row) else { return }
        slots[selectedSlotIndex].bytes[row] ^= 0x80
        syncPixelsFromBytes(slotIndex: selectedSlotIndex)
    }

    func toggleCurrentRowGroup() {
        toggleRowGroup(editorCursorY)
    }

    func syncPixelsFromBytes(slotIndex: Int) {
        guard slots.indices.contains(slotIndex) else { return }
        let bytes = slots[slotIndex].bytes
        let xBlock = slots[slotIndex].xParityDisplay.xBlock
        let invertPalette = slots[slotIndex].paletteInverted
        var newPixels = Array(repeating: UInt8(0), count: 56)

        for y in 0..<Self.tileHeight {
            let row = y < bytes.count ? bytes[y] : 0
            let decoded = HiresColorDecoder.decodePixelIndices(from: row, xBlock: xBlock, invertPalette: invertPalette)
            for x in 0..<Self.tileWidth {
                newPixels[y * Self.tileWidth + x] = decoded[x]
            }
        }
        slots[slotIndex].pixels = newPixels
        schedulePersist()
    }
}
// swiftlint:enable identifier_name
