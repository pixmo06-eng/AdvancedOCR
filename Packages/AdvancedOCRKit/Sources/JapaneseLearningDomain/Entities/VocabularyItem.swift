import Foundation

public enum MasteryStatus: String, Codable, Sendable, CaseIterable {
    case newWord = "New"
    case learning = "Learning"
    case mastered = "Mastered"
}

public struct VocabularyItem: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let word: String
    public let reading: String
    public let meaning: String
    public let partOfSpeech: String
    public let jlptLevel: String?
    public var isNewWord: Bool
    public var occurrenceCount: Int
    public var masteryStatus: MasteryStatus
    public let examples: [DailyLifeExample]
    public let firstLessonId: UUID?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        word: String,
        reading: String,
        meaning: String,
        partOfSpeech: String = "",
        jlptLevel: String? = nil,
        isNewWord: Bool = true,
        occurrenceCount: Int = 1,
        masteryStatus: MasteryStatus = .newWord,
        examples: [DailyLifeExample] = [],
        firstLessonId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.word = word
        self.reading = reading
        self.meaning = meaning
        self.partOfSpeech = partOfSpeech
        self.jlptLevel = jlptLevel
        self.isNewWord = isNewWord
        self.occurrenceCount = occurrenceCount
        self.masteryStatus = masteryStatus
        self.examples = examples
        self.firstLessonId = firstLessonId
        self.createdAt = createdAt
    }
}
