import Foundation

public enum TileCapacityMath {
    public static func normalizeTileCapacity(_ requested: Int) -> Int {
        max(1, min(TileSetConstants.maxTileCapacity, requested))
    }

    public static var maxBinByteCount: Int {
        TileSetConstants.maxTileCapacity * TileSetConstants.bytesPerTile
    }

    /// Clamp to supported max bytes and align to tile-byte boundary.
    /// Returns 0 for empty input.
    public static func normalizeBinByteCount(_ inputByteCount: Int) -> Int {
        let clamped = max(0, min(inputByteCount, maxBinByteCount))
        guard clamped > 0 else { return 0 }
        let unit = TileSetConstants.bytesPerTile
        return ((clamped + unit - 1) / unit) * unit
    }
}
