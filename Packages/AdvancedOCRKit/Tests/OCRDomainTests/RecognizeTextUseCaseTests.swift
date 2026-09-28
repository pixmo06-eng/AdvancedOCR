import XCTest
@testable import Core
@testable import OCRDomain

final class MockOCRService: OCRServiceProtocol, @unchecked Sendable {
    var resultToReturn: ScanResult?
    var errorToThrow: Error?

    func recognizeText(from imageData: Data) async throws -> ScanResult {
        if let error = errorToThrow {
            throw error
        }
        return resultToReturn ?? ScanResult(fullText: "Mock", blocks: [])
    }
}

final class RecognizeTextUseCaseTests: XCTestCase {
    func testExecute_withEmptyData_throwsInvalidImageData() async {
        let mockService = MockOCRService()
        let useCase = RecognizeTextUseCase(ocrService: mockService)

        do {
            _ = try await useCase.execute(imageData: Data())
            XCTFail("Expected invalidImageData error")
        } catch let error as AppError {
            XCTAssertEqual(error, AppError.invalidImageData)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testExecute_withValidData_returnsScanResult() async throws {
        let mockService = MockOCRService()
        let expected = ScanResult(fullText: "Hello World", blocks: [])
        mockService.resultToReturn = expected
        let useCase = RecognizeTextUseCase(ocrService: mockService)

        let result = try await useCase.execute(imageData: Data([0x01, 0x02]))
        XCTAssertEqual(result.fullText, "Hello World")
    }
}
