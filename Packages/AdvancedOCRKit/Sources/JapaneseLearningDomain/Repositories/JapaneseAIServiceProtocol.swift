import Foundation

public struct ExtractedStudyContent: Sendable {
    public let vocabulary: [VocabularyItem]
    public let grammar: [GrammarItem]

    public init(vocabulary: [VocabularyItem], grammar: [GrammarItem]) {
        self.vocabulary = vocabulary
        self.grammar = grammar
    }
}

public protocol JapaneseAIServiceProtocol: Sendable {
    func extractStudyContent(
        from text: String,
        lessonId: UUID,
        pageId: UUID?,
        pageCode: String?,
        category: String?
    ) async throws -> ExtractedStudyContent
}
