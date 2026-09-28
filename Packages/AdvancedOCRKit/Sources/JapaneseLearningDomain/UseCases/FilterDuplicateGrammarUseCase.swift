import Foundation

public protocol FilterDuplicateGrammarUseCaseProtocol: Sendable {
    func execute(
        candidates: [GrammarItem],
        existingItems: [GrammarItem]
    ) -> (newItems: [GrammarItem], updatedExisting: [GrammarItem])
}

public final class FilterDuplicateGrammarUseCase: FilterDuplicateGrammarUseCaseProtocol {
    public init() {}

    public func execute(
        candidates: [GrammarItem],
        existingItems: [GrammarItem]
    ) -> (newItems: [GrammarItem], updatedExisting: [GrammarItem]) {
        var existingDict = Dictionary(grouping: existingItems, by: { $0.pattern })
            .compactMapValues(\.first)
        var newItems: [GrammarItem] = []

        for candidate in candidates {
            processCandidate(candidate, existingDict: &existingDict, newItems: &newItems)
        }

        return (newItems: newItems, updatedExisting: Array(existingDict.values))
    }

    private func processCandidate(
        _ candidate: GrammarItem,
        existingDict: inout [String: GrammarItem],
        newItems: inout [GrammarItem]
    ) {
        if var existing = existingDict[candidate.pattern] {
            existing.occurrenceCount += 1
            existingDict[candidate.pattern] = existing
            return
        }

        var newGrammar = candidate
        newGrammar.isNewGrammar = true
        newGrammar.occurrenceCount = 1
        newItems.append(newGrammar)
        existingDict[newGrammar.pattern] = newGrammar
    }
}
