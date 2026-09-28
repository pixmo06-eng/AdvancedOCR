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
        var allVocab: [VocabularyItem] = []
        var allGrammar: [GrammarItem] = []

        for page in lesson.pages {
            let content = try await extractFromPage(page, lessonId: lesson.id)
            allVocab.append(contentsOf: content.vocabulary)
            allGrammar.append(contentsOf: content.grammar)
        }

        let combined = ExtractedStudyContent(vocabulary: allVocab, grammar: allGrammar)
        return try await persistAnalysis(lesson: lesson, content: combined)
    }

    private func extractFromPage(_ page: LessonPage, lessonId: UUID) async throws -> ExtractedStudyContent {
        let trimmed = page.extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ExtractedStudyContent(vocabulary: [], grammar: [])
        }
        return try await aiService.extractStudyContent(
            from: page.extractedText,
            lessonId: lessonId,
            pageId: page.id,
            pageCode: page.pageCode,
            category: page.category
        )
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
