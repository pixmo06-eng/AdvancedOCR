import Foundation

public enum JapaneseRomajiConverter: Sendable {
    public static func toRomaji(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        guard let latin = trimmed.applyingTransform(.toLatin, reverse: false) else {
            return cleanPunctuation(trimmed)
        }
        let stripped = latin.applyingTransform(.stripDiacritics, reverse: false) ?? latin
        return cleanPunctuation(stripped)
    }

    private static func cleanPunctuation(_ text: String) -> String {
        text.replacingOccurrences(of: "。", with: ".")
            .replacingOccurrences(of: "、", with: ", ")
            .replacingOccurrences(of: "「", with: "\"")
            .replacingOccurrences(of: "」", with: "\"")
            .replacingOccurrences(of: "・", with: " ")
    }
}
