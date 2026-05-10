import Foundation

/// On-disk JSON for `.a2teproj` (portable; no AppKit / SwiftUI).
public struct A2teProjectSnapshot: Codable, Equatable, Sendable {
    public struct Slot: Codable, Equatable, Sendable {
        public var code: UInt8
        public var bytes: [UInt8]
        public var xParityDisplay: XParityDisplay?
        public var paletteInverted: Bool?

        public init(
            code: UInt8,
            bytes: [UInt8],
            xParityDisplay: XParityDisplay? = nil,
            paletteInverted: Bool? = nil
        ) {
            self.code = code
            self.bytes = bytes
            self.xParityDisplay = xParityDisplay
            self.paletteInverted = paletteInverted
        }
    }

    public struct UiState: Codable, Equatable, Sendable {
        public var selectedSlotIndex: Int

        public init(selectedSlotIndex: Int) {
            self.selectedSlotIndex = selectedSlotIndex
        }
    }

    public var version: Int
    public var tileCapacity: Int?
    public var incLabelName: String
    public var slots: [Slot]
    public var uiState: UiState

    private enum CodingKeys: String, CodingKey {
        case version
        case tileCapacity
        case incLabelName
        case slots
        case uiState
        // Legacy flat key used before `uiState`.
        case selectedSlotIndex
    }

    public init(version: Int, tileCapacity: Int?, incLabelName: String, slots: [Slot], uiState: UiState) {
        self.version = version
        self.tileCapacity = tileCapacity
        self.incLabelName = incLabelName
        self.slots = slots
        self.uiState = uiState
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let decodedSlots = try container.decodeIfPresent([Slot].self, forKey: .slots) ?? []
        let legacySelectedIndex = try container.decodeIfPresent(Int.self, forKey: .selectedSlotIndex) ?? 0
        let decodedUiState = try container.decodeIfPresent(UiState.self, forKey: .uiState)

        self.version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        self.tileCapacity = try container.decodeIfPresent(Int.self, forKey: .tileCapacity)
        self.incLabelName = try container.decodeIfPresent(String.self, forKey: .incLabelName) ?? "hgr_tiles"
        self.slots = decodedSlots
        self.uiState = decodedUiState ?? UiState(selectedSlotIndex: legacySelectedIndex)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encodeIfPresent(tileCapacity, forKey: .tileCapacity)
        try container.encode(incLabelName, forKey: .incLabelName)
        try container.encode(slots, forKey: .slots)
        try container.encode(uiState, forKey: .uiState)
    }

    /// New empty project (128 tiles).
    public static func emptyNew() -> A2teProjectSnapshot {
        let cap = TileSetConstants.defaultTileCapacity
        let slots = (0..<cap).map { i in
            Slot(code: UInt8(i), bytes: Array(repeating: 0, count: TileSetConstants.bytesPerTile))
        }
        return A2teProjectSnapshot(
            version: 1,
            tileCapacity: cap,
            incLabelName: "hgr_tiles",
            slots: slots,
            uiState: UiState(selectedSlotIndex: 0)
        )
    }
}
