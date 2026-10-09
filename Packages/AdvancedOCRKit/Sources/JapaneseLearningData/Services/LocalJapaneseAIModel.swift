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
                makeGrammarExample(pattern: rule.pattern, scenario: "Daily Life"),
                makeGrammarExample(pattern: rule.pattern, scenario: "Conversation")
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
        var results: [VocabularyItem] = []

        for token in rawTokens {
            var item = token
            item.pageCode = pageCode
            item.category = category
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

    private func makeRoutineExample(for word: String) -> DailyLifeExample {
        DailyLifeExample(
            japanese: "毎日の生活で「\(word)」をよく見かけます。",
            reading: "まいにちの せいかつで「\(word)」を よく みかけます。",
            english: "I often come across \"\(word)\" in daily life.",
            scenario: "Daily Routine"
        )
    }

    private func makeServiceExample(for word: String) -> DailyLifeExample {
        DailyLifeExample(
            japanese: "お店で「\(word)」について店員に尋ねました。",
            reading: "おみせで「\(word)」について てんいんに たずねました。",
            english: "I asked the store staff about \"\(word)\".",
            scenario: "Shopping & Store"
        )
    }

    private func makeConversationExample(for word: String) -> DailyLifeExample {
        DailyLifeExample(
            japanese: "友達と一緒に「\(word)」を楽しく勉強しました。",
            reading: "ともだちと いっしょに「\(word)」を たのしく べんきょうしました。",
            english: "I enjoyed studying \"\(word)\" together with my friend.",
            scenario: "Casual Conversation"
        )
    }

    private func makeGrammarExample(pattern: String, scenario: String) -> DailyLifeExample {
        let clean = pattern.replacingOccurrences(of: "〜", with: "")
        return DailyLifeExample(
            japanese: "日常会話で\(clean)の文型を使って話します。",
            reading: "にちじょうかいわで \(clean)の ぶんけいを つかって はなします。",
            english: "Speaking using the \(pattern) structure in everyday dialogue.",
            scenario: scenario
        )
    }

    private func grammarRuleCatalog() -> [GrammarRuleDef] {
        [
            GrammarRuleDef(keywords: ["てください", "でください"], pattern: "〜てください", meaning: "Please do (polite request)", formation: "Verb (Te-form) + ください", explanation: "Used to politely ask someone to perform an action.", jlpt: "N5"),
            GrammarRuleDef(keywords: ["てもいい", "でもいい"], pattern: "〜てもいい", meaning: "May do / Permission", formation: "Verb (Te-form) + もいい(です)", explanation: "Used to ask for or grant permission.", jlpt: "N5"),
            GrammarRuleDef(keywords: ["てはいけない", "ではいけない"], pattern: "〜てはいけない", meaning: "Must not do / Prohibition", formation: "Verb (Te-form) + はいけない", explanation: "Expresses a strong prohibition or rule.", jlpt: "N5"),
            GrammarRuleDef(keywords: ["なければならない", "なきゃいけない"], pattern: "〜なければならない", meaning: "Must do / Obligation", formation: "Verb (Nai-stem) + ければならない", explanation: "Indicates necessity, duty, or an unavoidable obligation.", jlpt: "N5"),
            GrammarRuleDef(keywords: ["ている", "でいる"], pattern: "〜ている", meaning: "Continuous action / Ongoing state", formation: "Verb (Te-form) + いる", explanation: "Expresses progressive action in progress or a lasting state.", jlpt: "N5"),
            GrammarRuleDef(keywords: ["たことがある", "だことがある"], pattern: "〜たことがある", meaning: "Have done before (Experience)", formation: "Verb (Ta-form) + ことがある", explanation: "Expresses past life experience.", jlpt: "N5"),
            GrammarRuleDef(keywords: ["たいです", "たい"], pattern: "〜たい", meaning: "Want to do", formation: "Verb (Masu-stem) + たい", explanation: "Expresses personal desire to perform an action.", jlpt: "N5")
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
