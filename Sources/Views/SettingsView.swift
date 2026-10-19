import SwiftUI
import ServiceManagement

/// Settings window: history size, duplicates, ignored apps, global hotkey, launch at login, donate.
struct SettingsView: View {
    @EnvironmentObject private var store: ClipStore

    @AppStorage(SettingsKey.historySize) private var historySize = ClipStore.maxHistory
    @AppStorage(SettingsKey.skipDuplicates) private var skipDuplicates = true
    @AppStorage(SettingsKey.ignoredApps) private var ignoredApps = ""

    @AppStorage(HotKeyManager.Key.enabled) private var hotkeyEnabled = true
    @AppStorage(HotKeyManager.Key.letter) private var hotkeyLetter = HotKeyManager.keyDefault
    @AppStorage(HotKeyManager.Key.cmd) private var hkCmd = true
    @AppStorage(HotKeyManager.Key.shift) private var hkShift = true
    @AppStorage(HotKeyManager.Key.option) private var hkOption = false
    @AppStorage(HotKeyManager.Key.control) private var hkControl = false

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section("History") {
                Stepper("Keep up to \(historySize) clips", value: $historySize, in: 10...ClipStore.maxHistory, step: 10)
                    .onChange(of: historySize) { _, _ in store.enforceLimit() }
                Toggle("Skip duplicates (move existing clip to top)", isOn: $skipDuplicates)
                Toggle("Pause recording", isOn: $store.isPaused)
            }

            Section {
                TextEditor(text: $ignoredApps)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 70)
            } header: {
                Text("Ignored Apps")
            } footer: {
                Text("One app name or bundle identifier per line, e.g. Keychain Access or com.apple.keychainaccess.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Global Hotkey (opens the window)") {
                Toggle("Enabled", isOn: $hotkeyEnabled)
                HStack {
                    Toggle("⌃", isOn: $hkControl)
                    Toggle("⌥", isOn: $hkOption)
                    Toggle("⇧", isOn: $hkShift)
                    Toggle("⌘", isOn: $hkCmd)
                    Picker("Key", selection: $hotkeyLetter) {
                        ForEach(HotKeyManager.letters.keys.sorted(), id: \.self) { Text($0).tag($0) }
                    }
                    .frame(width: 110)
                }
                .disabled(!hotkeyEnabled)
                if hotkeyEnabled && !(hkCmd || hkShift || hkOption || hkControl) {
                    Text("Choose at least one modifier key.").font(.caption).foregroundStyle(.orange)
                }
            }
            .onChange(of: hotkeySignature) { _, _ in HotKeyManager.shared.registerFromDefaults() }

            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
                if let loginError {
                    Text(loginError).font(.caption).foregroundStyle(.red)
                }
            }

            Section {
                HStack {
                    Text("ClipMergeEditor is free and open source.")
                    Spacer()
                    Button("Support / Donate ❤️") { AppInfo.openDonate() }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 600)
    }

    private var hotkeySignature: String {
        "\(hotkeyEnabled)\(hotkeyLetter)\(hkCmd)\(hkShift)\(hkOption)\(hkControl)"
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            loginError = nil
        } catch {
            loginError = "Could not update login item: \(error.localizedDescription). You can manage it in System Settings › General › Login Items."
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
