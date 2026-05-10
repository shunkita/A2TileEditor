import SwiftUI

/// One window per document; wires `FileDocument` to `EditorState`.
struct DocumentEditorHost: View {
    let configuration: FileDocumentConfiguration<A2teProjectDocument>

    @StateObject private var state: EditorState

    init(configuration: FileDocumentConfiguration<A2teProjectDocument>) {
        self.configuration = configuration
        _state = StateObject(wrappedValue: EditorState(document: configuration.$document))
    }

    var body: some View {
        ContentView()
            .environmentObject(state)
            .onAppear {
                state.documentFileURL = configuration.fileURL
                state.applySnapshot(configuration.document.snapshot)
            }
            .onChange(of: configuration.fileURL) { _, newValue in
                state.documentFileURL = newValue
            }
            .onChange(of: configuration.document.snapshot) { _, newSnapshot in
                state.applySnapshot(newSnapshot)
            }
    }
}
