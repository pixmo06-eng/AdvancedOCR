import Foundation
import CoreGraphics
import OCRDomain

public struct TextLayoutSorter: Sendable {
    public init() {}

    public func sortBlocks(_ blocks: [RecognizedBlock]) -> [RecognizedBlock] {
        guard blocks.count > 3 else {
            return sortByReadingOrder(blocks)
        }

        if isTwoColumnOrSpreadLayout(blocks) {
            return sortTwoColumns(blocks)
        }

        return sortByReadingOrder(blocks)
    }

    private func isTwoColumnOrSpreadLayout(_ blocks: [RecognizedBlock]) -> Bool {
        let leftCount = blocks.filter { $0.boundingBox.midX < 0.46 }.count
        let rightCount = blocks.filter { $0.boundingBox.midX > 0.54 }.count
        let minimumCount = max(2, blocks.count / 6)
        return leftCount >= minimumCount && rightCount >= minimumCount
    }

    private func sortTwoColumns(_ blocks: [RecognizedBlock]) -> [RecognizedBlock] {
        let topSpanning = blocks.filter { isTopHeader($0.boundingBox) }
        let remaining = blocks.filter { !isTopHeader($0.boundingBox) }

        let leftBlocks = remaining.filter { $0.boundingBox.midX <= 0.50 }
        let rightBlocks = remaining.filter { $0.boundingBox.midX > 0.50 }

        let sortedTop = sortByReadingOrder(topSpanning)
        let sortedLeft = sortByVerticalPosition(leftBlocks)
        let sortedRight = sortByVerticalPosition(rightBlocks)

        return sortedTop + sortedLeft + sortedRight
    }

    private func isTopHeader(_ rect: CGRect) -> Bool {
        let isSpanning = rect.width > 0.55
        let isAtVeryTop = rect.midY > 0.92
        return isSpanning || isAtVeryTop
    }

    private func sortByReadingOrder(_ blocks: [RecognizedBlock]) -> [RecognizedBlock] {
        blocks.sorted { first, second in
            let yDelta = abs(first.boundingBox.midY - second.boundingBox.midY)
            if yDelta < 0.02 {
                return first.boundingBox.midX < second.boundingBox.midX
            }
            return first.boundingBox.midY > second.boundingBox.midY
        }
    }

    private func sortByVerticalPosition(_ blocks: [RecognizedBlock]) -> [RecognizedBlock] {
        blocks.sorted { first, second in
            let yDelta = abs(first.boundingBox.midY - second.boundingBox.midY)
            if yDelta < 0.02 {
                return first.boundingBox.midX < second.boundingBox.midX
            }
            return first.boundingBox.midY > second.boundingBox.midY
        }
    }
}
