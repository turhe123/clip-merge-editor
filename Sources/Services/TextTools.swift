import Foundation

/// Separator choices offered by the merge popup.
enum Separator: String, CaseIterable, Identifiable {
    case newLine = "New Line"
    case blankLine = "Blank Line"
    case commaSpace = "Comma and Space"
    case tab = "Tab"
    case custom = "Custom…"

    var id: String { rawValue }

    func value(custom: String) -> String {
        switch self {
        case .newLine: return "\n"
        case .blankLine: return "\n\n"
        case .commaSpace: return ", "
        case .tab: return "\t"
        case .custom: return custom
        }
    }
}

/// Order in which selected clips are joined.
enum MergeOrder: String, CaseIterable, Identifiable {
    case copied = "Order Copied"
    case selected = "Order Selected"
    var id: String { rawValue }
}

/// Pure string operations for merging and cleaning the draft.
enum TextTools {
    /// Upper bound for a merged result; larger results are truncated with a warning.
    static let maxCharacters = 3_000_000

    static func normalizeLineEndings(_ s: String) -> String {
        s.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
    }

    /// Joins texts with the separator; returns the result and whether it was truncated.
    static func merge(_ texts: [String], separator: String) -> (text: String, truncated: Bool) {
        var result = ""
        for (index, raw) in texts.enumerated() {
            if index > 0 { result += separator }
            result += normalizeLineEndings(raw)
            if result.utf16.count > maxCharacters {
                return (String(result.prefix(maxCharacters)), true)
            }
        }
        return (result, false)
    }

    private static func lines(_ s: String) -> [String] {
        s.components(separatedBy: "\n")
    }

    /// Trims whitespace on every line and drops leading/trailing blank lines.
    static func trim(_ s: String) -> String {
        var out = lines(s).map { $0.trimmingCharacters(in: .whitespaces) }
        while out.first?.isEmpty == true { out.removeFirst() }
        while out.last?.isEmpty == true { out.removeLast() }
        return out.joined(separator: "\n")
    }

    /// Removes repeated lines, keeping the first occurrence.
    static func removeDuplicateLines(_ s: String) -> String {
        var seen = Set<String>()
        return lines(s).filter { seen.insert($0).inserted }.joined(separator: "\n")
    }

    static func sortLines(_ s: String) -> String {
        lines(s).sorted { $0.localizedStandardCompare($1) == .orderedAscending }.joined(separator: "\n")
    }

    static func numberLines(_ s: String) -> String {
        lines(s).enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
    }

    static func lineCount(_ s: String) -> Int {
        s.isEmpty ? 0 : lines(s).count
    }
}
