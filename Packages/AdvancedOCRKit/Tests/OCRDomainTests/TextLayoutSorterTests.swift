import XCTest
import CoreGraphics
@testable import OCRDomain
@testable import OCRData

final class TextLayoutSorterTests: XCTestCase {
    private let sorter = TextLayoutSorter()

    func testSortBlocks_withTwoColumnLayout_sortsLeftColumnFirstThenRightColumn() {
        let left1 = RecognizedBlock(text: "Left 1", confidence: 1.0, boundingBox: CGRect(x: 0.1, y: 0.8, width: 0.3, height: 0.05))
        let right1 = RecognizedBlock(text: "Right 1", confidence: 1.0, boundingBox: CGRect(x: 0.6, y: 0.8, width: 0.3, height: 0.05))
        let left2 = RecognizedBlock(text: "Left 2", confidence: 1.0, boundingBox: CGRect(x: 0.1, y: 0.6, width: 0.3, height: 0.05))
        let right2 = RecognizedBlock(text: "Right 2", confidence: 1.0, boundingBox: CGRect(x: 0.6, y: 0.6, width: 0.3, height: 0.05))

        let unsorted = [left1, right1, left2, right2]
        let sorted = sorter.sortBlocks(unsorted)

        XCTAssertEqual(sorted.map(\.text), ["Left 1", "Left 2", "Right 1", "Right 2"])
    }

    func testSortBlocks_withTopHeader_placesHeaderFirstBeforeColumns() {
        let header = RecognizedBlock(text: "Lesson Title", confidence: 1.0, boundingBox: CGRect(x: 0.1, y: 0.95, width: 0.8, height: 0.04))
        let left1 = RecognizedBlock(text: "Left 1", confidence: 1.0, boundingBox: CGRect(x: 0.1, y: 0.7, width: 0.3, height: 0.05))
        let right1 = RecognizedBlock(text: "Right 1", confidence: 1.0, boundingBox: CGRect(x: 0.6, y: 0.7, width: 0.3, height: 0.05))
        let left2 = RecognizedBlock(text: "Left 2", confidence: 1.0, boundingBox: CGRect(x: 0.1, y: 0.5, width: 0.3, height: 0.05))
        let right2 = RecognizedBlock(text: "Right 2", confidence: 1.0, boundingBox: CGRect(x: 0.6, y: 0.5, width: 0.3, height: 0.05))

        let sorted = sorter.sortBlocks([left2, right1, header, right2, left1])

        XCTAssertEqual(sorted.map(\.text), ["Lesson Title", "Left 1", "Left 2", "Right 1", "Right 2"])
    }

    func testSortBlocks_withSingleColumn_sortsTopToBottom() {
        let block1 = RecognizedBlock(text: "Top", confidence: 1.0, boundingBox: CGRect(x: 0.1, y: 0.8, width: 0.7, height: 0.05))
        let block2 = RecognizedBlock(text: "Middle", confidence: 1.0, boundingBox: CGRect(x: 0.1, y: 0.5, width: 0.7, height: 0.05))
        let block3 = RecognizedBlock(text: "Bottom", confidence: 1.0, boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.7, height: 0.05))

        let sorted = sorter.sortBlocks([block2, block3, block1])

        XCTAssertEqual(sorted.map(\.text), ["Top", "Middle", "Bottom"])
    }
}
