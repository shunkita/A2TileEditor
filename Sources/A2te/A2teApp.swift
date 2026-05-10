import SwiftUI

@main
struct A2teApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        DocumentGroup(newDocument: A2teProjectDocument()) { configuration in
            DocumentEditorHost(configuration: configuration)
        }
        .defaultSize(width: 1016, height: 860)
    }
}
