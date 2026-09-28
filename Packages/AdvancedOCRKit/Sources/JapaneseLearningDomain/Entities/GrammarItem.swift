import Foundation

public struct GrammarItem: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let pattern: String
    public let meaning: String
    public let formation: String
    public let explanation: String
    public let jlptLevel: String?
    public var isNewGrammar: Bool
    public var occurrenceCount: Int
    public let examples: [DailyLifeExample]
    public let lessonId: UUID?
    public var pageId: UUID?
    public var pageCode: String?
    public var category: String?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        pattern: String,
        meaning: String,
        formation: String,
        explanation: String,
        jlptLevel: String? = nil,
        isNewGrammar: Bool = true,
        occurrenceCount: Int = 1,
        examples: [DailyLifeExample] = [],
        lessonId: UUID? = nil,
        pageId: UUID? = nil,
        pageCode: String? = nil,
        category: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.pattern = pattern
        self.meaning = meaning
        self.formation = formation
        self.explanation = explanation
        self.jlptLevel = jlptLevel
        self.isNewGrammar = isNewGrammar
        self.occurrenceCount = occurrenceCount
        self.examples = examples
        self.lessonId = lessonId
        self.pageId = pageId
        self.pageCode = pageCode
        self.category = category
        self.createdAt = createdAt
    }
}
