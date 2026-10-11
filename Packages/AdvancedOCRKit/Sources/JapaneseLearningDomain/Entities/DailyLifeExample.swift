import Foundation

public struct DailyLifeExample: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let japanese: String
    public let reading: String
    public let romaji: String
    public let english: String
    public let scenario: String

    public var displayRomaji: String {
        if !romaji.isEmpty { return romaji }
        let source = reading.isEmpty ? japanese : reading
        return JapaneseRomajiConverter.toRomaji(from: source)
    }

    public var displayEnglish: String {
        if !english.isEmpty && !english.contains("in daily practice") && !english.contains("Example using") {
            return english
        }
        let cleanJapanese = japanese
            .replacingOccurrences(of: "を使います。", with: "")
            .replacingOccurrences(of: "を使います", with: "")
        if let translated = JapaneseDictionaryLookup.lookup(word: cleanJapanese) {
            return "Using \"\(translated)\" in daily conversation."
        }
        return english
    }

    public init(
        id: UUID = UUID(),
        japanese: String,
        reading: String,
        romaji: String = "",
        english: String,
        scenario: String
    ) {
        self.id = id
        self.japanese = japanese
        self.reading = reading
        let cleanRomaji = romaji.trimmingCharacters(in: .whitespacesAndNewlines)
        self.romaji = cleanRomaji.isEmpty ? JapaneseRomajiConverter.toRomaji(from: reading.isEmpty ? japanese : reading) : cleanRomaji
        self.english = english
        self.scenario = scenario
    }

    enum CodingKeys: String, CodingKey {
        case id, japanese, reading, romaji, english, scenario
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        japanese = try container.decode(String.self, forKey: .japanese)
        reading = try container.decode(String.self, forKey: .reading)
        let decodedRomaji = try container.decodeIfPresent(String.self, forKey: .romaji) ?? ""
        romaji = decodedRomaji.isEmpty ? JapaneseRomajiConverter.toRomaji(from: reading.isEmpty ? japanese : reading) : decodedRomaji
        english = try container.decode(String.self, forKey: .english)
        scenario = try container.decode(String.self, forKey: .scenario)
    }
}
