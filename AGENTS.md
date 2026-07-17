# AGENTS.md

## Cursor Cloud specific instructions

**This is a macOS-only app and cannot be built or run on a Linux cloud VM.**

`A2te` is a SwiftUI + AppKit macOS application (SwiftPM package,
`Package.swift` declares `platforms: [.macOS(.v14)]`). The `A2te` executable
target imports SwiftUI/AppKit throughout, and the app relies on macOS
`DocumentGroup` behavior. `README.md` documents building with the Xcode
toolchain:

```sh
swift build
swift run A2te
```

A Linux VM has neither the Swift/Xcode macOS SDK nor AppKit/SwiftUI, so there is
no build/test/run to set up here. Do development on macOS 14+ with the Xcode
toolchain. (The `A2teCore` target holds the pure-logic pieces, e.g.
`HiresColorDecoder`, `TileCapacityMath`, but there are no test targets and the
package platform is macOS-only.)
