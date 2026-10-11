import Foundation
import Observation
import Core
import OCRDomain
import OCRData
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
    private let spreadSplitter: PageSpreadSplitterProtocol

    public init(
        repository: LessonRepositoryProtocol,
        ocrService: OCRServiceProtocol,
        analyzeLessonUseCase: AnalyzeLessonUseCaseProtocol,
        spreadSplitter: PageSpreadSplitterProtocol = PageSpreadSplitter()
    ) {
        self.repository = repository
        self.ocrService = ocrService
        self.analyzeLessonUseCase = analyzeLessonUseCase
        self.spreadSplitter = spreadSplitter
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

    public func updatePage(lessonId: UUID, page: LessonPage) async {
        guard let index = lessons.firstIndex(where: { $0.id == lessonId }),
              let pageIndex = lessons[index].pages.firstIndex(where: { $0.id == page.id }) else { return }

        lessons[index].pages[pageIndex] = page
        do {
            try await repository.saveLesson(lessons[index])
            try await repository.saveVocabularyItems(page.vocabulary)
            try await repository.saveGrammarItems(page.grammar)
            vocabularyList = try await repository.fetchAllVocabulary()
            grammarList = try await repository.fetchAllGrammar()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func updateVocabularyMastery(item: VocabularyItem, status: MasteryStatus) async {
        guard let index = vocabularyList.firstIndex(where: { $0.id == item.id || $0.word == item.word }) else {
            return
        }
        vocabularyList[index].masteryStatus = status
        if status == .mastered {
            vocabularyList[index].isNewWord = false
        }
        do {
            try await repository.saveVocabularyItems([vocabularyList[index]])
            try await syncMasteryToLessons(item: item, status: status)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func syncMasteryToLessons(item: VocabularyItem, status: MasteryStatus) async throws {
        for (idx, _) in lessons.enumerated() {
            guard let updatedPages = updatePagesWithMastery(lessons[idx].pages, item: item, status: status) else {
                continue
            }
            lessons[idx].pages = updatedPages
            try await repository.saveLesson(lessons[idx])
        }
    }

    private func updatePagesWithMastery(
        _ pages: [LessonPage],
        item: VocabularyItem,
        status: MasteryStatus
    ) -> [LessonPage]? {
        var updated = pages
        var changed = false
        for (pIdx, page) in pages.enumerated() {
            guard let vIdx = page.vocabulary.firstIndex(where: { $0.id == item.id || $0.word == item.word }) else {
                continue
            }
            updated[pIdx].vocabulary[vIdx].masteryStatus = status
            if status == .mastered {
                updated[pIdx].vocabulary[vIdx].isNewWord = false
            }
            changed = true
        }
        return changed ? updated : nil
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

    /// Splits an existing 2-in-1 page spread within a lesson into two individual pages.
    public func splitPageInLesson(lessonId: UUID, pageId: UUID) async -> Lesson? {
        guard let lessonIndex = lessons.firstIndex(where: { $0.id == lessonId }),
              let pageIndex = lessons[lessonIndex].pages.firstIndex(where: { $0.id == pageId }) else {
            return nil
        }
        let targetPage = lessons[lessonIndex].pages[pageIndex]
        guard spreadSplitter.isTwoPageSpread(imageData: targetPage.imageData) else {
            return nil
        }
        let halves = spreadSplitter.splitSpread(imageData: targetPage.imageData)
        guard halves.count == 2 else { return nil }

        isProcessing = true
        statusMessage = "Splitting 2-page spread..."
        defer {
            isProcessing = false
            statusMessage = nil
        }

        do {
            let splitPages = try await performOCROnPages(
                pagesData: halves,
                startIndex: pageIndex,
                initialCategory: targetPage.category
            )
            let dummy = Lesson(id: lessonId, title: lessons[lessonIndex].title, pages: splitPages)
            let analyzed = try await analyzeLessonUseCase.execute(lesson: dummy)

            var updated = lessons[lessonIndex]
            updated.pages.remove(at: pageIndex)
            updated.pages.insert(contentsOf: analyzed.pages, at: pageIndex)
            reindexPages(&updated.pages)

            try await repository.saveLesson(updated)
            for page in analyzed.pages {
                try await repository.saveVocabularyItems(page.vocabulary)
                try await repository.saveGrammarItems(page.grammar)
            }
            lessons[lessonIndex] = updated
            vocabularyList = try await repository.fetchAllVocabulary()
            grammarList = try await repository.fetchAllGrammar()
            return updated
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func performOCROnPages(
        pagesData: [Data],
        startIndex: Int = 0,
        initialCategory: String? = nil
    ) async throws -> [LessonPage] {
        let expanded = expandSpreads(pagesData: pagesData)
        var pages: [LessonPage] = []
        var activeCategory: String? = initialCategory
        let parser = LessonHeaderParser()

        for (offset, data) in expanded.enumerated() {
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

    private func expandSpreads(pagesData: [Data]) -> [Data] {
        let shouldAutoSplit = UserDefaults.standard.object(forKey: "auto_split_two_page_spreads") as? Bool ?? true
        guard shouldAutoSplit else { return pagesData }
        var expanded: [Data] = []
        for data in pagesData {
            if spreadSplitter.isTwoPageSpread(imageData: data) {
                let halves = spreadSplitter.splitSpread(imageData: data)
                expanded.append(contentsOf: halves)
            } else {
                expanded.append(data)
            }
        }
        return expanded
    }

    private func reindexPages(_ pages: inout [LessonPage]) {
        for index in pages.indices {
            pages[index].pageIndex = index
        }
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
