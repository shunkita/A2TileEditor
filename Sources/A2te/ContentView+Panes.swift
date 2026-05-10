import SwiftUI
// swiftlint:disable identifier_name

private let rowGroupPaletteColumnWidth: CGFloat = 64
private let rowGroupValueGap: CGFloat = 24
private let rowGroupValueWidth: CGFloat = 96
private let rowGroupHeaderHeight: CGFloat = 15

private struct RowGroupBitColumnView: View {
    @ObservedObject var slot: TileSlot
    let isReadOnly: Bool
    let onToggleRow: (Int) -> Void

    private let cellWidth: CGFloat = 30
    private let cellHeight: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: rowGroupValueGap) {
                Text("Palette")
                    .font(.caption2.weight(.semibold))
                    .frame(width: rowGroupPaletteColumnWidth, alignment: .leading)
                Text("Value")
                    .font(.caption2.weight(.semibold))
                    .frame(width: rowGroupValueWidth, alignment: .leading)
            }
            .frame(height: rowGroupHeaderHeight, alignment: .leading)
            .foregroundStyle(.secondary)

            ForEach(0..<EditorState.tileHeight, id: \.self) { row in
                HStack(spacing: rowGroupValueGap) {
                    rowCell(row)
                        .frame(width: rowGroupPaletteColumnWidth, alignment: .leading)
                    Text("$\(hexByte(row))")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .frame(width: rowGroupValueWidth, alignment: .leading)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func hexByte(_ row: Int) -> String {
        guard slot.bytes.indices.contains(row) else { return "00" }
        return String(format: "%02X", slot.bytes[row])
    }

    @ViewBuilder
    private func rowCell(_ row: Int) -> some View {
        let rawBit7IsOne = (slot.bytes[row] & 0x80) != 0
        // Match the actual displayed palette behavior: Inverted flips the bit7 color meaning.
        let effectiveBit7IsOne = slot.paletteInverted ? !rawBit7IsOne : rawBit7IsOne
        let topLeftColor: Color = effectiveBit7IsOne ? .blue : .purple
        let remainderColor: Color = effectiveBit7IsOne ? .orange : .green

        Button {
            onToggleRow(row)
        } label: {
            ZStack {
                Rectangle()
                    .fill(remainderColor)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: cellWidth, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: cellHeight))
                    path.closeSubpath()
                }
                .fill(topLeftColor)
            }
            .frame(width: cellWidth, height: cellHeight)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.black.opacity(0.45), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isReadOnly)
        .accessibilityLabel("Row \(row) bit7 \(effectiveBit7IsOne ? "one" : "zero")")
    }
}

extension ContentView {
    private var referencePaneWidth: CGFloat {
        // Grid width (16 * 50 + 15 * 4 + 34 + 4) + scroll paddings (24) + pane paddings (20)
        // = 942. Keep about one tile (~50pt) as right margin inside the pane.
        992
    }

    var headerBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Button("Import .bin") { state.importBin() }
                Button("Export .bin") { state.exportBin() }
                Button("Export .inc") { state.exportInc() }
            }
        }
    }

    var editorPane: some View {
        PaneSection(selected: state.focusedPane == .editor) {
            let activeSlot = state.slots[state.selectedSlotIndex]
            let infoFont = Font.system(size: 22, weight: .bold, design: .monospaced)
            let editorGridWidth = CGFloat(EditorState.tileWidth) * 28 + CGFloat(EditorState.tileWidth - 1) * 3
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    HStack(spacing: 0) {
                        Text("Tile Code $")
                            .font(infoFont)
                        TextField("00", text: $state.activeSlotHexText)
                            .font(infoFont)
                            .textFieldStyle(.plain)
                            .frame(width: 44)
                            .onSubmit { state.applyActiveSlotNavigation() }
                    }
                    Button("Change") { state.applyActiveSlotNavigation() }
                        .controlSize(.small)
                    Spacer()
                }
                HStack(alignment: .top, spacing: 22) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tile Appearance")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: editorGridWidth, height: rowGroupHeaderHeight, alignment: .leading)
                        ForEach(0..<EditorState.tileHeight, id: \.self) { y in
                            EditorHiresRowView(
                                slot: activeSlot,
                                rowY: y,
                                cursorX: state.editorCursorX,
                                cursorY: state.editorCursorY,
                                xBlock: state.selectedXBlockForPreview(),
                                invertPalette: state.selectedPaletteInvertedForPreview(),
                                palette: { Color(state.paletteColor(index: $0)) },
                                onToggle: { x in
                                    guard !state.isEditorReadOnly else { return }
                                    state.toggleBitAt(x: x, y: y)
                                    state.focusedPane = .editor
                                }
                            )
                        }
                    }
                    RowGroupBitColumnView(
                        slot: activeSlot,
                        isReadOnly: state.isEditorReadOnly,
                        onToggleRow: { row in
                            state.toggleRowGroup(row)
                            state.editorCursorY = row
                            state.focusedPane = .editor
                        }
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                GroupBox("View Tile As") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: rowGroupValueGap) {
                            Text("X coord")
                                .foregroundStyle(.secondary)
                                .frame(width: rowGroupPaletteColumnWidth, alignment: .leading)
                            Text(state.selectedXParityLabel)
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .frame(width: rowGroupValueWidth, alignment: .leading)
                        }
                        HStack(spacing: rowGroupValueGap) {
                            Text("Palette")
                                .foregroundStyle(.secondary)
                                .frame(width: rowGroupPaletteColumnWidth, alignment: .leading)
                            Text(state.selectedPaletteModeLabel)
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .frame(width: rowGroupValueWidth, alignment: .leading)
                        }
                    }
                    .font(.system(size: 12))
                }
                .padding(.top, 14)
                .frame(width: rowGroupPaletteColumnWidth + rowGroupValueGap + rowGroupValueWidth, alignment: .leading)
                if state.isEditorReadOnly {
                    Text("Editor is read-only while all reference tiles are selected")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .frame(width: referencePaneWidth, alignment: .leading)
        .onTapGesture { state.focusedPane = .editor }
    }

    var referencePane: some View {
        let rowCount = max(1, (state.tileCapacity + 15) / 16)
        let infoFont = Font.system(size: 22, weight: .bold, design: .monospaced)
        return PaneSection(title: "Tile Reference 16x\(rowCount)", titleFont: infoFont, selected: state.focusedPane == .reference) {
            let activeRow = state.selectedSlotIndex / 16
            let activeCol = state.selectedSlotIndex % 16
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("")
                            .frame(width: 34, alignment: .trailing)
                        ForEach(0..<16, id: \.self) { col in
                            let isActiveCol = col == activeCol
                            Text("$\(String(format: "%02X", col))")
                                .font(.system(size: 12, design: .monospaced))
                                .frame(width: 50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(
                                            isActiveCol ? Color.orange : Color.clear,
                                            lineWidth: isActiveCol ? 2 : 0
                                        )
                                )
                        }
                    }
                    ForEach(0..<rowCount, id: \.self) { row in
                        HStack(spacing: 4) {
                            let isActiveRow = row == activeRow
                            Text("$\(String(format: "%02X", row))")
                                .font(.system(size: 12, design: .monospaced))
                                .frame(width: 34, alignment: .trailing)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(
                                            isActiveRow ? Color.orange : Color.clear,
                                            lineWidth: isActiveRow ? 2 : 0
                                        )
                                )
                            ForEach(0..<16, id: \.self) { col in
                                let idx = row * 16 + col
                                if idx < state.tileCapacity {
                                    let slot = state.slots[idx]
                                    let isActive = idx == state.selectedSlotIndex
                                    let isSelected = state.isReferenceSlotSelected(idx)
                                    TileMiniView(
                                        slot: slot,
                                        xBlock: slot.xParityDisplay.xBlock,
                                        invertPalette: slot.paletteInverted,
                                        palette: state.paletteColor(index:)
                                    )
                                    .frame(width: 50, height: 34)
                                    .background(isSelected ? Color.orange.opacity(0.22) : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(
                                                isActive ? Color.orange : Color.gray.opacity(0.35),
                                                lineWidth: isActive ? 2 : 1
                                            )
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        state.selectSlot(idx)
                                        state.focusedPane = .reference
                                    }
                                } else {
                                    Color.clear
                                        .frame(width: 50, height: 34)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .frame(height: 430)
        }
        .frame(width: referencePaneWidth, alignment: .leading)
        .onTapGesture { state.focusedPane = .reference }
    }

    func hex2(_ value: UInt8) -> String {
        String(format: "%02X", value)
    }
}
// swiftlint:enable identifier_name
