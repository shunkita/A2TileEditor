import A2teCore
import SwiftUI
import UniformTypeIdentifiers

struct A2teProjectDocument: FileDocument {
    static let projectUTI = "io.github.shunkita.a2teproj"

    static var readableContentTypes: [UTType] {
        let binType = UTType(filenameExtension: "bin")
            ?? UTType(importedAs: "com.apple.macbinary-archive")
        return [
            UTType(exportedAs: projectUTI),
            .json,
            binType,
            .data,
        ]
    }

    static var writableContentTypes: [UTType] { readableContentTypes }

    var snapshot: A2teProjectSnapshot

    init() {
        snapshot = .emptyNew()
    }

    init(snapshot: A2teProjectSnapshot) {
        self.snapshot = snapshot
    }

    init(configuration: ReadConfiguration) throws {
        let fileExtension = configuration.file.preferredFilename?
            .split(separator: ".")
            .last?
            .lowercased()
        let fileData = configuration.file.regularFileContents

        guard let data = fileData else {
            // State restoration can try to reopen stale/permission-lost binary docs.
            // Avoid hard-failing app launch in this case.
            if fileExtension != "a2teproj" && fileExtension != "json" {
                snapshot = .emptyNew()
                return
            }
            throw CocoaError(.fileReadCorruptFile)
        }

        // For explicit project/json files, keep strict JSON decoding.
        if fileExtension == "a2teproj" || fileExtension == "json" {
            snapshot = try JSONDecoder().decode(A2teProjectSnapshot.self, from: data)
            return
        }

        // Otherwise, allow direct launch/open with raw .bin style tile data.
        if let decoded = try? JSONDecoder().decode(A2teProjectSnapshot.self, from: data) {
            snapshot = decoded
            return
        }
        snapshot = Self.snapshotFromBinaryData(data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        return FileWrapper(regularFileWithContents: data)
    }

    private static func snapshotFromBinaryData(_ data: Data) -> A2teProjectSnapshot {
        var bytes = [UInt8](data)
        guard !bytes.isEmpty else { return .emptyNew() }

        let normalizedByteCount = TileCapacityMath.normalizeBinByteCount(bytes.count)
        guard normalizedByteCount > 0 else { return .emptyNew() }

        if bytes.count > normalizedByteCount {
            bytes = Array(bytes.prefix(normalizedByteCount))
        } else if bytes.count < normalizedByteCount {
            bytes += Array(repeating: 0, count: normalizedByteCount - bytes.count)
        }

        let tileCapacity = normalizedByteCount / TileSetConstants.bytesPerTile
        let slots = (0..<tileCapacity).map { i in
            let start = i * TileSetConstants.bytesPerTile
            let end = start + TileSetConstants.bytesPerTile
            return A2teProjectSnapshot.Slot(
                code: UInt8(i),
                bytes: Array(bytes[start..<end]),
                xParityDisplay: .even,
                paletteInverted: false
            )
        }

        return A2teProjectSnapshot(
            version: 1,
            tileCapacity: tileCapacity,
            incLabelName: "hgr_tiles",
            slots: slots,
            uiState: .init(selectedSlotIndex: 0)
        )
    }
}
