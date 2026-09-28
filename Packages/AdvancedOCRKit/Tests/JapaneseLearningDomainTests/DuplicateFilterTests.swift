import XCTest
@testable import JapaneseLearningDomain

final class DuplicateFilterTests: XCTestCase {
    func testVocabularyDeduplication_filtersCorrectly() {
        let useCase = FilterDuplicateVocabularyUseCase()
        let existing = [
            VocabularyItem(word: "食べる", reading: "たべる", meaning: "to eat", occurrenceCount: 2)
        ]

        let candidates = [
            VocabularyItem(word: "食べる", reading: "たべる", meaning: "to eat"),
            VocabularyItem(word: "本", reading: "ほん", meaning: "book")
        ]

        let result = useCase.execute(candidates: candidates, existingItems: existing)

        XCTAssertEqual(result.newItems.count, 1)
        XCTAssertEqual(result.newItems.first?.word, "本")
        XCTAssertTrue(result.newItems.first?.isNewWord ?? false)

        let taberu = result.updatedExisting.first(where: { $0.word == "食べる" })
        XCTAssertEqual(taberu?.occurrenceCount, 3)
    }

    func testGrammarDeduplication_filtersCorrectly() {
        let useCase = FilterDuplicateGrammarUseCase()
        let existing = [
            GrammarItem(pattern: "〜てもいい", meaning: "permission", formation: "Te-form + もいい", explanation: "allowed to", occurrenceCount: 1)
        ]

        let candidates = [
            GrammarItem(pattern: "〜てもいい", meaning: "permission", formation: "Te-form + もいい", explanation: "allowed to"),
            GrammarItem(pattern: "〜なければならない", meaning: "must", formation: "Nai-stem + なければならない", explanation: "obligation")
        ]

        let result = useCase.execute(candidates: candidates, existingItems: existing)

        XCTAssertEqual(result.newItems.count, 1)
        XCTAssertEqual(result.newItems.first?.pattern, "〜なければならない")
        XCTAssertTrue(result.newItems.first?.isNewGrammar ?? false)

        let temoii = result.updatedExisting.first(where: { $0.pattern == "〜てもいい" })
        XCTAssertEqual(temoii?.occurrenceCount, 2)
    }
}
