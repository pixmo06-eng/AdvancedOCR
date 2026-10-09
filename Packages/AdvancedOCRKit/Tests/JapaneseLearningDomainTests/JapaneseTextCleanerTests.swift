import XCTest
@testable import JapaneseLearningDomain

final class JapaneseTextCleanerTests: XCTestCase {
    func testClean_withSpacedKana_recombinesWords() {
        let cleaner = JapaneseTextCleaner()
        let raw = "か ん じ 1\nな ま え"
        let cleaned = cleaner.clean(text: raw)

        XCTAssertTrue(cleaned.contains("かんじ"))
        XCTAssertTrue(cleaned.contains("なまえ"))
    }

    func testClean_withSpacedHeader_recombinesHeaderCode() {
        let cleaner = JapaneseTextCleaner()
        let raw = "A 1 b KUMON"
        let cleaned = cleaner.clean(text: raw)

        XCTAssertTrue(cleaned.contains("A 1b"))
    }

    func testClean_withStrayPunctuation_cleansLineArtifacts() {
        let cleaner = JapaneseTextCleaner()
        let raw = "--- • 本を読む • ---"
        let cleaned = cleaner.clean(text: raw)

        XCTAssertEqual(cleaned, "本を読む")
    }
}
