import Foundation

public struct DailyLifeExample: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let japanese: String
    public let reading: String
    public let english: String
    public let scenario: String

    public init(
        id: UUID = UUID(),
        japanese: String,
        reading: String,
        english: String,
        scenario: String
    ) {
        self.id = id
        self.japanese = japanese
        self.reading = reading
        self.english = english
        self.scenario = scenario
    }
}
