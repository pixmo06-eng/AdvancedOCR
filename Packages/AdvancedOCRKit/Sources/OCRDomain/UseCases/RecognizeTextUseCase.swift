import Foundation
import Core

public protocol RecognizeTextUseCaseProtocol: Sendable {
    func execute(imageData: Data) async throws -> ScanResult
}

public final class RecognizeTextUseCase: RecognizeTextUseCaseProtocol {
    private let ocrService: OCRServiceProtocol

    public init(ocrService: OCRServiceProtocol) {
        self.ocrService = ocrService
    }

    public func execute(imageData: Data) async throws -> ScanResult {
        guard !imageData.isEmpty else {
            throw AppError.invalidImageData
        }
        return try await ocrService.recognizeText(from: imageData)
    }
}
