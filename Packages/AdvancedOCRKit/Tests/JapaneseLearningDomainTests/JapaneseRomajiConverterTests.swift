import XCTest
@testable import JapaneseLearningDomain

final class JapaneseRomajiConverterTests: XCTestCase {
    func testToRomaji_withHiragana_convertsAccurately() {
        let result = JapaneseRomajiConverter.toRomaji(from: "たべる")
        XCTAssertTrue(result.lowercased().contains("taberu"))
    }

    func testToRomaji_withKatakana_convertsAccurately() {
        let result = JapaneseRomajiConverter.toRomaji(from: "ラーメン")
        XCTAssertTrue(result.lowercased().contains("ra"))
    }

    func testToRomaji_withSentence_convertsAccurately() {
        let result = JapaneseRomajiConverter.toRomaji(from: "にほんごをべんきょうします")
        XCTAssertTrue(result.lowercased().contains("nihongo"))
    }
}
