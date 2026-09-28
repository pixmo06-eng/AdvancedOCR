import Foundation
import JapaneseLearningDomain

public actor LocalLessonRepository: LessonRepositoryProtocol {
    private let directoryURL: URL
    private let lessonsURL: URL
    private let vocabularyURL: URL
    private let grammarURL: URL

    private var cachedLessons: [Lesson] = []
    private var cachedVocabulary: [VocabularyItem] = []
    private var cachedGrammar: [GrammarItem] = []
    private var isLoaded: Bool = false

    public init(storageDirectory: URL? = nil) {
        let base = storageDirectory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.directoryURL = base.appendingPathComponent("AdvancedOCRData", isDirectory: true)
        self.lessonsURL = directoryURL.appendingPathComponent("lessons.json")
        self.vocabularyURL = directoryURL.appendingPathComponent("vocabulary.json")
        self.grammarURL = directoryURL.appendingPathComponent("grammar.json")
    }

    public func fetchLessons() async throws -> [Lesson] {
        try ensureLoaded()
        return cachedLessons
    }

    public func fetchLesson(by id: UUID) async throws -> Lesson? {
        try ensureLoaded()
        return cachedLessons.first(where: { $0.id == id })
    }

    public func saveLesson(_ lesson: Lesson) async throws {
        try ensureLoaded()
        if let index = cachedLessons.firstIndex(where: { $0.id == lesson.id }) {
            cachedLessons[index] = lesson
        } else {
            cachedLessons.append(lesson)
        }
        try persistData(cachedLessons, to: lessonsURL)
    }

    public func deleteLesson(by id: UUID) async throws {
        try ensureLoaded()
        cachedLessons.removeAll(where: { $0.id == id })
        try persistData(cachedLessons, to: lessonsURL)
    }

    public func fetchAllVocabulary() async throws -> [VocabularyItem] {
        try ensureLoaded()
        return cachedVocabulary
    }

    public func saveVocabularyItems(_ items: [VocabularyItem]) async throws {
        try ensureLoaded()
        for item in items {
            updateOrInsertVocabulary(item)
        }
        try persistData(cachedVocabulary, to: vocabularyURL)
    }

    public func fetchAllGrammar() async throws -> [GrammarItem] {
        try ensureLoaded()
        return cachedGrammar
    }

    public func saveGrammarItems(_ items: [GrammarItem]) async throws {
        try ensureLoaded()
        for item in items {
            updateOrInsertGrammar(item)
        }
        try persistData(cachedGrammar, to: grammarURL)
    }

    private func updateOrInsertVocabulary(_ item: VocabularyItem) {
        if let index = cachedVocabulary.firstIndex(where: { $0.word == item.word }) {
            cachedVocabulary[index] = item
            return
        }
        cachedVocabulary.append(item)
    }

    private func updateOrInsertGrammar(_ item: GrammarItem) {
        if let index = cachedGrammar.firstIndex(where: { $0.pattern == item.pattern }) {
            cachedGrammar[index] = item
            return
        }
        cachedGrammar.append(item)
    }

    private func ensureLoaded() throws {
        guard !isLoaded else { return }
        try createDirectoryIfNeeded()
        cachedLessons = loadFile(from: lessonsURL) ?? []
        cachedVocabulary = loadFile(from: vocabularyURL) ?? []
        cachedGrammar = loadFile(from: grammarURL) ?? []
        isLoaded = true
    }

    private func createDirectoryIfNeeded() throws {
        let manager = FileManager.default
        guard !manager.fileExists(atPath: directoryURL.path) else { return }
        try manager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    private func loadFile<T: Decodable>(from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func persistData<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(value)
        try data.write(to: url, options: .atomic)
    }
}
