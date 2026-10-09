import XCTest
@testable import JapaneseLearningDomain
@testable import JapaneseLearningData

final class LocalJapaneseAIModelTests: XCTestCase {
    func testGenerateSentences_providesRomajiAndEnglish() async {
        let model = LocalJapaneseAIModel()
        let examples = await model.generateSentences(for: "食べる", reading: "たべる", meaning: "to eat")

        XCTAssertEqual(examples.count, 3)
        XCTAssertTrue(examples.contains(where: { $0.scenario == "日常生活" }))
        XCTAssertTrue(examples.contains(where: { $0.japanese.contains("食べる") }))
        XCTAssertTrue(examples.allSatisfy { !$0.english.isEmpty })
        XCTAssertTrue(examples.allSatisfy { !$0.displayRomaji.isEmpty })
    }

    func testExtractGrammar_detectsPoliteRequest() async {
        let model = LocalJapaneseAIModel()
        let lessonId = UUID()
        let text = "ここを読んでください。"
        let grammarItems = await model.extractGrammar(from: text, pageCode: "A 2a", category: "Kanji 1", lessonId: lessonId)

        XCTAssertFalse(grammarItems.isEmpty)
        let requestPattern = grammarItems.first(where: { $0.pattern == "〜てください" })
        XCTAssertNotNil(requestPattern)
        XCTAssertEqual(requestPattern?.pageCode, "A 2a")
        XCTAssertTrue(grammarItems.allSatisfy { item in
            item.examples.allSatisfy { !$0.displayRomaji.isEmpty && !$0.english.isEmpty }
        })
    }

    func testSuggestVocabulary_attachesPageCodeAndVerifiesTokens() async {
        let model = LocalJapaneseAIModel()
        let lessonId = UUID()
        let text = "日本語の勉強をします。"
        let items = await model.suggestVocabulary(from: text, pageCode: "A 1b", category: "General", lessonId: lessonId)

        XCTAssertFalse(items.isEmpty)
        XCTAssertEqual(items.first?.pageCode, "A 1b")
        XCTAssertFalse(items.first?.examples.isEmpty ?? true)
        XCTAssertTrue(items.allSatisfy { !$0.word.isEmpty && !$0.word.contains("は") && !$0.word.contains("を") })
        XCTAssertTrue(items.allSatisfy { !$0.displayRomaji.isEmpty })
    }

    func testVerifyVocabulary_filtersParticlesAndStrayNoise() async {
        let model = LocalJapaneseAIModel()
        let context = "学校で日本語を勉強します。"
        let candidates = [
            VocabularyItem(word: "学校", reading: "がっこう", meaning: ""),
            VocabularyItem(word: "で", reading: "で", meaning: ""),
            VocabularyItem(word: "日本語", reading: "にほんご", meaning: ""),
            VocabularyItem(word: "を", reading: "を", meaning: ""),
            VocabularyItem(word: "勉強", reading: "べんきょう", meaning: ""),
            VocabularyItem(word: "Kumon", reading: "Kumon", meaning: ""),
            VocabularyItem(word: "A11", reading: "A11", meaning: "")
        ]

        let verified = await model.verifyVocabulary(candidates: candidates, contextText: context)
        let verifiedWords = verified.map(\.word)

        XCTAssertTrue(verifiedWords.contains("学校"))
        XCTAssertTrue(verifiedWords.contains("日本語"))
        XCTAssertTrue(verifiedWords.contains("勉強"))
        XCTAssertFalse(verifiedWords.contains("で"))
        XCTAssertFalse(verifiedWords.contains("を"))
        XCTAssertFalse(verifiedWords.contains("Kumon"))
        XCTAssertFalse(verifiedWords.contains("A11"))
    }
}
