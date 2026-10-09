import Foundation
import NaturalLanguage
import JapaneseLearningDomain

public final class JapaneseNLPService: Sendable {
    public init() {}

    private static let disallowedWords: Set<String> = [
        "は", "が", "を", "に", "で", "へ", "と", "も", "の", "や", "から", "まで",
        "より", "だけ", "しか", "ば", "たら", "なら", "ね", "よ", "わ", "ぞ", "ぜ",
        "さ", "て", "し", "たり", "だり", "ながら", "ので", "のに", "けど", "けれど",
        "です", "ます", "でした", "ました", "ません", "たい", "ない",
        "くもん", "クモン", "Kumon", "プリント", "ページ", "番号", "月", "日", "名前",
        "なまえ", "てん", "時間", "ふん", "分"
    ]

    public func extractTokens(from text: String) -> [VocabularyItem] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        tagger.setLanguage(.japanese, range: text.startIndex..<text.endIndex)

        var candidateMap: [String: String] = [:]
        var orderedWords: [String] = []

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            let token = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard shouldAccept(token: token, tag: tag) else { return true }
            if candidateMap[token] == nil {
                orderedWords.append(token)
                candidateMap[token] = resolveJapanesePOS(tag: tag, word: token)
            }
            return true
        }

        return orderedWords.map { word in
            makeVocabularyItem(for: word, partOfSpeech: candidateMap[word] ?? "語彙")
        }
    }

    private func shouldAccept(token: String, tag: NLTag?) -> Bool {
        guard isJapaneseWord(token) else { return false }
        guard !Self.disallowedWords.contains(token) else { return false }
        guard let tag else { return true }
        let rejectedTags: Set<NLTag> = [.particle, .conjunction, .punctuation, .whitespace, .number]
        return !rejectedTags.contains(tag)
    }

    private func resolveJapanesePOS(tag: NLTag?, word: String) -> String {
        guard let tag else {
            return word.unicodeScalars.contains(where: isKanji) ? "漢字" : "語彙"
        }
        switch tag {
        case .noun: return "名詞"
        case .verb: return "動詞"
        case .adjective: return "形容詞"
        case .adverb: return "副詞"
        case .classifier: return "助数詞"
        default:
            return word.unicodeScalars.contains(where: isKanji) ? "漢字" : "語彙"
        }
    }

    private func isJapaneseWord(_ word: String) -> Bool {
        guard !word.isEmpty else { return false }
        guard !word.unicodeScalars.contains(where: \.isASCII) else { return false }
        if word.unicodeScalars.contains(where: isKanji) {
            return true
        }
        return word.count >= 2 && word.unicodeScalars.allSatisfy(isJapaneseScalar)
    }

    private func isKanji(_ scalar: UnicodeScalar) -> Bool {
        (0x4E00...0x9FAF).contains(scalar.value)
    }

    private func isJapaneseScalar(_ scalar: UnicodeScalar) -> Bool {
        let value = scalar.value
        let isHiragana = (0x3040...0x309F).contains(value)
        let isKatakana = (0x30A0...0x30FF).contains(value)
        return isHiragana || isKatakana || isKanji(scalar)
    }

    private func makeVocabularyItem(for word: String, partOfSpeech: String) -> VocabularyItem {
        let example = DailyLifeExample(
            japanese: "\(word)を使います。",
            reading: "\(word)をつかいます。",
            english: "",
            scenario: "日常練習"
        )
        return VocabularyItem(
            word: word,
            reading: word,
            meaning: "",
            partOfSpeech: partOfSpeech,
            isNewWord: true,
            examples: [example]
        )
    }
}

