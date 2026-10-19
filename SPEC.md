# ClipMergeEditor — specification

**Tagline:** Select several clipboard entries, merge them with a separator, edit the result, and paste it as one clip.

**Category:** Clipboard

**Inspired by (paid):** ClipBook ($9.99 one-time)

**Frameworks:** SwiftUI, AppKit, UniformTypeIdentifiers, ServiceManagement

**Donation URL (Support button):** https://ko-fi.com/leodavidai

## Spec

What the paid app does and the demand. ClipBook is a native clipboard history app with a free trial and paid pricing starting at 9.99 dollars as a one-time payment, listed on Capterra and appearing in 2026 clipboard roundups next to Maccy and Paste. Users of clipboard history often want to combine and clean up several copied pieces, such as a list of names or several quotes, before pasting. Our clean-room version, ClipMergeEditor, centers on that: multi-select, merge, edit, paste.

Feature set. The app keeps a history of copied text, up to 200 items. In the history window, hold Command or Shift to select multiple rows. A Merge button builds a new clip by joining the chosen items in the order copied or in the order selected, using a separator from a popup: new line, blank line, comma and space, tab, or a custom string. A built-in editor pane shows the merged result and lets you edit it, with quick buttons to trim whitespace, remove duplicate lines, sort lines, and number lines. Copy puts the result on the pasteboard, and Save as Clip adds it to history. Single items can also be opened in the editor.

UI spec. A normal window app with a MenuBarExtra that opens the window, shows the last five clips for a quick copy, and holds Pause Recording, Settings and Quit. The window is a split view. The left side is a searchable list with checkboxes appearing on hover, showing a two line preview and relative time. The right side shows the editor above a toolbar with the separator popup, order popup, the four cleaning buttons and the Copy and Save buttons, plus a live line and character count. Settings has history size, a toggle to skip duplicates, an ignored apps list, the global hotkey for opening the window (default Command Shift M), and launch at login. Empty states read No clips yet and Select two or more clips to merge them.

Technical approach. Poll NSPasteboard changeCount every 0.4 seconds, read the string and record the frontmost app name. Skip concealed and transient types. Persist history as JSON in Application Support, written atomically after each change. The list uses SwiftUI List with a multiple selection set of UUIDs, and the merge function sorts by the date or selection order held in an array. The editor is a SwiftUI TextEditor bound to a draft string. Cleaning functions use Swift string operations: trimming lines, removing repeated lines while keeping the first occurrence, sorting lines with localized standard comparison, and numbering with a counter prefix. The global hotkey uses Carbon. Launch at login uses SMAppService. No special permissions are required, since only the clipboard is read and nothing is pasted automatically.

Edge cases. When the draft was edited and the user selects different rows, ask before discarding it. Prevent the editor result from being re-recorded as a duplicate by remembering the change count after writing. Handle an empty selection by disabling Merge. Limit the merged result to a few million characters and show a warning rather than freezing. Preserve line endings by normalizing carriage returns to new lines on merge. If the history file cannot be read, back it up and start empty with a notice. Keep undo working inside the editor through the standard text undo manager.
