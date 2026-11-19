import AppKit
import RadarStories
import SwiftUI

/// The component catalog: cmux-radar's Storybook. `make catalog`.
@main
struct CatalogApp: App {
    @NSApplicationDelegateAdaptor(CatalogAppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup("Radar Catalog") {
            CatalogView()
                .frame(minWidth: 1100, minHeight: 720)
        }
        .windowToolbarStyle(.unified)
    }
}

/// `swift run` launches a bare executable; make it a regular, frontmost app with a Dock icon.
final class CatalogAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        true
    }
}
