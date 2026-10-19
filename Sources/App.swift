import SwiftUI
import AppKit

/// Shared constants and small helpers used across the app.
enum AppInfo {
    static let mainWindowID = "main"

    static func openDonate() {
        NSWorkspace.shared.open(URL(string: "https://ko-fi.com/leodavidai")!)
    }
}

/// Remembers how to open the main window so non-view code (the global hotkey) can bring it up.
final class WindowOpener {
    static let shared = WindowOpener()
    var openMain: (() -> Void)?

    func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue.hasPrefix(AppInfo.mainWindowID) == true }),
           window.isVisible || window.isMiniaturized {
            window.makeKeyAndOrderFront(nil)
        } else {
            openMain?()
        }
    }
}

/// Application delegate: registers the global hotkey once the app has launched.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        HotKeyManager.shared.onPress = { WindowOpener.shared.showMainWindow() }
        HotKeyManager.shared.registerFromDefaults()
    }
}

/// App entry point: the main split-view window, the menu bar extra, and the Settings scene.
@main
struct ClipMergeEditorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = ClipStore()

    var body: some Scene {
        Window("ClipMergeEditor", id: AppInfo.mainWindowID) {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 760, minHeight: 460)
        }
        .defaultSize(width: 980, height: 620)

        MenuBarExtra("ClipMergeEditor", systemImage: "doc.on.clipboard") {
            MenuBarContent()
                .environmentObject(store)
        }

        Settings {
            SettingsView()
                .environmentObject(store)
        }
    }
}

/// Menu bar dropdown: open window, quick-copy recent clips, pause, settings, donate, quit.
struct MenuBarContent: View {
    @EnvironmentObject private var store: ClipStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open ClipMergeEditor") {
            WindowOpener.shared.openMain = { openWindow(id: AppInfo.mainWindowID) }
            WindowOpener.shared.showMainWindow()
        }
        Divider()
        if store.clips.isEmpty {
            Text("No clips yet")
        } else {
            ForEach(store.clips.prefix(5)) { clip in
                Button(clip.menuTitle) { store.copyToPasteboard(clip.text) }
            }
        }
        Divider()
        Toggle("Pause Recording", isOn: $store.isPaused)
        SettingsLink { Text("Settings…") }
            .keyboardShortcut(",")
        Button("Support / Donate ❤️") { AppInfo.openDonate() }
        Divider()
        Button("Quit ClipMergeEditor") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
