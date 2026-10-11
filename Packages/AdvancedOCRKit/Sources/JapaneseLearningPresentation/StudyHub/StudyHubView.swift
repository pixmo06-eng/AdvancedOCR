import SwiftUI
import JapaneseLearningDomain

public struct StudyHubView: View {
    let vocabulary: [VocabularyItem]
    let grammar: [GrammarItem]
    let onUpdateVocabularyMastery: ((VocabularyItem, MasteryStatus) async -> Void)?

    @State private var selectedTab: StudyHubTab = .vocabulary
    @State private var selectedCategory: String = "All"
    @State private var masteryFilter: MasteryFilterOption = .all
    @State private var searchText: String = ""
    @State private var isPresentingFlashcards: Bool = false
    @State private var selectedCardItem: VocabularyItem?

    public enum StudyHubTab: String, CaseIterable {
        case vocabulary = "Vocabulary"
        case grammar = "Grammar"
    }

    public enum MasteryFilterOption: String, CaseIterable {
        case all = "All"
        case needsReview = "Needs Review"
        case mastered = "Mastered"
    }

    public init(
        vocabulary: [VocabularyItem],
        grammar: [GrammarItem],
        onUpdateVocabularyMastery: ((VocabularyItem, MasteryStatus) async -> Void)? = nil
    ) {
        self.vocabulary = vocabulary
        self.grammar = grammar
        self.onUpdateVocabularyMastery = onUpdateVocabularyMastery
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                masterySummaryHeader
                tabSegmentedPicker
                categoryFilterRow
                mainListContent
            }
            .navigationTitle("Study Hub")
            .searchable(text: $searchText, prompt: "Search words, readings, meanings...")
            .sheet(isPresented: $isPresentingFlashcards) {
                FlashcardSessionView(
                    cards: practiceCards,
                    onUpdateMastery: onUpdateVocabularyMastery
                )
            }
            .sheet(item: $selectedCardItem) { item in
                VocabularyCardView(item: item)
                    .presentationDetents([.medium])
            }
        }
    }

    private var masterySummaryHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statPill(title: "Mastered", count: masteredCount, color: .green)
                statPill(title: "Learning", count: learningCount, color: .orange)
                statPill(title: "New", count: newCount, color: .blue)
            }
            practiceButton
        }
        .padding()
        .background(Color.secondary.opacity(0.06))
    }

    private func statPill(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var practiceButton: some View {
        Button(action: { isPresentingFlashcards = true }) {
            HStack {
                Image(systemName: "sparkles.rectangle.stack.fill")
                Text("Start Flashcard Practice (\(practiceCards.count))")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .tint(.purple)
        .disabled(practiceCards.isEmpty)
    }

    private var tabSegmentedPicker: some View {
        Picker("Hub Section", selection: $selectedTab) {
            Text("Vocabulary (\(filteredVocabulary.count))").tag(StudyHubTab.vocabulary)
            Text("Grammar (\(filteredGrammar.count))").tag(StudyHubTab.grammar)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableCategories, id: \.self) { cat in
                    categoryChip(cat)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func categoryChip(_ category: String) -> some View {
        Button(action: { selectedCategory = category }) {
            Text(category)
                .font(.caption)
                .fontWeight(selectedCategory == category ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCategory == category ? Color.purple : Color.secondary.opacity(0.12))
                .foregroundStyle(selectedCategory == category ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var mainListContent: some View {
        if selectedTab == .vocabulary {
            vocabularyListSection
        } else {
            grammarListSection
        }
    }

    private var vocabularyListSection: some View {
        List {
            ForEach(filteredVocabulary) { item in
                vocabRow(item)
            }
        }
        .listStyle(.plain)
        .overlay {
            if filteredVocabulary.isEmpty {
                ContentUnavailableView("No Vocabulary Matching Filters", systemImage: "character.book.closed")
            }
        }
    }

    private func vocabRow(_ item: VocabularyItem) -> some View {
        Button(action: { selectedCardItem = item }) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.word)
                        .font(.headline)
                    if !item.reading.isEmpty && item.reading != item.word {
                        Text(item.reading)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(item.displayRomaji)
                        .font(.caption2)
                        .foregroundStyle(.purple)
                    Text(item.displayMeaning)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                masteryMenu(for: item)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func masteryMenu(for item: VocabularyItem) -> some View {
        Menu {
            Button("Mastered") {
                updateMastery(item: item, status: .mastered)
            }
            Button("Learning") {
                updateMastery(item: item, status: .learning)
            }
            Button("New") {
                updateMastery(item: item, status: .newWord)
            }
        } label: {
            masteryBadge(for: item.masteryStatus)
        }
    }

    private func masteryBadge(for status: MasteryStatus) -> some View {
        let (color, icon): (Color, String) = switch status {
        case .mastered: (.green, "checkmark.circle.fill")
        case .learning: (.orange, "arrow.triangle.2.circlepath")
        case .newWord: (.blue, "sparkle")
        }
        return HStack(spacing: 4) {
            Image(systemName: icon)
            Text(status.rawValue)
        }
        .font(.caption2)
        .fontWeight(.semibold)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }

    private var grammarListSection: some View {
        List {
            ForEach(filteredGrammar) { item in
                NavigationLink(destination: GrammarCardView(item: item)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.pattern)
                            .font(.headline)
                        Text(item.meaning)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(item.formation)
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if filteredGrammar.isEmpty {
                ContentUnavailableView("No Grammar Rules Matching Filters", systemImage: "book.pages")
            }
        }
    }

    private func updateMastery(item: VocabularyItem, status: MasteryStatus) {
        Task {
            await onUpdateVocabularyMastery?(item, status)
        }
    }

    private var masteredCount: Int {
        vocabulary.filter { $0.masteryStatus == .mastered }.count
    }

    private var learningCount: Int {
        vocabulary.filter { $0.masteryStatus == .learning }.count
    }

    private var newCount: Int {
        vocabulary.filter { $0.masteryStatus == .newWord }.count
    }

    private var practiceCards: [VocabularyItem] {
        let unmastered = vocabulary.filter { $0.masteryStatus != .mastered }
        return unmastered.isEmpty ? vocabulary : unmastered
    }

    private var availableCategories: [String] {
        var set = Set(vocabulary.compactMap(\.category))
        set.formUnion(grammar.compactMap(\.category))
        set.remove("General")
        var sorted = set.sorted()
        sorted.insert("All", at: 0)
        return sorted
    }

    private var filteredVocabulary: [VocabularyItem] {
        vocabulary.filter { item in
            let matchesCategory = selectedCategory == "All" || item.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                item.word.contains(searchText) ||
                item.reading.contains(searchText) ||
                item.displayMeaning.localizedCaseInsensitiveContains(searchText) ||
                item.displayRomaji.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    private var filteredGrammar: [GrammarItem] {
        grammar.filter { item in
            let matchesCategory = selectedCategory == "All" || item.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                item.pattern.contains(searchText) ||
                item.meaning.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }
}
