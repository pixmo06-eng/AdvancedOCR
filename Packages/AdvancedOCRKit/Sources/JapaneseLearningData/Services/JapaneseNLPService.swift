import Foundation
import NaturalLanguage
import JapaneseLearningDomain

public final class JapaneseNLPService: Sendable {
    public init() {}

    public func extractTokens(from text: String) -> [VocabularyItem] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        tokenizer.setLanguage(.japanese)

        var words: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let token = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if self.isJapaneseWord(token) {
                words.append(token)
            }
            return true
        }

        let uniqueWords = Array(NSOrderedSet(array: words)) as? [String] ?? []
        return uniqueWords.map(makeVocabularyItem)
    }

    private func isJapaneseWord(_ word: String) -> Bool {
        guard word.count >= 2 else { return false }
        return word.unicodeScalars.contains(where: isJapaneseScalar)
    }

    private func isJapaneseScalar(_ scalar: UnicodeScalar) -> Bool {
        let value = scalar.value
        let isHiragana = (0x3040...0x309F).contains(value)
        let isKatakana = (0x30A0...0x30FF).contains(value)
        let isKanji = (0x4E00...0x9FAF).contains(value)
        return isHiragana || isKatakana || isKanji
    }

    private func makeVocabularyItem(for word: String) -> VocabularyItem {
        let example = DailyLifeExample(
            japanese: "\(word)を使います。",
            reading: "\(word)をつかいます。",
            english: "Use \(word) in daily conversation.",
            scenario: "Daily Practice"
        )
        return VocabularyItem(
            word: word,
            reading: word,
            meaning: "Extracted from lesson",
            partOfSpeech: "General",
            isNewWord: true,
            examples: [example]
        )
    }
}
