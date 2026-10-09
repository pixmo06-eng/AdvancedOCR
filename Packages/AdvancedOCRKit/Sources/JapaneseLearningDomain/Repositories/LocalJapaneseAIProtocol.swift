import Foundation

public protocol LocalJapaneseAIProtocol: Sendable {
    func generateSentences(for word: String, reading: String, meaning: String) async -> [DailyLifeExample]
    func extractGrammar(from text: String, pageCode: String?, category: String?, lessonId: UUID) async -> [GrammarItem]
    func suggestVocabulary(from text: String, pageCode: String?, category: String?, lessonId: UUID) async -> [VocabularyItem]
    func correctOCRText(_ rawText: String) -> String
    func verifyVocabulary(candidates: [VocabularyItem], contextText: String) async -> [VocabularyItem]
}
