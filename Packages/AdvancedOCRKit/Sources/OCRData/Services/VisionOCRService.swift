import Foundation
import ImageIO
import Vision
import Core
import OCRDomain

public final class VisionOCRService: OCRServiceProtocol {
    public init() {}

    public func recognizeText(from imageData: Data) async throws -> ScanResult {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw AppError.invalidImageData
        }
        let orientation = extractOrientation(from: imageSource)
        return try await performRecognition(on: cgImage, orientation: orientation)
    }

    private func extractOrientation(from source: CGImageSource) -> CGImagePropertyOrientation {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let rawValue = properties[kCGImagePropertyOrientation] as? UInt32,
              let orientation = CGImagePropertyOrientation(rawValue: rawValue) else {
            return .up
        }
        return orientation
    }

    private func performRecognition(
        on cgImage: CGImage,
        orientation: CGImagePropertyOrientation
    ) async throws -> ScanResult {
        try await withCheckedThrowingContinuation { continuation in
            self.startRecognition(on: cgImage, orientation: orientation, continuation: continuation)
        }
    }

    private func startRecognition(
        on cgImage: CGImage,
        orientation: CGImagePropertyOrientation,
        continuation: CheckedContinuation<ScanResult, Error>
    ) {
        let request = makeTextRequest(continuation: continuation)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        do {
            try handler.perform([request])
        } catch {
            continuation.resume(throwing: AppError.ocrRecognitionFailed(error.localizedDescription))
        }
    }

    private func makeTextRequest(
        continuation: CheckedContinuation<ScanResult, Error>
    ) -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest { [weak self] req, err in
            guard let self else { return }
            let result = self.handleRecognitionResult(request: req, error: err)
            continuation.resume(with: result)
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["ja-JP", "ja", "en-US"]
        request.revision = VNRecognizeTextRequestRevision3
        return request
    }

    private func handleRecognitionResult(
        request: VNRequest,
        error: Error?
    ) -> Result<ScanResult, Error> {
        if let error {
            return .failure(AppError.ocrRecognitionFailed(error.localizedDescription))
        }
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return .success(ScanResult(fullText: "", blocks: []))
        }
        let rawBlocks = observations.compactMap(self.mapObservation)
        let sortedBlocks = TextLayoutSorter().sortBlocks(rawBlocks)
        let fullText = sortedBlocks.map(\.text).joined(separator: "\n")
        return .success(ScanResult(fullText: fullText, blocks: sortedBlocks))
    }

    private func mapObservation(_ observation: VNRecognizedTextObservation) -> RecognizedBlock? {
        guard let topCandidate = observation.topCandidates(1).first else {
            return nil
        }
        return RecognizedBlock(
            text: topCandidate.string,
            confidence: topCandidate.confidence,
            boundingBox: observation.boundingBox
        )
    }
}
