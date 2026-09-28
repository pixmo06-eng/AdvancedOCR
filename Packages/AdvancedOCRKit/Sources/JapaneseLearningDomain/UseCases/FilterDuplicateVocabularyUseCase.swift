import Foundation

public protocol FilterDuplicateVocabularyUseCaseProtocol: Sendable {
    func execute(
        candidates: [VocabularyItem],
        existingItems: [VocabularyItem]
    ) -> (newItems: [VocabularyItem], updatedExisting: [VocabularyItem])
}

public final class FilterDuplicateVocabularyUseCase: FilterDuplicateVocabularyUseCaseProtocol {
    public init() {}

    public func execute(
        candidates: [VocabularyItem],
        existingItems: [VocabularyItem]
    ) -> (newItems: [VocabularyItem], updatedExisting: [VocabularyItem]) {
        var existingDict = Dictionary(grouping: existingItems, by: { $0.word })
            .compactMapValues(\.first)
        var newItems: [VocabularyItem] = []

        for candidate in candidates {
            processCandidate(candidate, existingDict: &existingDict, newItems: &newItems)
        }

        return (newItems: newItems, updatedExisting: Array(existingDict.values))
    }

    private func processCandidate(
        _ candidate: VocabularyItem,
        existingDict: inout [String: VocabularyItem],
        newItems: inout [VocabularyItem]
    ) {
        if var existing = existingDict[candidate.word] {
            existing.occurrenceCount += 1
            if existing.category == nil { existing.category = candidate.category }
            if existing.pageCode == nil { existing.pageCode = candidate.pageCode }
            existingDict[candidate.word] = existing
            return
        }

        var newWord = candidate
        newWord.isNewWord = true
        newWord.occurrenceCount = 1
        newItems.append(newWord)
        existingDict[newWord.word] = newWord
    }
}
