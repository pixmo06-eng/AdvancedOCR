import Foundation

public protocol OCRServiceProtocol: Sendable {
    func recognizeText(from imageData: Data) async throws -> ScanResult
}
