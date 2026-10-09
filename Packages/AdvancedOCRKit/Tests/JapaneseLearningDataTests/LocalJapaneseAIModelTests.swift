import XCTest
@testable import JapaneseLearningDomain
@testable import JapaneseLearningData

final class LocalJapaneseAIModelTests: XCTestCase {
    func testGenerateSentences_returnsContextualExamples() async {
        let model = LocalJapaneseAIModel()
        let examples = await model.generateSentences(for: "食べる", reading: "たべる", meaning: "to eat")

        XCTAssertEqual(examples.count, 3)
        XCTAssertTrue(examples.contains(where: { $0.scenario == "Daily Routine" }))
        XCTAssertTrue(examples.contains(where: { $0.japanese.contains("食べる") }))
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
    }

    func testSuggestVocabulary_attachesPageCodeAndExamples() async {
        let model = LocalJapaneseAIModel()
        let lessonId = UUID()
        let text = "日本語の勉強をします。"
        let items = await model.suggestVocabulary(from: text, pageCode: "A 1b", category: "General", lessonId: lessonId)

        XCTAssertFalse(items.isEmpty)
        XCTAssertEqual(items.first?.pageCode, "A 1b")
        XCTAssertFalse(items.first?.examples.isEmpty ?? true)
    }
}
