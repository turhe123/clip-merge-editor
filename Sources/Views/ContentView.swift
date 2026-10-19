import SwiftUI

/// Main window: searchable history list on the left, merge editor on the right.
struct ContentView: View {
    @EnvironmentObject private var store: ClipStore
    @Environment(\.openWindow) private var openWindow

    @State private var selection = Set<UUID>()
    @State private var selectionOrder: [UUID] = []
    @State private var search = ""
    @State private var draft = ""
    @State private var generated = ""
    @State private var truncated = false
    @State private var confirmDiscard = false
    @State private var confirmClear = false

    @AppStorage("separator") private var separator: Separator = .newLine
    @AppStorage("customSeparator") private var customSeparator = " | "
    @AppStorage("mergeOrder") private var order: MergeOrder = .copied

    private var isDirty: Bool { draft != generated && !draft.isEmpty }

    private var filtered: [Clip] {
        let q = search.trimmingCharacters(in: .whitespaces)
        return q.isEmpty ? store.clips : store.clips.filter { $0.text.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        NavigationSplitView {
            historyList
                .navigationSplitViewColumnWidth(min: 260, ideal: 320)
        } detail: {
            editorPane
        }
        .searchable(text: $search, placement: .sidebar, prompt: "Search clips")
        .onAppear { WindowOpener.shared.openMain = { openWindow(id: AppInfo.mainWindowID) } }
        .onChange(of: selection) { _, newValue in
            selectionOrder.removeAll { !newValue.contains($0) }
            selectionOrder.append(contentsOf: newValue.filter { !selectionOrder.contains($0) }
                .sorted { date(of: $0) < date(of: $1) })
            if isDirty { confirmDiscard = true } else { regenerate() }
        }
        .onChange(of: separator) { _, _ in if !isDirty { regenerate() } }
        .onChange(of: customSeparator) { _, _ in if !isDirty { regenerate() } }
        .onChange(of: order) { _, _ in if !isDirty { regenerate() } }
        .alert("Discard your edits?", isPresented: $confirmDiscard) {
            Button("Discard", role: .destructive) { regenerate() }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("The draft was edited. Loading the new selection will replace it.")
        }
        .alert("Clear all history?", isPresented: $confirmClear) {
            Button("Clear", role: .destructive) { store.clearAll(); selection.removeAll() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: History

    private var historyList: some View {
        Group {
            if store.clips.isEmpty {
                ContentUnavailableView("No clips yet", systemImage: "doc.on.clipboard",
                                       description: Text("Copy some text in any app and it will appear here."))
            } else {
                List(filtered, selection: $selection) { clip in
                    ClipRow(clip: clip, isSelected: selection.contains(clip.id)) {
                        if selection.contains(clip.id) { selection.remove(clip.id) } else { selection.insert(clip.id) }
                    }
                    .tag(clip.id)
                    .contextMenu {
                        Button("Open in Editor") { selection = [clip.id] }
                        Button("Copy") { store.copyToPasteboard(clip.text) }
                        Divider()
                        Button("Delete", role: .destructive) { delete([clip.id]) }
                    }
                }
                .onDeleteCommand { delete(selection) }
            }
        }
        .toolbar {
            ToolbarItem {
                Button { confirmClear = true } label: { Label("Clear History", systemImage: "trash") }
                    .disabled(store.clips.isEmpty)
                    .help("Clear all history")
            }
        }
    }

    private func delete(_ ids: Set<UUID>) {
        store.delete(ids)
        selection.subtract(ids)
    }

    private func date(of id: UUID) -> Date {
        store.clips.first { $0.id == id }?.date ?? .distantPast
    }

    // MARK: Editor

    private var editorPane: some View {
        VStack(spacing: 0) {
            if let notice = store.notice {
                banner(notice, color: .orange) { store.notice = nil }
            }
            if truncated {
                banner("The merged result exceeded \(TextTools.maxCharacters.formatted()) characters and was truncated.",
                       color: .yellow) { truncated = false }
            }
            ZStack {
                TextEditor(text: $draft)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                if draft.isEmpty {
                    Text(selection.isEmpty ? "Select two or more clips to merge them" : "The selected clips are empty")
                        .foregroundStyle(.secondary)
                        .allowsHitTesting(false)
                }
            }
            .background(Color(nsColor: .textBackgroundColor))
            Divider()
            editorToolbar
        }
    }

    private var editorToolbar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("Separator", selection: $separator) {
                    ForEach(Separator.allCases) { Text($0.rawValue).tag($0) }
                }
                .frame(maxWidth: 220)
                if separator == .custom {
                    TextField("Custom", text: $customSeparator)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                }
                Picker("Order", selection: $order) {
                    ForEach(MergeOrder.allCases) { Text($0.rawValue).tag($0) }
                }
                .labelsHidden()
                .frame(maxWidth: 150)
                Button("Merge") { regenerate() }
                    .disabled(selection.isEmpty)
                    .keyboardShortcut("m", modifiers: [.command])
                Spacer()
            }
            HStack {
                Button("Trim") { apply(TextTools.trim) }
                Button("Remove Duplicates") { apply(TextTools.removeDuplicateLines) }
                Button("Sort Lines") { apply(TextTools.sortLines) }
                Button("Number Lines") { apply(TextTools.numberLines) }
                Spacer()
                Text("\(TextTools.lineCount(draft)) lines · \(draft.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Button("Copy") { store.copyToPasteboard(draft) }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                Button("Save as Clip") {
                    store.add(draft, appName: "ClipMergeEditor")
                    generated = draft
                }
                .keyboardShortcut("s", modifiers: [.command])
                .buttonStyle(.borderedProminent)
            }
            .disabled(draft.isEmpty)
        }
        .padding(10)
    }

    private func apply(_ transform: (String) -> String) {
        draft = transform(draft)
    }

    /// Rebuilds the draft from the current selection, separator and order.
    private func regenerate() {
        let byID = Dictionary(uniqueKeysWithValues: store.clips.map { ($0.id, $0) })
        let chosen: [Clip]
        switch order {
        case .copied:
            chosen = store.clips.filter { selection.contains($0.id) }.sorted { $0.date < $1.date }
        case .selected:
            chosen = selectionOrder.compactMap { byID[$0] }
        }
        let result = TextTools.merge(chosen.map(\.text), separator: separator.value(custom: customSeparator))
        truncated = result.truncated
        draft = result.text
        generated = result.text
    }

    private func banner(_ text: String, color: Color, dismiss: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(color)
            Text(text).font(.callout)
            Spacer()
            Button("Dismiss", action: dismiss).buttonStyle(.link)
        }
        .padding(8)
        .background(color.opacity(0.15))
    }
}

/// One history row: hover checkbox, two-line preview, source app and relative time.
struct ClipRow: View {
    let clip: Clip
    let isSelected: Bool
    let toggle: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                .opacity(hovering || isSelected ? 1 : 0)
                .onTapGesture(perform: toggle)
                .help("Add to or remove from selection")
            VStack(alignment: .leading, spacing: 3) {
                Text(clip.text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(300))
                    .lineLimit(2)
                HStack(spacing: 4) {
                    if let app = clip.appName { Text(app) ; Text("·") }
                    Text(clip.date, format: .relative(presentation: .named))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }
}
