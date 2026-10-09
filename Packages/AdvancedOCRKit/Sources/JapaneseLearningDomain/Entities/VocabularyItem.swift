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
    public var romaji: String
    public let meaning: String
    public let partOfSpeech: String
    public let jlptLevel: String?
    public var isNewWord: Bool
    public var occurrenceCount: Int
    public var masteryStatus: MasteryStatus
    public let examples: [DailyLifeExample]
    public let firstLessonId: UUID?
    public var pageId: UUID?
    public var pageCode: String?
    public var category: String?
    public let createdAt: Date

    public var displayRomaji: String {
        if !romaji.isEmpty { return romaji }
        let source = reading.isEmpty ? word : reading
        return JapaneseRomajiConverter.toRomaji(from: source)
    }

    public init(
        id: UUID = UUID(),
        word: String,
        reading: String,
        romaji: String = "",
        meaning: String,
        partOfSpeech: String = "",
        jlptLevel: String? = nil,
        isNewWord: Bool = true,
        occurrenceCount: Int = 1,
        masteryStatus: MasteryStatus = .newWord,
        examples: [DailyLifeExample] = [],
        firstLessonId: UUID? = nil,
        pageId: UUID? = nil,
        pageCode: String? = nil,
        category: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.word = word
        self.reading = reading
        let cleanRomaji = romaji.trimmingCharacters(in: .whitespacesAndNewlines)
        self.romaji = cleanRomaji.isEmpty ? JapaneseRomajiConverter.toRomaji(from: reading.isEmpty ? word : reading) : cleanRomaji
        self.meaning = meaning
        self.partOfSpeech = partOfSpeech
        self.jlptLevel = jlptLevel
        self.isNewWord = isNewWord
        self.occurrenceCount = occurrenceCount
        self.masteryStatus = masteryStatus
        self.examples = examples
        self.firstLessonId = firstLessonId
        self.pageId = pageId
        self.pageCode = pageCode
        self.category = category
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, word, reading, romaji, meaning, partOfSpeech, jlptLevel, isNewWord
        case occurrenceCount, masteryStatus, examples, firstLessonId, pageId, pageCode, category, createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        word = try container.decode(String.self, forKey: .word)
        reading = try container.decode(String.self, forKey: .reading)
        let decodedRomaji = try container.decodeIfPresent(String.self, forKey: .romaji) ?? ""
        romaji = decodedRomaji.isEmpty ? JapaneseRomajiConverter.toRomaji(from: reading.isEmpty ? word : reading) : decodedRomaji
        meaning = try container.decode(String.self, forKey: .meaning)
        partOfSpeech = try container.decodeIfPresent(String.self, forKey: .partOfSpeech) ?? ""
        jlptLevel = try container.decodeIfPresent(String.self, forKey: .jlptLevel)
        isNewWord = try container.decode(Bool.self, forKey: .isNewWord)
        occurrenceCount = try container.decode(Int.self, forKey: .occurrenceCount)
        masteryStatus = try container.decode(MasteryStatus.self, forKey: .masteryStatus)
        examples = try container.decode([DailyLifeExample].self, forKey: .examples)
        firstLessonId = try container.decodeIfPresent(UUID.self, forKey: .firstLessonId)
        pageId = try container.decodeIfPresent(UUID.self, forKey: .pageId)
        pageCode = try container.decodeIfPresent(String.self, forKey: .pageCode)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
