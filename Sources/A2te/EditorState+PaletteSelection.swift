import A2teCore
import AppKit
import Foundation

extension EditorState {
    // MARK: - Palette

    func paletteColor(index: UInt8) -> NSColor {
        switch index {
        case 0: return .black
        case 1: return NSColor(calibratedRed: 0.54, green: 0.23, blue: 0.76, alpha: 1.0) // purple
        case 2: return NSColor(calibratedRed: 0.28, green: 0.78, blue: 0.31, alpha: 1.0) // green
        case 3: return NSColor(calibratedRed: 0.23, green: 0.45, blue: 0.88, alpha: 1.0) // blue
        case 4: return NSColor(calibratedRed: 0.95, green: 0.56, blue: 0.16, alpha: 1.0) // orange
        case 5: return NSColor(calibratedRed: 0.15, green: 0.75, blue: 0.75, alpha: 1.0) // temp
        case 6: return NSColor(calibratedRed: 0.82, green: 0.38, blue: 0.65, alpha: 1.0) // temp
        case 7: return .white
        default: return .black
        }
    }

    // MARK: - Selection / Cursor

    func normalizeTileCapacity(_ requested: Int) -> Int {
        TileCapacityMath.normalizeTileCapacity(requested)
    }

    func setTileCapacity(_ requested: Int, persist: Bool = true) {
        let normalized = normalizeTileCapacity(requested)
        tileCapacity = normalized
        if selectedSlotIndex >= normalized {
            selectedSlotIndex = max(0, normalized - 1)
        }
        normalizeReferenceSelection()
        refreshActiveSlotText()
        if persist {
            schedulePersist()
        }
    }

    func normalizeReferenceSelection() {
        referenceSelectedSlotIndices = Set(referenceSelectedSlotIndices.filter { (0..<tileCapacity).contains($0) })
        if referenceSelectedSlotIndices.isEmpty, (0..<tileCapacity).contains(selectedSlotIndex) {
            referenceSelectedSlotIndices = [selectedSlotIndex]
        }
    }

    func selectAllReferenceTiles() {
        referenceSelectedSlotIndices = Set(0..<tileCapacity)
        focusedPane = .reference
        statusMessage = "Selected all \(tileCapacity) tiles"
    }

    func clearReferenceSelectionToActive() {
        guard (0..<tileCapacity).contains(selectedSlotIndex) else { return }
        referenceSelectedSlotIndices = [selectedSlotIndex]
    }

    func isReferenceSlotSelected(_ index: Int) -> Bool {
        referenceSelectedSlotIndices.contains(index)
    }

    func selectedSlotIndicesForReferenceCommands() -> [Int] {
        let selected = referenceSelectedSlotIndices
            .filter { (0..<tileCapacity).contains($0) }
            .sorted()
        return selected.isEmpty ? [selectedSlotIndex] : selected
    }

    func selectSlot(_ index: Int, preserveReferenceSelection: Bool = false) {
        guard (0..<tileCapacity).contains(index), slots.indices.contains(index) else { return }
        selectedSlotIndex = index
        if !preserveReferenceSelection {
            referenceSelectedSlotIndices = [index]
        }
        refreshActiveSlotText()
    }

    func moveSlot(delta: Int) {
        let next = max(0, min(tileCapacity - 1, selectedSlotIndex + delta))
        selectSlot(next, preserveReferenceSelection: isReferenceAllSelected)
    }

    var selectedXParityLabel: String {
        guard slots.indices.contains(selectedSlotIndex) else { return XParityDisplay.even.label }
        return slots[selectedSlotIndex].xParityDisplay.label
    }

    var selectedPaletteModeLabel: String {
        guard slots.indices.contains(selectedSlotIndex) else { return "Normal" }
        return slots[selectedSlotIndex].paletteInverted ? "Inverted" : "Normal"
    }

    func selectedXBlockForPreview() -> Int {
        guard slots.indices.contains(selectedSlotIndex) else { return 0 }
        return slots[selectedSlotIndex].xParityDisplay.xBlock
    }

    func selectedPaletteInvertedForPreview() -> Bool {
        guard slots.indices.contains(selectedSlotIndex) else { return false }
        return slots[selectedSlotIndex].paletteInverted
    }

    func setSelectedXParity(_ parity: XParityDisplay) {
        guard slots.indices.contains(selectedSlotIndex) else { return }
        slots[selectedSlotIndex].xParityDisplay = parity
        syncPixelsFromBytes(slotIndex: selectedSlotIndex)
        statusMessage = "X parity -> \(parity.label) (slot \(selectedSlotIndex))"
    }

    func toggleSelectedPaletteInverted() {
        guard slots.indices.contains(selectedSlotIndex) else { return }
        slots[selectedSlotIndex].paletteInverted.toggle()
        syncPixelsFromBytes(slotIndex: selectedSlotIndex)
        statusMessage = "Palette -> \(slots[selectedSlotIndex].paletteInverted ? "Inverted" : "Normal") (slot \(selectedSlotIndex))"
    }

    func togglePaletteInvertedForReferenceSelection() {
        let targets = selectedSlotIndicesForReferenceCommands()
        guard !targets.isEmpty else { return }
        for index in targets where slots.indices.contains(index) {
            slots[index].paletteInverted.toggle()
            syncPixelsFromBytes(slotIndex: index)
        }
        if targets.count == 1, let slotIndex = targets.first {
            statusMessage = "Palette -> \(slots[slotIndex].paletteInverted ? "Inverted" : "Normal") (slot \(slotIndex))"
        } else {
            statusMessage = "Palette toggled for \(targets.count) selected tiles"
        }
    }

    func refreshActiveSlotText() {
        guard slots.indices.contains(selectedSlotIndex) else { return }
        activeSlotHexText = String(format: "%02X", selectedSlotIndex)
    }

    func applyActiveSlotNavigation() {
        let raw = activeSlotHexText.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized: String
        if raw.lowercased().hasPrefix("0x") {
            normalized = String(raw.dropFirst(2))
        } else if raw.hasPrefix("$") {
            normalized = String(raw.dropFirst())
        } else {
            normalized = raw
        }

        guard let value = UInt8(normalized, radix: 16), Int(value) < tileCapacity else {
            showWarning("Slot must be $\(String(format: "%02X", 0))..$\(String(format: "%02X", tileCapacity - 1)) (hex).")
            refreshActiveSlotText()
            return
        }
        selectSlot(Int(value), preserveReferenceSelection: isReferenceAllSelected)
        focusedPane = .reference
        statusMessage = "Active slot -> \(Int(value))"
    }

}
