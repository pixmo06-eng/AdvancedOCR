import Foundation
import NaturalLanguage
import JapaneseLearningDomain

public final class LocalJapaneseAIModel: LocalJapaneseAIProtocol {
    private let nlpService: JapaneseNLPService
    private let textCleaner: JapaneseTextCleaner

    public init(
        nlpService: JapaneseNLPService = JapaneseNLPService(),
        textCleaner: JapaneseTextCleaner = JapaneseTextCleaner()
    ) {
        self.nlpService = nlpService
        self.textCleaner = textCleaner
    }

    public func correctOCRText(_ rawText: String) -> String {
        textCleaner.clean(text: rawText)
    }

    public func generateSentences(
        for word: String,
        reading: String,
        meaning: String
    ) async -> [DailyLifeExample] {
        var examples: [DailyLifeExample] = []
        let cleanWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanWord.isEmpty else { return [] }

        examples.append(makeRoutineExample(for: cleanWord))
        examples.append(makeServiceExample(for: cleanWord))
        examples.append(makeConversationExample(for: cleanWord))
        return examples
    }

    public func extractGrammar(
        from text: String,
        pageCode: String?,
        category: String?,
        lessonId: UUID
    ) async -> [GrammarItem] {
        let cleaned = textCleaner.clean(text: text)
        var items: [GrammarItem] = []
        let rules = grammarRuleCatalog()

        for rule in rules {
            guard rule.keywords.contains(where: { cleaned.contains($0) }) else { continue }
            let examples = [
                makeGrammarExample(pattern: rule.pattern, scenario: "日常生活"),
                makeGrammarExample(pattern: rule.pattern, scenario: "日常会話")
            ]
            let item = GrammarItem(
                pattern: rule.pattern,
                meaning: rule.meaning,
                formation: rule.formation,
                explanation: rule.explanation,
                jlptLevel: rule.jlpt,
                examples: examples,
                lessonId: lessonId,
                pageCode: pageCode,
                category: category
            )
            items.append(item)
        }
        return items
    }

    public func suggestVocabulary(
        from text: String,
        pageCode: String?,
        category: String?,
        lessonId: UUID
    ) async -> [VocabularyItem] {
        let cleaned = textCleaner.clean(text: text)
        let rawTokens = nlpService.extractTokens(from: cleaned)
        let verifiedTokens = await verifyVocabulary(candidates: rawTokens, contextText: cleaned)
        var results: [VocabularyItem] = []

        for item in verifiedTokens {
            let generated = await generateSentences(for: item.word, reading: item.reading, meaning: item.meaning)
            let updated = VocabularyItem(
                id: item.id,
                word: item.word,
                reading: item.reading,
                meaning: item.meaning,
                partOfSpeech: item.partOfSpeech,
                jlptLevel: item.jlptLevel,
                isNewWord: item.isNewWord,
                occurrenceCount: item.occurrenceCount,
                masteryStatus: item.masteryStatus,
                examples: generated,
                firstLessonId: lessonId,
                pageCode: pageCode,
                category: category
            )
            results.append(updated)
        }
        return results
    }

    public func verifyVocabulary(
        candidates: [VocabularyItem],
        contextText: String
    ) async -> [VocabularyItem] {
        let cleanContext = textCleaner.clean(text: contextText)
        guard !cleanContext.isEmpty else { return [] }

        let tagMap = buildLexicalTagMap(for: cleanContext)
        var verifiedItems: [VocabularyItem] = []
        var seenWords = Set<String>()

        for item in candidates {
            let word = item.word.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !seenWords.contains(word) else { continue }
            guard isValidJapaneseCandidate(word, in: cleanContext, tag: tagMap[word]) else { continue }

            seenWords.insert(word)
            let resolvedPOS = resolvePOS(for: word, tag: tagMap[word], existing: item.partOfSpeech)
            let verified = buildVerifiedItem(from: item, word: word, pos: resolvedPOS)
            verifiedItems.append(verified)
        }

        return verifiedItems
    }

    private func buildLexicalTagMap(for text: String) -> [String: NLTag] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        tagger.setLanguage(.japanese, range: text.startIndex..<text.endIndex)

        var map: [String: NLTag] = [:]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            let token = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if let tag, !token.isEmpty {
                map[token] = tag
            }
            return true
        }
        return map
    }

    private func isValidJapaneseCandidate(_ word: String, in context: String, tag: NLTag?) -> Bool {
        guard !word.isEmpty else { return false }
        guard context.contains(word) else { return false }
        guard !word.unicodeScalars.contains(where: \.isASCII) else { return false }
        guard !Self.disallowedWords.contains(word) else { return false }

        if let tag {
            let invalidTags: Set<NLTag> = [.particle, .conjunction, .punctuation, .whitespace, .number]
            guard !invalidTags.contains(tag) else { return false }
        }

        let hasKanji = word.unicodeScalars.contains(where: isKanji)
        return hasKanji || word.count >= 2
    }

    private func resolvePOS(for word: String, tag: NLTag?, existing: String) -> String {
        if !existing.isEmpty && !existing.unicodeScalars.contains(where: \.isASCII) && existing != "General" {
            return existing
        }
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

    private func buildVerifiedItem(from item: VocabularyItem, word: String, pos: String) -> VocabularyItem {
        let cleanExamples = sanitizeExamples(item.examples)
        return VocabularyItem(
            id: item.id,
            word: word,
            reading: item.reading.isEmpty ? word : item.reading,
            romaji: item.displayRomaji,
            meaning: item.meaning,
            partOfSpeech: pos,
            jlptLevel: item.jlptLevel,
            isNewWord: item.isNewWord,
            occurrenceCount: item.occurrenceCount,
            masteryStatus: item.masteryStatus,
            examples: cleanExamples,
            firstLessonId: item.firstLessonId,
            pageId: item.pageId,
            pageCode: item.pageCode,
            category: item.category,
            createdAt: item.createdAt
        )
    }

    private func sanitizeExamples(_ examples: [DailyLifeExample]) -> [DailyLifeExample] {
        examples.map { example in
            DailyLifeExample(
                id: example.id,
                japanese: example.japanese,
                reading: example.reading,
                romaji: example.displayRomaji,
                english: example.english.isEmpty ? "Example using \(example.japanese)" : example.english,
                scenario: example.scenario
            )
        }
    }

    private func isKanji(_ scalar: UnicodeScalar) -> Bool {
        (0x4E00...0x9FAF).contains(scalar.value)
    }

    private static let disallowedWords: Set<String> = [
        "は", "が", "を", "に", "で", "へ", "と", "も", "の", "や", "から", "まで",
        "より", "だけ", "しか", "ば", "たら", "なら", "ね", "よ", "わ", "ぞ", "ぜ",
        "さ", "て", "し", "たり", "だり", "ながら", "ので", "のに", "けど", "けれど",
        "です", "ます", "でした", "ました", "ません", "たい", "ない",
        "くもん", "クモン", "Kumon", "プリント", "ページ", "番号", "月", "日", "名前",
        "なまえ", "てん", "時間", "ふん", "分"
    ]

    private func makeRoutineExample(for word: String) -> DailyLifeExample {
        let meaning = JapaneseDictionaryLookup.lookup(word: word) ?? word
        let reading = "まいにちの せいかつで「\(word)」を よく つかいます。"
        return DailyLifeExample(
            japanese: "毎日の生活で「\(word)」をよく使います。",
            reading: reading,
            romaji: JapaneseRomajiConverter.toRomaji(from: reading),
            english: "I often use \"\(meaning)\" in daily life.",
            scenario: "日常生活"
        )
    }

    private func makeServiceExample(for word: String) -> DailyLifeExample {
        let meaning = JapaneseDictionaryLookup.lookup(word: word) ?? word
        let reading = "おみせで「\(word)」について たずねました。"
        return DailyLifeExample(
            japanese: "お店で「\(word)」について尋ねました。",
            reading: reading,
            romaji: JapaneseRomajiConverter.toRomaji(from: reading),
            english: "I asked about \"\(meaning)\" at the shop.",
            scenario: "買い物・店舗"
        )
    }

    private func makeConversationExample(for word: String) -> DailyLifeExample {
        let meaning = JapaneseDictionaryLookup.lookup(word: word) ?? word
        let reading = "ともだちと いっしょに「\(word)」を はなしました。"
        return DailyLifeExample(
            japanese: "友達と一緒に「\(word)」を話しました。",
            reading: reading,
            romaji: JapaneseRomajiConverter.toRomaji(from: reading),
            english: "I talked about \"\(meaning)\" with a friend.",
            scenario: "日常会話"
        )
    }

    private func makeGrammarExample(pattern: String, scenario: String) -> DailyLifeExample {
        let clean = pattern.replacingOccurrences(of: "〜", with: "")
        let reading = "にちじょうかいわで \(clean)の ぶんけいを つかって はなします。"
        return DailyLifeExample(
            japanese: "日常会話で\(clean)の文型を使って話します。",
            reading: reading,
            romaji: JapaneseRomajiConverter.toRomaji(from: reading),
            english: "Speaking using the \(pattern) structure in daily conversation.",
            scenario: scenario
        )
    }

    private func grammarRuleCatalog() -> [GrammarRuleDef] {
        [
            GrammarRuleDef(keywords: ["てください", "でください"], pattern: "〜てください", meaning: "Please do (polite request)", formation: "動詞て形 ＋ ください", explanation: "相手にていねいに行動をお願いするときに使います。", jlpt: "N5"),
            GrammarRuleDef(keywords: ["てもいい", "でもいい"], pattern: "〜てもいい", meaning: "May do / Permission", formation: "動詞て形 ＋ もいい", explanation: "許可を求めたり与えたりするときに使います。", jlpt: "N5"),
            GrammarRuleDef(keywords: ["てはいけない", "ではいけない"], pattern: "〜てはいけない", meaning: "Must not do / Prohibition", formation: "動詞て形 ＋ はいけない", explanation: "規則や強い禁止を表します。", jlpt: "N5"),
            GrammarRuleDef(keywords: ["なければならない", "なきゃいけない"], pattern: "〜なければならない", meaning: "Must do / Obligation", formation: "動詞ない形 ＋ ければならない", explanation: "義務や必要な行動を表します。", jlpt: "N5"),
            GrammarRuleDef(keywords: ["ている", "でいる"], pattern: "〜ている", meaning: "Continuous action / Ongoing state", formation: "動詞て形 ＋ いる", explanation: "現在進行中の動作や継続する状態を表します。", jlpt: "N5"),
            GrammarRuleDef(keywords: ["たことがある", "だことがある"], pattern: "〜たことがある", meaning: "Have done before (Experience)", formation: "動詞た形 ＋ ことがある", explanation: "過去の経験を表します。", jlpt: "N5"),
            GrammarRuleDef(keywords: ["たいです", "たい"], pattern: "〜たい", meaning: "Want to do (Desire)", formation: "動詞ます形語幹 ＋ たい", explanation: "話し手の希望を表します。", jlpt: "N5")
        ]
    }

}

private struct GrammarRuleDef {
    let keywords: [String]
    let pattern: String
    let meaning: String
    let formation: String
    let explanation: String
    let jlpt: String
}

