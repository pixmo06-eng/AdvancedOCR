import SwiftUI
import JapaneseLearningDomain
import JapaneseLearningData

public struct PageStudySheetView: View {
    let page: LessonPage
    @State private var selectedTab: StudyTab = .vocabulary
    @State private var selectedCardItem: VocabularyItem?
    @State private var pageVocabulary: [VocabularyItem] = []
    @State private var pageGrammar: [GrammarItem] = []
    @State private var isLoading: Bool = false
    @State private var localAIModel: LocalJapaneseAIModel = LocalJapaneseAIModel()
    @State private var aiGeneratedExamples: [UUID: [DailyLifeExample]] = [:]

    public enum StudyTab: String, CaseIterable {
        case vocabulary = "Vocabulary"
        case grammar = "Grammar"
    }

    public init(page: LessonPage) {
        self.page = page
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerBanner
                contentSection
            }
            .navigationTitle("Study: \(page.title)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { toolbarContent }
            .sheet(item: $selectedCardItem) { item in
                VocabularyCardView(item: updatedItemWithAI(item))
                    .presentationDetents([.medium])
            }
            .task {
                await loadPageContent()
            }
        }
    }

    private var headerBanner: some View {
        HStack(spacing: 8) {
            badgeView(title: page.pageCode, color: .blue)
            badgeView(title: page.category, color: .purple)
            Spacer()
            Text("Page-Specific Study")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func badgeView(title: String, color: Color) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var contentSection: some View {
        VStack(spacing: 0) {
            tabPicker
            tabContent
        }
    }

    private var tabPicker: some View {
        Picker("Content", selection: $selectedTab) {
            Text("Vocabulary (\(pageVocabulary.count))").tag(StudyTab.vocabulary)
            Text("Grammar (\(pageGrammar.count))").tag(StudyTab.grammar)
        }
        .pickerStyle(.segmented)
        .padding()
    }

    @ViewBuilder
    private var tabContent: some View {
        if isLoading {
            ProgressView("Analyzing page text with Local AI...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if selectedTab == .vocabulary {
            vocabList
        } else {
            grammarList
        }
    }

    private var vocabList: some View {
        List(pageVocabulary) { item in
            VStack(alignment: .leading, spacing: 6) {
                vocabRowButton(item: item)
                aiSentenceButton(item: item)
            }
            .padding(.vertical, 4)
        }
        .overlay {
            if pageVocabulary.isEmpty && !isLoading {
                ContentUnavailableView("No Vocabulary Found on this Page", systemImage: "character.book.closed")
            }
        }
    }

    private func vocabRowButton(item: VocabularyItem) -> some View {
        Button(action: { selectedCardItem = item }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.word).font(.headline)
                    Text(item.reading).font(.caption).foregroundStyle(.secondary)
                    Text(item.meaning).font(.footnote).foregroundStyle(.secondary)
                }
                Spacer()
                if item.isNewWord {
                    newBadge
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func aiSentenceButton(item: VocabularyItem) -> some View {
        Button(action: { generateSentences(for: item) }) {
            Label(
                aiGeneratedExamples[item.id] != nil ? "AI Sentences Ready ✓" : "Make Sentences with Local AI",
                systemImage: "wand.and.stars"
            )
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.purple)
        }
        .buttonStyle(.bordered)
    }

    private var grammarList: some View {
        List(pageGrammar) { item in
            NavigationLink(destination: GrammarCardView(item: item)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.pattern).font(.headline)
                    Text(item.meaning).font(.caption).foregroundStyle(.secondary)
                    Text(item.formation).font(.caption2).foregroundStyle(.blue)
                }
            }
        }
        .overlay {
            if pageGrammar.isEmpty && !isLoading {
                ContentUnavailableView("No Grammar Patterns Found on this Page", systemImage: "book.pages")
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: { Task { await forceReextract() } }) {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(isLoading)
        }
    }

    private func loadPageContent() async {
        let matchingVocab = filterPageVocab(page.vocabulary)
        let matchingGrammar = filterPageGrammar(page.grammar)

        if !matchingVocab.isEmpty || !matchingGrammar.isEmpty {
            pageVocabulary = matchingVocab
            pageGrammar = matchingGrammar
            return
        }

        await forceReextract()
    }

    private func forceReextract() async {
        isLoading = true
        let rawText = page.extractedText
        let vocab = await localAIModel.suggestVocabulary(
            from: rawText,
            pageCode: page.pageCode,
            category: page.category,
            lessonId: page.id
        )
        let grammar = await localAIModel.extractGrammar(
            from: rawText,
            pageCode: page.pageCode,
            category: page.category,
            lessonId: page.id
        )

        pageVocabulary = filterPageVocab(vocab)
        pageGrammar = filterPageGrammar(grammar)
        isLoading = false
    }

    private func filterPageVocab(_ items: [VocabularyItem]) -> [VocabularyItem] {
        items.filter { item in
            page.extractedText.contains(item.word) || page.extractedText.contains(item.reading)
        }
    }

    private func filterPageGrammar(_ items: [GrammarItem]) -> [GrammarItem] {
        items.filter { item in
            let keyword = item.pattern.replacingOccurrences(of: "〜", with: "")
            return page.extractedText.contains(keyword)
        }
    }

    private func generateSentences(for item: VocabularyItem) {
        Task {
            let examples = await localAIModel.generateSentences(for: item.word, reading: item.reading, meaning: item.meaning)
            aiGeneratedExamples[item.id] = examples
            selectedCardItem = updatedItemWithAI(item)
        }
    }

    private func updatedItemWithAI(_ item: VocabularyItem) -> VocabularyItem {
        guard let aiExamples = aiGeneratedExamples[item.id], !aiExamples.isEmpty else {
            return item
        }
        let updated = item
        let combined = item.examples + aiExamples
        return VocabularyItem(
            id: updated.id,
            word: updated.word,
            reading: updated.reading,
            meaning: updated.meaning,
            partOfSpeech: updated.partOfSpeech,
            jlptLevel: updated.jlptLevel,
            isNewWord: updated.isNewWord,
            occurrenceCount: updated.occurrenceCount,
            masteryStatus: updated.masteryStatus,
            examples: combined,
            firstLessonId: updated.firstLessonId,
            pageId: updated.pageId,
            pageCode: updated.pageCode,
            category: updated.category,
            createdAt: updated.createdAt
        )
    }

    private var newBadge: some View {
        Text("NEW")
            .font(.system(size: 10, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red)
            .clipShape(Capsule())
    }
}
