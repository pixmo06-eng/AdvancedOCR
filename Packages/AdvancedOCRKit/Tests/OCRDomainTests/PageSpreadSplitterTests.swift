import XCTest
import CoreGraphics
import ImageIO
@testable import OCRDomain
@testable import OCRData

final class PageSpreadSplitterTests: XCTestCase {
    private let splitter = PageSpreadSplitter()

    func testIsTwoPageSpread_withLandscapeImage_returnsTrue() {
        let data = makeTestJPEG(width: 800, height: 400)
        XCTAssertTrue(splitter.isTwoPageSpread(imageData: data))
    }

    func testIsTwoPageSpread_withPortraitImage_returnsFalse() {
        let data = makeTestJPEG(width: 400, height: 600)
        XCTAssertFalse(splitter.isTwoPageSpread(imageData: data))
    }

    func testSplitSpread_withLandscapeImage_returnsTwoHalves() {
        let data = makeTestJPEG(width: 800, height: 400)
        let halves = splitter.splitSpread(imageData: data)
        XCTAssertEqual(halves.count, 2)
        XCTAssertGreaterThan(halves[0].count, 0)
        XCTAssertGreaterThan(halves[1].count, 0)
    }

    func testSplitSpread_withPortraitImage_returnsOriginalSingleImage() {
        let data = makeTestJPEG(width: 400, height: 600)
        let result = splitter.splitSpread(imageData: data)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0], data)
    }

    private func makeTestJPEG(width: Int, height: Int) -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let cgImage = context.makeImage()!

        let mutableData = CFDataCreateMutable(nil, 0)!
        let dest = CGImageDestinationCreateWithData(mutableData, "public.jpeg" as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, cgImage, nil)
        CGImageDestinationFinalize(dest)
        return mutableData as Data
    }
}
