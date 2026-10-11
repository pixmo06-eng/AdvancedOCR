import XCTest
@testable import JapaneseLearningDomain
@testable import JapaneseLearningData

final class LocalLessonRepositoryMasteryTests: XCTestCase {
    var tempDir: URL!
    var repository: LocalLessonRepository!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        repository = LocalLessonRepository(storageDirectory: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testSaveVocabularyItems_updatesExistingItemMasteryStatus() async throws {
        let initialItem = VocabularyItem(
            word: "車",
            reading: "くるま",
            meaning: "car",
            isNewWord: true,
            masteryStatus: .newWord
        )
        try await repository.saveVocabularyItems([initialItem])

        let fetched = try await repository.fetchAllVocabulary()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.masteryStatus, .newWord)

        var updatedItem = initialItem
        updatedItem.masteryStatus = .mastered
        updatedItem.isNewWord = false
        try await repository.saveVocabularyItems([updatedItem])

        let refreshed = try await repository.fetchAllVocabulary()
        XCTAssertEqual(refreshed.count, 1)
        XCTAssertEqual(refreshed.first?.masteryStatus, .mastered)
        XCTAssertFalse(refreshed.first?.isNewWord ?? true)
    }
}
