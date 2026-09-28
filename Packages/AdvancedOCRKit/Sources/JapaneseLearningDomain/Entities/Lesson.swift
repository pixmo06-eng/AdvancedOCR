import Foundation

public struct Lesson: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var title: String
    public var pages: [LessonPage]
    public var vocabularyIds: [UUID]
    public var grammarIds: [UUID]
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        pages: [LessonPage] = [],
        vocabularyIds: [UUID] = [],
        grammarIds: [UUID] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.pages = pages
        self.vocabularyIds = vocabularyIds
        self.grammarIds = grammarIds
        self.createdAt = createdAt
    }

    public var combinedText: String {
        pages.map(\.extractedText).joined(separator: "\n\n")
    }
}
