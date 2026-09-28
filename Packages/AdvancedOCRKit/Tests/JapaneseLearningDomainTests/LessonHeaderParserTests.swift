import XCTest
@testable import JapaneseLearningDomain

final class LessonHeaderParserTests: XCTestCase {
    func testParse_withKumonHeader_extractsPageCodeAndCategory() {
        let parser = LessonHeaderParser()
        let ocrText = """
        A 2a KUMON
        かんじ 1
        Kanji 1
        1 Trace the kanji and the hiragana.
        """

        let result = parser.parse(text: ocrText, fallbackIndex: 0, currentCategory: nil)

        XCTAssertEqual(result.pageCode, "A 2a")
        XCTAssertEqual(result.category, "Kanji 1")
        XCTAssertEqual(result.title, "A 2a - Kanji 1")
    }

    func testParse_withKumonA1b_extractsPageCodeAndInheritsCategory() {
        let parser = LessonHeaderParser()
        let ocrText = """
        A 1b
        2 Read aloud the kanji.
        """

        let result = parser.parse(text: ocrText, fallbackIndex: 0, currentCategory: "Kanji 1")

        XCTAssertEqual(result.pageCode, "A 1b")
        XCTAssertEqual(result.category, "Kanji 1")
    }

    func testParse_withKumonA11a_switchesToKanji2() {
        let parser = LessonHeaderParser()
        let ocrText = """
        A 11a KUMON
        かんじ 2
        Kanji 2
        1 Read aloud the numbers in Japanese.
        """

        let result = parser.parse(text: ocrText, fallbackIndex: 10, currentCategory: "Kanji 1")

        XCTAssertEqual(result.pageCode, "A 11a")
        XCTAssertEqual(result.category, "Kanji 2")
        XCTAssertEqual(result.title, "A 11a - Kanji 2")
    }
}
