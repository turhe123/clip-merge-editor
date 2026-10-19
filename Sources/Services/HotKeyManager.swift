import Carbon
import Foundation

/// Registers a single global hotkey via Carbon and calls `onPress` when it fires.
final class HotKeyManager {
    static let shared = HotKeyManager()

    static let keyDefault = "M"
    static let letters: [String: Int] = [
        "A": kVK_ANSI_A, "B": kVK_ANSI_B, "C": kVK_ANSI_C, "D": kVK_ANSI_D, "E": kVK_ANSI_E,
        "F": kVK_ANSI_F, "G": kVK_ANSI_G, "H": kVK_ANSI_H, "I": kVK_ANSI_I, "J": kVK_ANSI_J,
        "K": kVK_ANSI_K, "L": kVK_ANSI_L, "M": kVK_ANSI_M, "N": kVK_ANSI_N, "O": kVK_ANSI_O,
        "P": kVK_ANSI_P, "Q": kVK_ANSI_Q, "R": kVK_ANSI_R, "S": kVK_ANSI_S, "T": kVK_ANSI_T,
        "U": kVK_ANSI_U, "V": kVK_ANSI_V, "W": kVK_ANSI_W, "X": kVK_ANSI_X, "Y": kVK_ANSI_Y,
        "Z": kVK_ANSI_Z,
    ]

    /// UserDefaults keys for the hotkey configuration.
    enum Key {
        static let enabled = "hotkeyEnabled", letter = "hotkeyLetter"
        static let cmd = "hotkeyCmd", shift = "hotkeyShift", option = "hotkeyOption", control = "hotkeyControl"
    }

    var onPress: (() -> Void)?
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    private init() {
        UserDefaults.standard.register(defaults: [Key.enabled: true, Key.letter: Self.keyDefault,
                                                  Key.cmd: true, Key.shift: true,
                                                  Key.option: false, Key.control: false])
    }

    /// Reads the configuration from UserDefaults and (re)registers the hotkey.
    func registerFromDefaults() {
        unregister()
        let d = UserDefaults.standard
        guard d.bool(forKey: Key.enabled) else { return }
        let letter = d.string(forKey: Key.letter) ?? Self.keyDefault
        guard let code = Self.letters[letter] else { return }
        var mods: UInt32 = 0
        if d.bool(forKey: Key.cmd) { mods |= UInt32(cmdKey) }
        if d.bool(forKey: Key.shift) { mods |= UInt32(shiftKey) }
        if d.bool(forKey: Key.option) { mods |= UInt32(optionKey) }
        if d.bool(forKey: Key.control) { mods |= UInt32(controlKey) }
        guard mods != 0 else { return }
        installHandlerIfNeeded()
        let hotKeyID = EventHotKeyID(signature: OSType(0x434D_4544), id: 1) // "CMED"
        RegisterEventHotKey(UInt32(code), mods, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
        hotKeyRef = nil
    }

    private func installHandlerIfNeeded() {
        guard handlerRef == nil else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            DispatchQueue.main.async { HotKeyManager.shared.onPress?() }
            return noErr
        }, 1, &spec, nil, &handlerRef)
    }
}
