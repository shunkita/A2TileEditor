import Foundation

/// ca65 `.inc` text for a tile set (pure string generation).
public enum IncAssemblerExport {
    public static func build(
        tileCapacity: Int,
        incLabelName: String,
        slots: [(code: UInt8, bytes: [UInt8], xParity: XParityDisplay)]
    ) -> String {
        let label = incLabelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "hgr_tiles" : incLabelName
        var lines: [String] = []
        lines.append("; A2te tiles export")
        lines.append("; format: \(tileCapacity) slots, 8 bytes each")
        lines.append("")
        lines.append("\(label):")
        for slotIndex in 0..<tileCapacity {
            let codeHex = String(format: "%02x", slots[slotIndex].code)
            let byteText = slots[slotIndex].bytes
                .prefix(TileSetConstants.bytesPerTile)
                .map { "$" + String(format: "%02x", $0) }
                .joined(separator: ", ")
            lines.append("; code = $\(codeHex) (\(slots[slotIndex].xParity.label))")
            lines.append("    .byte \(byteText)")
        }
        lines.append("\(label)_end:")
        lines.append("")
        return lines.joined(separator: "\n")
    }
}
