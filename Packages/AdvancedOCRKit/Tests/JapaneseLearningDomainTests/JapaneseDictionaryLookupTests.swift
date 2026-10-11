import XCTest
@testable import JapaneseLearningDomain

final class JapaneseDictionaryLookupTests: XCTestCase {
    func testLookup_exactKanjiAndKana() {
        XCTAssertEqual(JapaneseDictionaryLookup.lookup(word: "にち"), "Day, Sun, Sunday")
        XCTAssertEqual(JapaneseDictionaryLookup.lookup(word: "日"), "Day, Sun, Sunday")
        XCTAssertEqual(JapaneseDictionaryLookup.lookup(word: "月"), "Moon, Month, Monday")
        XCTAssertEqual(JapaneseDictionaryLookup.lookup(word: "水"), "Water, Wednesday")
        XCTAssertEqual(JapaneseDictionaryLookup.lookup(word: "本"), "Book, Origin")
        XCTAssertEqual(JapaneseDictionaryLookup.lookup(word: "犬"), "Dog")
        XCTAssertEqual(JapaneseDictionaryLookup.lookup(word: "猫"), "Cat")
    }

    func testLookup_inflectedVerbs() {
        XCTAssertEqual(JapaneseDictionaryLookup.lookup(word: "たべます"), "To eat")
        XCTAssertEqual(JapaneseDictionaryLookup.lookup(word: "たべました"), "To eat")
        XCTAssertEqual(JapaneseDictionaryLookup.lookup(word: "のみます"), "To drink")
    }

    func testVocabularyItem_displayMeaning_replacesPlaceholderWithTranslation() {
        let legacyItem = VocabularyItem(
            word: "にち",
            reading: "にち",
            meaning: "Lesson word: にち"
        )
        XCTAssertEqual(legacyItem.displayMeaning, "Day, Sun, Sunday")
    }

    func testVocabularyItem_displayMeaning_preservesExistingValidMeaning() {
        let customItem = VocabularyItem(
            word: "にち",
            reading: "にち",
            meaning: "Solar day"
        )
        XCTAssertEqual(customItem.displayMeaning, "Solar day")
    }

    func testJapaneseRomajiConverter_convertsJapaneseFullStopToAsciiDot() {
        let sentence = "にちをつかいます。"
        let romaji = JapaneseRomajiConverter.toRomaji(from: sentence)
        XCTAssertFalse(romaji.contains("。"))
        XCTAssertTrue(romaji.hasSuffix("."))
    }
}
