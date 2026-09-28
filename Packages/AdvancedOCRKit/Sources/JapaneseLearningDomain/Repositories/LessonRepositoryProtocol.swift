import Foundation

public protocol LessonRepositoryProtocol: Sendable {
    func fetchLessons() async throws -> [Lesson]
    func fetchLesson(by id: UUID) async throws -> Lesson?
    func saveLesson(_ lesson: Lesson) async throws
    func deleteLesson(by id: UUID) async throws

    func fetchAllVocabulary() async throws -> [VocabularyItem]
    func saveVocabularyItems(_ items: [VocabularyItem]) async throws

    func fetchAllGrammar() async throws -> [GrammarItem]
    func saveGrammarItems(_ items: [GrammarItem]) async throws
}
