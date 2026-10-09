import Foundation

public enum JapaneseRomajiConverter: Sendable {
    public static func toRomaji(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        guard let latin = trimmed.applyingTransform(.toLatin, reverse: false) else {
            return trimmed
        }
        return latin.applyingTransform(.stripDiacritics, reverse: false) ?? latin
    }
}
