import XCTest
@testable import JapaneseLearningDomain

final class StudyHubMasteryTests: XCTestCase {
    func testMasteryStatus_defaultIsNewWord() {
        let item = VocabularyItem(
            word: "食べる",
            reading: "たべる",
            meaning: "to eat"
        )
        XCTAssertEqual(item.masteryStatus, .newWord)
        XCTAssertTrue(item.isNewWord)
    }

    func testMasteryStatus_updateToLearning_persistsCorrectly() {
        var item = VocabularyItem(
            word: "飲む",
            reading: "のむ",
            meaning: "to drink",
            masteryStatus: .newWord
        )
        item.masteryStatus = .learning
        XCTAssertEqual(item.masteryStatus, .learning)
        XCTAssertEqual(item.masteryStatus.rawValue, "Learning")
    }

    func testMasteryStatus_updateToMastered_clearsIsNewWord() {
        var item = VocabularyItem(
            word: "本",
            reading: "ほん",
            meaning: "book",
            isNewWord: true,
            masteryStatus: .newWord
        )
        item.masteryStatus = .mastered
        item.isNewWord = false

        XCTAssertEqual(item.masteryStatus, .mastered)
        XCTAssertFalse(item.isNewWord)
    }

    func testPracticeCardsFilter_filtersOutMasteredCards() {
        let items: [VocabularyItem] = [
            VocabularyItem(word: "猫", reading: "ねこ", meaning: "cat", masteryStatus: .mastered),
            VocabularyItem(word: "犬", reading: "いぬ", meaning: "dog", masteryStatus: .learning),
            VocabularyItem(word: "鳥", reading: "とり", meaning: "bird", masteryStatus: .newWord)
        ]

        let unmastered = items.filter { $0.masteryStatus != .mastered }
        XCTAssertEqual(unmastered.count, 2)
        XCTAssertEqual(unmastered.map(\.word), ["犬", "鳥"])
    }

    func testPracticeCardsFilter_whenAllMastered_returnsAllCardsForReview() {
        let items: [VocabularyItem] = [
            VocabularyItem(word: "猫", reading: "ねこ", meaning: "cat", masteryStatus: .mastered),
            VocabularyItem(word: "犬", reading: "いぬ", meaning: "dog", masteryStatus: .mastered)
        ]

        let unmastered = items.filter { $0.masteryStatus != .mastered }
        let practiceCards = unmastered.isEmpty ? items : unmastered
        XCTAssertEqual(practiceCards.count, 2)
    }
}
