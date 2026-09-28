import SwiftUI

#if os(iOS)
import UIKit
import VisionKit

public struct DocumentCameraScannerView: UIViewControllerRepresentable {
    public typealias CompletionHandler = ([Data]) -> Void

    private let onComplete: CompletionHandler
    private let onCancel: () -> Void

    public init(onComplete: @escaping CompletionHandler, onCancel: @escaping () -> Void) {
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete, onCancel: onCancel)
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        if VNDocumentCameraViewController.isSupported {
            let controller = VNDocumentCameraViewController()
            controller.delegate = context.coordinator
            return controller
        }
        return fallbackController()
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private func fallbackController() -> UIViewController {
        let alert = UIAlertController(
            title: "Scanner Unavailable",
            message: "Document camera scanning is not supported on this device.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.onCancel()
        })
        return alert
    }

    public final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate, @unchecked Sendable {
        private let onComplete: CompletionHandler
        private let onCancel: () -> Void

        init(onComplete: @escaping CompletionHandler, onCancel: @escaping () -> Void) {
            self.onComplete = onComplete
            self.onCancel = onCancel
        }

        public func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var pagesData: [Data] = []
            for index in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: index)
                guard let data = image.jpegData(compressionQuality: 0.85) else { continue }
                pagesData.append(data)
            }
            controller.dismiss(animated: true) {
                self.onComplete(pagesData)
            }
        }

        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true) {
                self.onCancel()
            }
        }

        public func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            controller.dismiss(animated: true) {
                self.onCancel()
            }
        }
    }
}
#else
public struct DocumentCameraScannerView: View {
    public typealias CompletionHandler = ([Data]) -> Void

    private let onComplete: CompletionHandler
    private let onCancel: () -> Void

    public init(onComplete: @escaping CompletionHandler, onCancel: @escaping () -> Void) {
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("Camera scanning is only available on iOS devices.")
                .font(.headline)
            Button("Dismiss") {
                onCancel()
            }
        }
        .padding()
    }
}
#endif
