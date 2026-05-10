import A2teCore
import AppKit
import Foundation
import UniformTypeIdentifiers

extension EditorState {
    // MARK: - Document persistence (SwiftUI `FileDocument`)
    private var isAutoPersistEnabled: Bool { true }

    private var shouldPersistToBoundDocument: Bool {
        guard documentBinding != nil else { return false }
        guard let url = documentFileURL else { return true } // unsaved/new document
        return url.pathExtension.lowercased() == "a2teproj"
    }

    func schedulePersist() {
        guard isAutoPersistEnabled else { return }
        guard let documentBinding else { return }
        guard shouldPersistToBoundDocument else { return }
        guard !isApplyingSnapshot else { return }
        persistTask?.cancel()
        persistTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            let snap = buildSnapshot()
            documentBinding.wrappedValue = A2teProjectDocument(snapshot: snap)
        }
    }

    func buildSnapshot() -> A2teProjectSnapshot {
        A2teProjectSnapshot(
            version: 1,
            tileCapacity: tileCapacity,
            incLabelName: incLabelName,
            slots: (0..<tileCapacity).map {
                A2teProjectSnapshot.Slot(
                    code: slots[$0].code,
                    bytes: Array(slots[$0].bytes.prefix(TileSetConstants.bytesPerTile)),
                    xParityDisplay: slots[$0].xParityDisplay,
                    paletteInverted: slots[$0].paletteInverted
                )
            },
            uiState: A2teProjectSnapshot.UiState(selectedSlotIndex: selectedSlotIndex)
        )
    }

    func applySnapshot(_ file: A2teProjectSnapshot) {
        persistTask?.cancel()
        isApplyingSnapshot = true
        defer { isApplyingSnapshot = false }

        let loadedCapacity = TileCapacityMath.normalizeTileCapacity(
            file.tileCapacity ?? min(Self.maxTileCapacity, max(1, file.slots.count))
        )
        setTileCapacity(loadedCapacity, persist: false)

        for slotIndex in 0..<Self.maxTileCapacity {
            if slotIndex < file.slots.count {
                slots[slotIndex].code = file.slots[slotIndex].code
                let bytes = Array(file.slots[slotIndex].bytes.prefix(TileSetConstants.bytesPerTile))
                slots[slotIndex].bytes = bytes + Array(repeating: 0, count: max(0, TileSetConstants.bytesPerTile - bytes.count))
                slots[slotIndex].xParityDisplay = file.slots[slotIndex].xParityDisplay ?? .even
                slots[slotIndex].paletteInverted = file.slots[slotIndex].paletteInverted ?? false
                syncPixelsFromBytes(slotIndex: slotIndex)
            } else {
                resetSlotToDefault(slotIndex)
            }
        }

        incLabelName = file.incLabelName.isEmpty ? "hgr_tiles" : file.incLabelName
        selectedSlotIndex = max(0, min(tileCapacity - 1, file.uiState.selectedSlotIndex))
        clearReferenceSelectionToActive()
        refreshActiveSlotText()
        statusMessage = "Loaded project"
    }

    private func resetSlotToDefault(_ index: Int) {
        guard slots.indices.contains(index) else { return }
        slots[index].code = UInt8(index)
        slots[index].bytes = Array(repeating: 0, count: TileSetConstants.bytesPerTile)
        slots[index].pixels = Array(repeating: 0, count: 56)
        slots[index].xParityDisplay = .even
        slots[index].paletteInverted = false
    }

    func importBin() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.data]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Import .bin"
        panel.message = "Import binary tile data (max 2048 bytes). Pad only when length is not multiple of 8."

        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Data(contentsOf: url)
            var bytes = [UInt8](data)
            let actual = bytes.count
            guard actual > 0 else {
                showWarning("Import warning: file length is 0 bytes.")
                return
            }

            let normalizedByteCount = TileCapacityMath.normalizeBinByteCount(actual)
            let maxSupported = TileCapacityMath.maxBinByteCount
            let clampedActual = min(actual, maxSupported)
            let wasTruncated = actual > maxSupported
            let wasPadded = normalizedByteCount > clampedActual
            let normalizedCapacity = normalizedByteCount / TileSetConstants.bytesPerTile
            setTileCapacity(normalizedCapacity, persist: false)
            isApplyingSnapshot = true
            defer { isApplyingSnapshot = false }

            if wasTruncated {
                bytes = Array(bytes.prefix(maxSupported))
            }
            if bytes.count < normalizedByteCount {
                bytes += Array(repeating: 0, count: normalizedByteCount - bytes.count)
            }
            for slot in 0..<tileCapacity {
                let start = slot * TileSetConstants.bytesPerTile
                let end = start + TileSetConstants.bytesPerTile
                // `.bin` has only raw tile bytes; metadata from previous loads must not leak.
                slots[slot].code = UInt8(slot)
                slots[slot].xParityDisplay = .even
                slots[slot].paletteInverted = false
                slots[slot].bytes = Array(bytes[start..<end])
                syncPixelsFromBytes(slotIndex: slot)
            }
            for slot in tileCapacity..<Self.maxTileCapacity {
                resetSlotToDefault(slot)
            }
            clearReferenceSelectionToActive()
            lastLoadedSourceURL = url

            if wasTruncated || wasPadded {
                var notes: [String] = []
                if wasTruncated {
                    notes.append("truncated to \(maxSupported)")
                }
                if wasPadded {
                    notes.append("padded to \(normalizedByteCount) for 8-byte alignment")
                }
                statusMessage = "Imported with warning: \(actual) bytes -> \(normalizedByteCount)"
                showWarning("Import warning: file length \(actual) bytes; \(notes.joined(separator: ", ")).")
            } else {
                statusMessage = "Imported .bin (\(actual) bytes, \(tileCapacity) tiles)"
            }
        } catch {
            showWarning("Import failed: \(error.localizedDescription)")
        }
    }

    func exportBin() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.data]
        panel.nameFieldStringValue = "tiles.bin"
        panel.prompt = "Export .bin"
        if let baseURL = documentFileURL ?? lastLoadedSourceURL {
            panel.directoryURL = baseURL.deletingLastPathComponent()
        }

        guard panel.runModal() == .OK, let url = panel.url else { return }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(tileCapacity * TileSetConstants.bytesPerTile)
        for slot in 0..<tileCapacity {
            bytes += slots[slot].bytes.prefix(TileSetConstants.bytesPerTile)
        }
        do {
            try Data(bytes).write(to: url)
            statusMessage = "Exported .bin (\(bytes.count) bytes)"
        } catch {
            showWarning("Export failed: \(error.localizedDescription)")
        }
    }

    func exportInc() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.sourceCode]
        panel.nameFieldStringValue = "tiles.inc"
        panel.prompt = "Export .inc"
        if let baseURL = documentFileURL ?? lastLoadedSourceURL {
            panel.directoryURL = baseURL.deletingLastPathComponent()
        }

        guard panel.runModal() == .OK, let url = panel.url else { return }
        let slotRows = (0..<tileCapacity).map { i in
            (code: slots[i].code, bytes: Array(slots[i].bytes.prefix(TileSetConstants.bytesPerTile)), xParity: slots[i].xParityDisplay)
        }
        let text = IncAssemblerExport.build(
            tileCapacity: tileCapacity,
            incLabelName: incLabelName,
            slots: slotRows
        )
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            statusMessage = "Exported .inc"
        } catch {
            showWarning("Export failed: \(error.localizedDescription)")
        }
    }
}
