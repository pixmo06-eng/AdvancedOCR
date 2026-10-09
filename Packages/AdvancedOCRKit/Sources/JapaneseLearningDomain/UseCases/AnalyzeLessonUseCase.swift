import Foundation

public protocol AnalyzeLessonUseCaseProtocol: Sendable {
    func execute(lesson: Lesson) async throws -> Lesson
}

public final class AnalyzeLessonUseCase: AnalyzeLessonUseCaseProtocol {
    private let aiService: JapaneseAIServiceProtocol
    private let repository: LessonRepositoryProtocol
    private let vocabFilter: FilterDuplicateVocabularyUseCaseProtocol
    private let grammarFilter: FilterDuplicateGrammarUseCaseProtocol
    private let textCleaner: JapaneseTextCleaner
    private let localAI: LocalJapaneseAIProtocol?

    public init(
        aiService: JapaneseAIServiceProtocol,
        repository: LessonRepositoryProtocol,
        vocabFilter: FilterDuplicateVocabularyUseCaseProtocol = FilterDuplicateVocabularyUseCase(),
        grammarFilter: FilterDuplicateGrammarUseCaseProtocol = FilterDuplicateGrammarUseCase(),
        textCleaner: JapaneseTextCleaner = JapaneseTextCleaner(),
        localAI: LocalJapaneseAIProtocol? = nil
    ) {
        self.aiService = aiService
        self.repository = repository
        self.vocabFilter = vocabFilter
        self.grammarFilter = grammarFilter
        self.textCleaner = textCleaner
        self.localAI = localAI
    }

    public func execute(lesson: Lesson) async throws -> Lesson {
        var updatedPages: [LessonPage] = []
        var allVocab: [VocabularyItem] = []
        var allGrammar: [GrammarItem] = []

        for page in lesson.pages {
            var currentPage = page
            let content = try await extractFromPage(currentPage, lessonId: lesson.id)
            currentPage.vocabulary = content.vocabulary
            currentPage.grammar = content.grammar
            updatedPages.append(currentPage)
            allVocab.append(contentsOf: content.vocabulary)
            allGrammar.append(contentsOf: content.grammar)
        }

        var lessonWithUpdatedPages = lesson
        lessonWithUpdatedPages.pages = updatedPages
        let combined = ExtractedStudyContent(vocabulary: allVocab, grammar: allGrammar)
        return try await persistAnalysis(lesson: lessonWithUpdatedPages, content: combined)
    }

    private func extractFromPage(_ page: LessonPage, lessonId: UUID) async throws -> ExtractedStudyContent {
        let cleaned = textCleaner.clean(text: page.extractedText)
        guard !cleaned.isEmpty else {
            return ExtractedStudyContent(vocabulary: [], grammar: [])
        }
        let content = try await aiService.extractStudyContent(
            from: cleaned,
            lessonId: lessonId,
            pageId: page.id,
            pageCode: page.pageCode,
            category: page.category
        )
        guard let localAI else { return content }
        let verifiedVocab = await localAI.verifyVocabulary(candidates: content.vocabulary, contextText: cleaned)
        return ExtractedStudyContent(vocabulary: verifiedVocab, grammar: content.grammar)
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
