import Foundation

public struct LessonPage: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let pageIndex: Int
    public let imageData: Data
    public var extractedText: String
    public var pageCode: String
    public var category: String
    public var title: String
    public var vocabulary: [VocabularyItem]
    public var grammar: [GrammarItem]

    public init(
        id: UUID = UUID(),
        pageIndex: Int,
        imageData: Data,
        extractedText: String = "",
        pageCode: String = "",
        category: String = "General",
        title: String = "",
        vocabulary: [VocabularyItem] = [],
        grammar: [GrammarItem] = []
    ) {
        self.id = id
        self.pageIndex = pageIndex
        self.imageData = imageData
        self.extractedText = extractedText
        self.pageCode = pageCode.isEmpty ? "Page \(pageIndex + 1)" : pageCode
        self.category = category
        self.title = title.isEmpty ? self.pageCode : title
        self.vocabulary = vocabulary
        self.grammar = grammar
    }
}
