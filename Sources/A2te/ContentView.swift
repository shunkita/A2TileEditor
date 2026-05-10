import A2teCore
import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: EditorState
    @State var keyMonitor: Any?

    var body: some View {
        // Leading alignment avoids centering fixed-width panes in a wide window (empty side gutters).
        VStack(alignment: .leading, spacing: 8) {
            headerBar
            VStack(alignment: .leading, spacing: 8) {
                editorPane
                referencePane
            }
            .frame(minWidth: 760, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(nsColor: NSColor(white: 0.94, alpha: 1.0))
                .ignoresSafeArea()
        )
        .preferredColorScheme(.light)
        .padding(10)
        .alert("A2te", isPresented: $state.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(state.alertMessage)
        }
        .onAppear { installKeyMonitor() }
        .onDisappear { removeKeyMonitor() }
    }
}

#Preview {
    ContentView()
        .environmentObject(EditorState(previewSnapshot: .emptyNew()))
}
