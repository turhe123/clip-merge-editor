# ClipMergeEditor

**Select several clipboard entries, merge them with a separator, edit the result, and paste it as one clip.**

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License MIT](https://img.shields.io/badge/License-MIT-green)
[![Release](https://img.shields.io/github/v/release/turhe123/clip-merge-editor)](https://github.com/turhe123/clip-merge-editor/releases/latest)

## Why

ClipMergeEditor is a free, open-source, 100% native, backend-free alternative to paid utilities in the *Clipboard* category. It was inspired by ClipBook ($9.99 one-time), a nice native clipboard manager, and focuses on one workflow: copy several things, combine them, tidy up the result, and paste it as a single clip. Everything stays on your Mac; there is no server, account, or network access.

## Features

- **Clipboard history** of copied text, up to 200 items (configurable from 10 to 200), checked every 0.4 seconds and stored as JSON in `~/Library/Application Support/ClipMergeEditor/history.json`.
- **Multi-select and merge**: hold ⌘ or ⇧ to select several clips (or use the hover checkbox), then merge them.
- **Separators**: New Line, Blank Line, Comma and Space, Tab, or a custom string.
- **Order**: join clips in the order copied or the order you selected them.
- **Built-in editor** (monospaced, with standard undo) showing the merged result, with a live line and character count.
- **Cleanup tools**: Trim (per-line whitespace and surrounding blank lines), Remove Duplicates (keeps first occurrence), Sort Lines (localized, natural ordering), Number Lines.
- **Copy** the result to the pasteboard, or **Save as Clip** to add it to history. The app's own writes are not re-recorded as duplicates.
- **Search** the history; open any single clip in the editor from its context menu; delete clips or clear all history.
- **Menu bar item** showing the last five clips for quick copy, plus Pause Recording, Settings, and Quit.
- **Privacy-minded recording**: skips concealed, transient, and auto-generated pasteboard types (e.g. password managers), and supports an ignored-apps list (by name or bundle identifier).
- **Skip duplicates** option (moves an existing identical clip to the top).
- **Global hotkey** to open the window (default ⌘⇧M; modifiers and letter are configurable).
- **Launch at login** via `SMAppService`.
- **Safety nets**: asks before discarding edited drafts, normalizes line endings on merge, truncates merged results above 3,000,000 characters with a warning, and backs up an unreadable history file instead of overwriting it.
- Text only: only plain-text clips are recorded.

## Screenshots

_Screenshots coming soon._

## Install

1. Download `ClipMergeEditor-macOS.zip` from the [latest release](https://github.com/turhe123/clip-merge-editor/releases/latest).
2. Unzip it and move `ClipMergeEditor.app` to `/Applications`.
3. Because the app is open source and not notarized, remove the quarantine attribute:

   ```bash
   xattr -cr /Applications/ClipMergeEditor.app
   ```

4. Right-click the app and choose **Open** the first time you launch it.

Requires macOS 14.0 or later.

## Build from source

You need Xcode with the macOS 14 SDK.

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project ClipMergeEditor.xcodeproj -scheme ClipMergeEditor -configuration Release -derivedDataPath ./build build
```

The app is produced at `build/Build/Products/Release/ClipMergeEditor.app`.

## Permissions

ClipMergeEditor does not request Accessibility, Screen Recording, or Microphone access, and it makes no network connections. Based on the code, this is what it uses:

- **Clipboard**: reads the general pasteboard (plain text) to build history and writes to it when you press Copy or pick a menu bar clip. It never pastes automatically.
- **Frontmost app name**: read via `NSWorkspace` to label clips and to honor the ignored-apps list. No permission prompt is needed.
- **Global hotkey**: registered with Carbon `RegisterEventHotKey`, which does not require Accessibility permission.
- **Login item**: if you enable Launch at login, macOS may show it under System Settings › General › Login Items.

## Support ❤️

If you find it useful, you can support development: [Support Or (Leo) Davidai ❤️](https://ko-fi.com/leodavidai). The app also has a **Support / Donate ❤️** button in the menu bar and in Settings.

## License

MIT © Or Davidai Bachar
