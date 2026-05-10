# A2te

A2te is a tile editor for Apple II Hires graphics.

- 2-pane UI (Editor and Tile Reference)
- `.bin`: tile set binary for Apple II Hires (1..256 tiles, 8 bytes per tile, 7x8 logical pixels, max 2048 bytes)
- `.inc`: ca65 include file of the same tile set as `.byte` assembly data
- `.a2teproj`: JSON project file storing tile set state and editor metadata

## Build and Run

Install Swift first

- Install Xcode from the App Store, then run once to complete setup, or
- Install Apple Command Line Tools: `xcode-select --install`

Then build and run from the project root:

```bash
swift build
swift run A2te
```

Requirements: macOS 14+ and Swift 5.8+ (Xcode toolchain). The app relies on modern `DocumentGroup` behavior for multi-window document editing.

## Build `.app`

To generate `A2te.app` for double-click launch:

```bash
./scripts/package_app.sh
```

Outputs:

- `.build/dist/A2te.app`
- `dist/A2te.app`
- `A2te.app` is for local launch by double-click.

## Unsigned / Unnotarized Distribution Note

Current builds are unsigned and not notarized. If macOS shows a warning on first launch, right-click `A2te.app` in Finder and choose `Open` (or allow it from Privacy & Security settings).

## Keyboard Operation

- `Tab`: switch focused pane (Editor ↔ Tile Reference)
- Arrow keys (depends on focused pane):
  - **Editor**: move the edit cursor within the current tile
  - **Tile Reference**: move the selected slot in the 16-wide grid (left/right ±1, up/down ±16)
- `[` `]`: previous / next selected slot (works in either pane; updates the reference selection unless every tile is selected)

**Editor** (ignored while the editor is read-only, e.g. all tiles selected in Reference)

- `Space`: toggle the bit at the cursor (pixel on/off)
- `Delete`: turn the bit at the cursor off
- `g`: toggle the current row’s hires group (bit 7)
- `o` / `e`: set X parity display to **O**dd / **E**ven
- `i`: toggle palette **I**nverted / Normal for the active slot

**Tile Reference**

- `⌘A`: select all tiles
- `Escape`: when all tiles are selected, clear selection to the active slot only
- `o` / `e`, `i`: same parity and palette toggles as in the editor; `i` applies to the current reference selection (one or many slots)
