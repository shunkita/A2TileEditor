import Foundation
// swiftlint:disable identifier_name

public enum HiresColorIndex: UInt8 {
    case black = 0
    case purple = 1
    case green = 2
    case blue = 3
    case orange = 4
    case white = 7
}

/// Decoder adapted from A2HiresViewer's decode/apply rules
/// to return color indexes for A2te.
public enum HiresColorDecoder {
    /// For color-resolution previews in the editor:
    /// merge adjacent dots with the same color into one segment.
    public struct MergedPreviewSegment: Identifiable, Sendable {
        public var id: String { "\(startIndex)_\(length)_\(colorIndex)" }
        public let startIndex: Int
        public let length: Int
        public let colorIndex: UInt8

        public init(startIndex: Int, length: Int, colorIndex: UInt8) {
            self.startIndex = startIndex
            self.length = length
            self.colorIndex = colorIndex
        }
    }

    public static func mergedPreviewSegments(decodedRow: [UInt8]) -> [MergedPreviewSegment] {
        guard decodedRow.count == 7 else { return [] }
        var out: [MergedPreviewSegment] = []
        var i = 0
        while i < 7 {
            let c = decodedRow[i]
            var j = i + 1
            while j < 7, decodedRow[j] == c { j += 1 }
            out.append(MergedPreviewSegment(startIndex: i, length: j - i, colorIndex: c))
            i = j
        }
        return out
    }

    public static func decodePixelIndices(from byte: UInt8, xBlock: Int, invertPalette: Bool = false) -> [UInt8] {
        let msb = (byte & 0x80) != 0
        let effectiveMSB = invertPalette ? !msb : msb
        let bitPattern = (0..<7).map { (byte >> $0) & 1 == 1 }

        let evenColors: [UInt8] = effectiveMSB
            ? [HiresColorIndex.blue.rawValue, HiresColorIndex.orange.rawValue]
            : [HiresColorIndex.purple.rawValue, HiresColorIndex.green.rawValue]
        let oddColors: [UInt8] = effectiveMSB
            ? [HiresColorIndex.orange.rawValue, HiresColorIndex.blue.rawValue]
            : [HiresColorIndex.green.rawValue, HiresColorIndex.purple.rawValue]
        let baseColors = (xBlock % 2 == 0) ? evenColors : oddColors

        var pixels = bitPattern.enumerated().map { index, bit in
            bit ? baseColors[index % 2] : HiresColorIndex.black.rawValue
        }

        for i in 0..<6 {
            if pixels[i] != HiresColorIndex.black.rawValue,
               pixels[i + 1] != HiresColorIndex.black.rawValue {
                pixels[i] = HiresColorIndex.white.rawValue
                pixels[i + 1] = HiresColorIndex.white.rawValue
            }
        }
        return pixels
    }

    public static func applyRowRules(_ row: [UInt8]) -> [UInt8] {
        guard row.count >= 3 else { return row }
        var out = row
        for x in 1..<(row.count - 1) {
            let left = row[x - 1]
            let center = row[x]
            let right = row[x + 1]

            if center == HiresColorIndex.black.rawValue {
                if left != HiresColorIndex.black.rawValue && right != HiresColorIndex.black.rawValue {
                    out[x] = (x % 2 == 0) ? left : right
                }
            } else {
                if !(left == HiresColorIndex.black.rawValue && right == HiresColorIndex.black.rawValue) {
                    out[x] = HiresColorIndex.white.rawValue
                }
            }
        }
        return out
    }
}
// swiftlint:enable identifier_name
