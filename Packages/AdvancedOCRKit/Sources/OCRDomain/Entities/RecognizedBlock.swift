import Foundation
import CoreGraphics

public struct RecognizedBlock: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let text: String
    public let confidence: Float
    public let boundingBox: CGRect

    public init(
        id: UUID = UUID(),
        text: String,
        confidence: Float,
        boundingBox: CGRect
    ) {
        self.id = id
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}
