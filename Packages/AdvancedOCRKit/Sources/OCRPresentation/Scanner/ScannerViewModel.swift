import Foundation
import Observation
import Core
import OCRDomain

@Observable
@MainActor
public final class ScannerViewModel {
    public var isScanning: Bool = false
    public var scanResult: ScanResult?
    public var errorMessage: String?

    private let recognizeTextUseCase: RecognizeTextUseCaseProtocol

    public init(recognizeTextUseCase: RecognizeTextUseCaseProtocol) {
        self.recognizeTextUseCase = recognizeTextUseCase
    }

    public func scanImage(data: Data) async {
        guard !isScanning else { return }
        isScanning = true
        errorMessage = nil

        do {
            scanResult = try await recognizeTextUseCase.execute(imageData: data)
        } catch {
            errorMessage = error.localizedDescription
        }

        isScanning = false
    }

    public func clear() {
        scanResult = nil
        errorMessage = nil
    }
}
