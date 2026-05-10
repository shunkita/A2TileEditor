import A2teCore
import AppKit
import SwiftUI
// swiftlint:disable identifier_name

private enum PixelAspect {
    // Keep this configurable for future ratio tuning.
    static let editorDotWidth: CGFloat = 28
    static let editorDotHeight: CGFloat = 20 // 1.4:1
    static let editorDotGap: CGFloat = 3

    static let refDotWidth: CGFloat = 5.6
    static let refDotHeight: CGFloat = 4.0 // 1.4:1
}

/// Back layer: merged-color Hires preview segments.
/// Front layer: 7-dot bit-edit hit targets.
struct EditorHiresRowView: View {
    @ObservedObject var slot: TileSlot
    let rowY: Int
    let cursorX: Int
    let cursorY: Int
    let xBlock: Int
    let invertPalette: Bool
    let palette: (UInt8) -> Color
    let onToggle: (Int) -> Void

    private let dotW: CGFloat = PixelAspect.editorDotWidth
    private let dotH: CGFloat = PixelAspect.editorDotHeight
    private let gap: CGFloat = PixelAspect.editorDotGap

    var body: some View {
        let rowByte = slot.bytes[rowY]
        let decoded = HiresColorDecoder.decodePixelIndices(from: rowByte, xBlock: xBlock, invertPalette: invertPalette)
        let ruled = HiresColorDecoder.applyRowRules(decoded)
        let segments = HiresColorDecoder.mergedPreviewSegments(decodedRow: ruled)
        let totalWidth = CGFloat(EditorState.tileWidth) * dotW + CGFloat(EditorState.tileWidth - 1) * gap

        ZStack(alignment: .leading) {
            ForEach(segments) { seg in
                Rectangle()
                    .fill(palette(seg.colorIndex))
                    .frame(
                        width: CGFloat(seg.length) * dotW + CGFloat(max(0, seg.length - 1)) * gap,
                        height: dotH
                    )
                    .offset(x: CGFloat(seg.startIndex) * (dotW + gap))
            }

            HStack(spacing: gap) {
                ForEach(0..<EditorState.tileWidth, id: \.self) { x in
                    let on = (rowByte & (1 << x)) != 0
                    let indicatorColor: Color = ruled[x] == 7 ? Color.gray.opacity(0.78) : Color.white.opacity(0.84)
                    Color.clear
                        .frame(width: dotW, height: dotH)
                        .contentShape(Rectangle())
                        .overlay(
                            ZStack {
                                Rectangle()
                                    .stroke(
                                        cursorX == x && cursorY == rowY ? Color.yellow : Color.gray.opacity(0.7),
                                        lineWidth: cursorX == x && cursorY == rowY ? 2 : 1
                                    )
                                if on {
                                    Circle()
                                        .fill(indicatorColor)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        )
                        .onTapGesture { onToggle(x) }
                }
            }
        }
        .frame(width: totalWidth, height: dotH, alignment: .leading)
    }
}

struct TileMiniView: View {
    @ObservedObject var slot: TileSlot
    let xBlock: Int
    let invertPalette: Bool
    let palette: (UInt8) -> NSColor

    var body: some View {
        Canvas { context, _ in
            for y in 0..<8 {
                let decoded = HiresColorDecoder.decodePixelIndices(from: slot.bytes[y], xBlock: xBlock, invertPalette: invertPalette)
                let ruled = HiresColorDecoder.applyRowRules(decoded)
                let segments = HiresColorDecoder.mergedPreviewSegments(decodedRow: ruled)
                for seg in segments {
                    let c = seg.colorIndex
                    context.fill(
                        Path(CGRect(
                            x: CGFloat(seg.startIndex) * PixelAspect.refDotWidth,
                            y: CGFloat(y) * PixelAspect.refDotHeight,
                            width: CGFloat(seg.length) * PixelAspect.refDotWidth,
                            height: PixelAspect.refDotHeight
                        )),
                        with: .color(Color(palette(c)))
                    )
                }
            }
        }
        .frame(
            width: CGFloat(EditorState.tileWidth) * PixelAspect.refDotWidth,
            height: CGFloat(EditorState.tileHeight) * PixelAspect.refDotHeight
        )
    }
}

struct PaneSection<Content: View>: View {
    let title: String?
    let titleFont: Font
    let selected: Bool
    @ViewBuilder var content: Content

    init(title: String? = nil, titleFont: Font = .headline, selected: Bool, @ViewBuilder content: () -> Content) {
        self.title = title
        self.titleFont = titleFont
        self.selected = selected
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title, !title.isEmpty {
                Text(title)
                    .font(titleFont)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            content
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(selected ? Color.accentColor.opacity(0.12) : Color.gray.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(selected ? Color.accentColor : Color.gray.opacity(0.4), lineWidth: selected ? 2 : 1)
        )
    }
}
// swiftlint:enable identifier_name
