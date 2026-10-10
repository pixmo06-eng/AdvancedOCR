import Foundation

public protocol PageSpreadSplitterProtocol: Sendable {
    /// Determines whether the given image data represents a two-page spread.
    func isTwoPageSpread(imageData: Data) -> Bool

    /// Splits a two-page spread image into two individual page images (left and right).
    /// If the image is not a spread, returns an array containing the original image.
    func splitSpread(imageData: Data) -> [Data]
}
