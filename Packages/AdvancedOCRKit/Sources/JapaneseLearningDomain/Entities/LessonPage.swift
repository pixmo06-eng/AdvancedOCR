import Foundation

public struct LessonPage: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let pageIndex: Int
    public let imageData: Data
    public var extractedText: String

    public init(
        id: UUID = UUID(),
        pageIndex: Int,
        imageData: Data,
        extractedText: String = ""
    ) {
        self.id = id
        self.pageIndex = pageIndex
        self.imageData = imageData
        self.extractedText = extractedText
    }
}
