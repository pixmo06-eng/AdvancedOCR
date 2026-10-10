import Foundation

public struct ParsedPageHeader: Sendable, Equatable {
    public let pageCode: String
    public let category: String?
    public let title: String

    public init(pageCode: String, category: String?, title: String) {
        self.pageCode = pageCode
        self.category = category
        self.title = title
    }
}

public struct LessonHeaderParser: Sendable {
    public init() {}

    public func parse(text: String, fallbackIndex: Int, currentCategory: String?) -> ParsedPageHeader {
        let code = extractPageCode(from: text) ?? "Page \(fallbackIndex + 1)"
        let detectedCategory = extractCategory(from: text) ?? currentCategory
        let resolvedCategory = detectedCategory ?? "General"
        let title = makeTitle(pageCode: code, category: detectedCategory)

        return ParsedPageHeader(
            pageCode: code,
            category: resolvedCategory,
            title: title
        )
    }

    public func extractAllPageCodes(from text: String) -> [String] {
        let pattern = #"(?i)\b([A-Z]\s*\d+\s*[a-b]?)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        var codes: [String] = []
        for match in regex.matches(in: text, range: range) {
            guard let r = Range(match.range(at: 1), in: text) else { continue }
            let code = cleanPageCode(String(text[r]))
            if !codes.contains(code) {
                codes.append(code)
            }
        }
        return codes
    }

    private func extractPageCode(from text: String) -> String? {
        extractAllPageCodes(from: text).first
    }

    private func cleanPageCode(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    private func extractCategory(from text: String) -> String? {
        if let kanji = matchPattern(in: text, pattern: #"(?i)(?:かんじ|kanji)\s*(\d+)"#) {
            return "Kanji \(kanji)"
        }
        if let vocab = matchPattern(in: text, pattern: #"(?i)(?:ことば|vocabulary)\s*(\d+)"#) {
            return "Vocabulary \(vocab)"
        }
        if let grammar = matchPattern(in: text, pattern: #"(?i)(?:ぶんぽう|grammar)\s*(\d+)"#) {
            return "Grammar \(grammar)"
        }
        return nil
    }

    private func matchPattern(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > 1 else {
            return nil
        }
        guard let numRange = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[numRange])
    }

    private func makeTitle(pageCode: String, category: String?) -> String {
        guard let category, !category.isEmpty else {
            return pageCode
        }
        return "\(pageCode) - \(category)"
    }
}
