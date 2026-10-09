import Foundation
import Observation
import Core
import OCRDomain
import JapaneseLearningDomain

@Observable
@MainActor
public final class LessonListViewModel {
    public var lessons: [Lesson] = []
    public var vocabularyList: [VocabularyItem] = []
    public var grammarList: [GrammarItem] = []
    public var isProcessing: Bool = false
    public var statusMessage: String?
    public var errorMessage: String?

    private let repository: LessonRepositoryProtocol
    private let ocrService: OCRServiceProtocol
    private let analyzeLessonUseCase: AnalyzeLessonUseCaseProtocol

    public init(
        repository: LessonRepositoryProtocol,
        ocrService: OCRServiceProtocol,
        analyzeLessonUseCase: AnalyzeLessonUseCaseProtocol
    ) {
        self.repository = repository
        self.ocrService = ocrService
        self.analyzeLessonUseCase = analyzeLessonUseCase
    }

    public func loadData() async {
        do {
            lessons = try await repository.fetchLessons()
            vocabularyList = try await repository.fetchAllVocabulary()
            grammarList = try await repository.fetchAllGrammar()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func processScannedPages(title: String, pagesData: [Data]) async {
        guard !pagesData.isEmpty else { return }
        isProcessing = true
        statusMessage = "Extracting Japanese text from pages..."
        errorMessage = nil

        do {
            let pages = try await performOCROnPages(pagesData: pagesData)
            statusMessage = "Analyzing vocabulary & grammar with AI..."
            let finalTitle = resolveLessonTitle(givenTitle: title, pages: pages)
            let initialLesson = Lesson(title: finalTitle, pages: pages)
            let analyzedLesson = try await analyzeLessonUseCase.execute(lesson: initialLesson)
            lessons.insert(analyzedLesson, at: 0)
            vocabularyList = try await repository.fetchAllVocabulary()
            grammarList = try await repository.fetchAllGrammar()
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
        statusMessage = nil
    }

    public func deleteLesson(id: UUID) async {
        do {
            try await repository.deleteLesson(by: id)
            lessons.removeAll(where: { $0.id == id })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Appends newly scanned pages to an existing lesson and returns the updated lesson.
    public func appendPages(to lessonId: UUID, pagesData: [Data]) async -> Lesson? {
        guard !pagesData.isEmpty,
              let existing = lessons.first(where: { $0.id == lessonId }) else { return nil }
        isProcessing = true
        statusMessage = "Extracting Japanese text from new pages..."
        errorMessage = nil
        defer {
            isProcessing = false
            statusMessage = nil
        }

        do {
            let merged = try await analyzeAndMerge(existing: existing, pagesData: pagesData)
            try await repository.saveLesson(merged)
            if let index = lessons.firstIndex(where: { $0.id == lessonId }) {
                lessons[index] = merged
            }
            vocabularyList = try await repository.fetchAllVocabulary()
            grammarList = try await repository.fetchAllGrammar()
            return merged
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func analyzeAndMerge(existing: Lesson, pagesData: [Data]) async throws -> Lesson {
        let newPages = try await performOCROnPages(
            pagesData: pagesData,
            startIndex: existing.pages.count,
            initialCategory: existing.pages.last?.category
        )
        statusMessage = "Analyzing vocabulary & grammar with AI..."
        let partial = Lesson(id: existing.id, title: existing.title, pages: newPages)
        let analyzed = try await analyzeLessonUseCase.execute(lesson: partial)
        var merged = existing
        merged.pages.append(contentsOf: analyzed.pages)
        merged.vocabularyIds.append(contentsOf: analyzed.vocabularyIds)
        merged.grammarIds.append(contentsOf: analyzed.grammarIds)
        return merged
    }

    private func performOCROnPages(
        pagesData: [Data],
        startIndex: Int = 0,
        initialCategory: String? = nil
    ) async throws -> [LessonPage] {
        var pages: [LessonPage] = []
        var activeCategory: String? = initialCategory
        let parser = LessonHeaderParser()

        for (offset, data) in pagesData.enumerated() {
            let index = startIndex + offset
            let scanResult = try await ocrService.recognizeText(from: data)
            let header = parser.parse(text: scanResult.fullText, fallbackIndex: index, currentCategory: activeCategory)
            if let detected = header.category {
                activeCategory = detected
            }
            let page = LessonPage(
                pageIndex: index,
                imageData: data,
                extractedText: scanResult.fullText,
                pageCode: header.pageCode,
                category: header.category ?? "General",
                title: header.title
            )
            pages.append(page)
        }
        return pages
    }

    private func resolveLessonTitle(givenTitle: String, pages: [LessonPage]) -> String {
        let trimmed = givenTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        if let firstCategory = pages.compactMap({ $0.category }).first(where: { $0 != "General" }) {
            return firstCategory
        }
        return "Lesson \(lessons.count + 1)"
    }
}
