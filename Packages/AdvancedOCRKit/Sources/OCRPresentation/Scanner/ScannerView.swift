import SwiftUI
import OCRDomain

public struct ScannerView: View {
    @State private var viewModel: ScannerViewModel

    public init(viewModel: ScannerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Advanced OCR")
                .toolbar { toolbarContent }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 16) {
            statusSection
            resultSection
        }
        .padding()
    }

    private var statusSection: some View {
        Group {
            if viewModel.isScanning {
                ProgressView("Analyzing image...")
            } else if let error = viewModel.errorMessage {
                errorBanner(message: error)
            }
        }
    }

    private func errorBanner(message: String) -> some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.red)
            .padding(8)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var resultSection: some View {
        Group {
            if let result = viewModel.scanResult {
                scanResultView(result: result)
            } else {
                emptyPlaceholder
            }
        }
    }

    private var emptyPlaceholder: some View {
        ContentUnavailableView(
            "No Document Scanned",
            systemImage: "doc.text.viewfinder",
            description: Text("Select an image or scan a document to recognize text.")
        )
    }

    private func scanResultView(result: ScanResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Extracted Text")
                    .font(.headline)
                Text(result.fullText)
                    .font(.body)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(Color.secondary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Clear", role: .destructive) {
                viewModel.clear()
            }
            .disabled(viewModel.scanResult == nil && viewModel.errorMessage == nil)
        }
    }
}
