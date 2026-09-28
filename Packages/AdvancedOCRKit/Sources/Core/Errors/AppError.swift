import Foundation

public enum AppError: LocalizedError, Sendable, Equatable {
    case invalidImageData
    case ocrRecognitionFailed(String)
    case cameraUnavailable
    case unauthorizedAccess

    public var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "The provided image data is invalid."
        case .ocrRecognitionFailed(let reason):
            return "Text recognition failed: \(reason)"
        case .cameraUnavailable:
            return "The camera is currently unavailable."
        case .unauthorizedAccess:
            return "Permission to access the camera or photo library was denied."
        }
    }
}
