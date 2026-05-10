import AppKit

extension ContentView {
    func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKey(event) ? nil : event
        }
    }

    func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    func handleKey(_ event: NSEvent) -> Bool {
        guard !isTextInputFocused() else { return false }
        if handleCommandShortcut(event) { return true }
        if handleCharacterShortcut(event) { return true }
        return handleKeyCodeShortcut(event)
    }

    func isTextInputFocused() -> Bool {
        guard let responder = NSApp.keyWindow?.firstResponder else { return false }
        if responder is NSTextField {
            return true
        }
        if let textView = responder as? NSTextView {
            return textView.isFieldEditor || textView.isEditable
        }
        return false
    }

    private func handleCommandShortcut(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.contains(.command),
              let characters = event.charactersIgnoringModifiers?.lowercased(),
              characters == "a",
              state.focusedPane == .reference else {
            return false
        }
        state.selectAllReferenceTiles()
        return true
    }

    private func handleCharacterShortcut(_ event: NSEvent) -> Bool {
        guard let characters = event.charactersIgnoringModifiers,
              characters.count == 1,
              let character = characters.first else {
            return false
        }

        switch character.lowercased() {
        case " ":
            if !state.isEditorReadOnly {
                state.toggleCurrentBit()
            }
            return true
        case "g":
            if !state.isEditorReadOnly {
                state.toggleCurrentRowGroup()
            }
            return true
        case "o":
            guard isEditorOrReferenceFocused() else { return false }
            state.setSelectedXParity(.odd)
            return true
        case "e":
            guard isEditorOrReferenceFocused() else { return false }
            state.setSelectedXParity(.even)
            return true
        case "i":
            guard isEditorOrReferenceFocused() else { return false }
            if state.focusedPane == .reference {
                state.togglePaletteInvertedForReferenceSelection()
            } else {
                state.toggleSelectedPaletteInverted()
            }
            return true
        case "[":
            state.moveSlot(delta: -1)
            return true
        case "]":
            state.moveSlot(delta: 1)
            return true
        default:
            return false
        }
    }

    private func handleKeyCodeShortcut(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 123: // left
            if state.focusedPane == .reference {
                state.moveSlot(delta: -1)
            } else {
                state.moveEditorCursor(dx: -1, dy: 0)
            }
            return true
        case 124: // right
            if state.focusedPane == .reference {
                state.moveSlot(delta: 1)
            } else {
                state.moveEditorCursor(dx: 1, dy: 0)
            }
            return true
        case 125: // down
            if state.focusedPane == .reference {
                state.moveSlot(delta: 16)
            } else {
                state.moveEditorCursor(dx: 0, dy: 1)
            }
            return true
        case 126: // up
            if state.focusedPane == .reference {
                state.moveSlot(delta: -16)
            } else {
                state.moveEditorCursor(dx: 0, dy: -1)
            }
            return true
        case 51: // delete
            if state.focusedPane == .editor, !state.isEditorReadOnly {
                state.setCurrentBit(false)
            }
            return true
        case 53: // escape
            if state.isReferenceAllSelected {
                state.clearReferenceSelectionToActive()
                state.statusMessage = "Cleared full selection"
                return true
            }
            return false
        case 48: // tab
            switch state.focusedPane {
            case .editor:
                state.focusedPane = .reference
            case .reference:
                state.focusedPane = .editor
            }
            return true
        default:
            return false
        }
    }

    private func isEditorOrReferenceFocused() -> Bool {
        state.focusedPane == .editor || state.focusedPane == .reference
    }
}
