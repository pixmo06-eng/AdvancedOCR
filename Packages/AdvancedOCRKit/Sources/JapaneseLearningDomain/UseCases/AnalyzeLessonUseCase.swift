import Foundation

public protocol AnalyzeLessonUseCaseProtocol: Sendable {
    func execute(lesson: Lesson) async throws -> Lesson
}

public final class AnalyzeLessonUseCase: AnalyzeLessonUseCaseProtocol {
    private let aiService: JapaneseAIServiceProtocol
    private let repository: LessonRepositoryProtocol
    private let vocabFilter: FilterDuplicateVocabularyUseCaseProtocol
    private let grammarFilter: FilterDuplicateGrammarUseCaseProtocol

    public init(
        aiService: JapaneseAIServiceProtocol,
        repository: LessonRepositoryProtocol,
        vocabFilter: FilterDuplicateVocabularyUseCaseProtocol = FilterDuplicateVocabularyUseCase(),
        grammarFilter: FilterDuplicateGrammarUseCaseProtocol = FilterDuplicateGrammarUseCase()
    ) {
        self.aiService = aiService
        self.repository = repository
        self.vocabFilter = vocabFilter
        self.grammarFilter = grammarFilter
    }

    public func execute(lesson: Lesson) async throws -> Lesson {
        let text = lesson.combinedText
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return lesson
        }

        let studyContent = try await aiService.extractStudyContent(from: text, lessonId: lesson.id)
        return try await persistAnalysis(lesson: lesson, content: studyContent)
    }

    private func persistAnalysis(
        lesson: Lesson,
        content: ExtractedStudyContent
    ) async throws -> Lesson {
        let existingVocab = try await repository.fetchAllVocabulary()
        let existingGrammar = try await repository.fetchAllGrammar()

        let vocabResult = vocabFilter.execute(candidates: content.vocabulary, existingItems: existingVocab)
        let grammarResult = grammarFilter.execute(candidates: content.grammar, existingItems: existingGrammar)

        try await repository.saveVocabularyItems(vocabResult.updatedExisting)
        try await repository.saveGrammarItems(grammarResult.updatedExisting)

        var modifiedLesson = lesson
        modifiedLesson.vocabularyIds = vocabResult.newItems.map(\.id)
        modifiedLesson.grammarIds = grammarResult.newItems.map(\.id)
        try await repository.saveLesson(modifiedLesson)

        return modifiedLesson
    }
}
