import Foundation

public struct ScanResult: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let fullText: String
    public let blocks: [RecognizedBlock]
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        fullText: String,
        blocks: [RecognizedBlock],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.fullText = fullText
        self.blocks = blocks
        self.createdAt = createdAt
    }
}
