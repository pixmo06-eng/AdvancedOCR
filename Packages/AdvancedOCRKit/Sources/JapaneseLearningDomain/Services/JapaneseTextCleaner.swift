import Foundation

public struct JapaneseTextCleaner: Sendable {
    public init() {}

    public func clean(text: String) -> String {
        var result = text
        result = cleanSpacedJapaneseWords(in: result)
        result = cleanHeaderCodes(in: result)
        result = removeStrayPunctuation(in: result)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cleanSpacedJapaneseWords(in text: String) -> String {
        let pattern = #"(?<=[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF])\s+(?=[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return text
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
    }

    private func cleanHeaderCodes(in text: String) -> String {
        let pattern = #"(?i)\b([A-Z])\s+(\d+)\s*([a-b]?)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return text
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "$1 $2$3")
    }

    private func removeStrayPunctuation(in text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let filtered = lines.map { line in
            line.trimmingCharacters(in: CharacterSet(charactersIn: " `~_^|•-=").union(.whitespaces))
        }
        return filtered.joined(separator: "\n")
    }
}
