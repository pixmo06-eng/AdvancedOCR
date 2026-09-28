import SwiftUI
import Core
import OCRDomain
import OCRData
import OCRPresentation

@main
struct AdvancedOCRApp: App {
    @State private var scannerViewModel: ScannerViewModel

    init() {
        let ocrService = VisionOCRService()
        let recognizeUseCase = RecognizeTextUseCase(ocrService: ocrService)
        let viewModel = ScannerViewModel(recognizeTextUseCase: recognizeUseCase)
        _scannerViewModel = State(initialValue: viewModel)
    }

    var body: some Scene {
        WindowGroup {
            ScannerView(viewModel: scannerViewModel)
        }
    }
}
