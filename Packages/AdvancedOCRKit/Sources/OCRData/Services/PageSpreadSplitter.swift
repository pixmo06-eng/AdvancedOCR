import Foundation
import CoreGraphics
import CoreImage
import ImageIO
import OCRDomain

public final class PageSpreadSplitter: PageSpreadSplitterProtocol, @unchecked Sendable {
    private let ciContext = CIContext(options: nil)

    public init() {}

    public func isTwoPageSpread(imageData: Data) -> Bool {
        guard let dimensions = extractVisualDimensions(from: imageData) else {
            return false
        }
        guard dimensions.height > 0 else { return false }
        let aspectRatio = dimensions.width / dimensions.height
        return aspectRatio >= 1.05
    }

    public func splitSpread(imageData: Data) -> [Data] {
        guard isTwoPageSpread(imageData: imageData),
              let cgImage = renderUprightCGImage(from: imageData) else {
            return [imageData]
        }

        let leftRect = calculateLeftCropRect(width: cgImage.width, height: cgImage.height)
        let rightRect = calculateRightCropRect(width: cgImage.width, height: cgImage.height)

        guard let leftCG = cgImage.cropping(to: leftRect),
              let rightCG = cgImage.cropping(to: rightRect),
              let leftData = encodeToJPEG(cgImage: leftCG),
              let rightData = encodeToJPEG(cgImage: rightCG) else {
            return [imageData]
        }

        return [leftData, rightData]
    }

    private func extractVisualDimensions(from data: Data) -> (width: Double, height: Double)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return nil
        }
        let rawWidth = properties[kCGImagePropertyPixelWidth] as? Double ?? 0
        let rawHeight = properties[kCGImagePropertyPixelHeight] as? Double ?? 0
        let orientation = properties[kCGImagePropertyOrientation] as? UInt32 ?? 1

        let isRotated = orientation >= 5 && orientation <= 8
        let visualWidth = isRotated ? rawHeight : rawWidth
        let visualHeight = isRotated ? rawWidth : rawHeight
        return (visualWidth, visualHeight)
    }

    private func renderUprightCGImage(from data: Data) -> CGImage? {
        guard let ciImage = CIImage(data: data, options: [.applyOrientationProperty: true]) else {
            return nil
        }
        return ciContext.createCGImage(ciImage, from: ciImage.extent)
    }

    private func calculateLeftCropRect(width: Int, height: Int) -> CGRect {
        let halfWidth = Double(width) * 0.5
        let cropWidth = min(Double(width), halfWidth * 1.03)
        return CGRect(x: 0, y: 0, width: cropWidth, height: Double(height))
    }

    private func calculateRightCropRect(width: Int, height: Int) -> CGRect {
        let halfWidth = Double(width) * 0.5
        let startX = max(0.0, halfWidth * 0.97)
        let cropWidth = Double(width) - startX
        return CGRect(x: startX, y: 0, width: cropWidth, height: Double(height))
    }

    private func encodeToJPEG(cgImage: CGImage, quality: Double = 0.88) -> Data? {
        let mutableData = CFDataCreateMutable(nil, 0)!
        guard let destination = CGImageDestinationCreateWithData(mutableData, "public.jpeg" as CFString, 1, nil) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}
