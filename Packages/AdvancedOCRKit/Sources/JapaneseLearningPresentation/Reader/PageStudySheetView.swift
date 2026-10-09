import SwiftUI
import JapaneseLearningDomain
import JapaneseLearningData

public struct PageStudySheetView: View {
    let page: LessonPage
    @State private var selectedTab: StudyTab = .vocabulary
    @State private var selectedCardItem: VocabularyItem?
    @State private var localAIModel: LocalJapaneseAIModel = LocalJapaneseAIModel()
    @State private var aiGeneratedExamples: [UUID: [DailyLifeExample]] = [:]
    @State private var isGeneratingAI: Bool = false

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
            .sheet(item: $selectedCardItem) { item in
                VocabularyCardView(item: updatedItemWithAI(item))
                    .presentationDetents([.medium])
            }
        }
    }

    private var headerBanner: some View {
        HStack(spacing: 8) {
            badgeView(title: page.pageCode, color: .blue)
            badgeView(title: page.category, color: .purple)
            Spacer()
            Text("Page Specific Study")
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
            Picker("Content", selection: $selectedTab) {
                Text("Vocabulary (\(page.vocabulary.count))").tag(StudyTab.vocabulary)
                Text("Grammar (\(page.grammar.count))").tag(StudyTab.grammar)
            }
            .pickerStyle(.segmented)
            .padding()

            tabContent
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        if selectedTab == .vocabulary {
            vocabList
        } else {
            grammarList
        }
    }

    private var vocabList: some View {
        List(page.vocabulary) { item in
            VStack(alignment: .leading, spacing: 6) {
                vocabRowButton(item: item)
                aiSentenceButton(item: item)
            }
            .padding(.vertical, 4)
        }
        .overlay {
            if page.vocabulary.isEmpty {
                ContentUnavailableView("No Vocabulary for this Page", systemImage: "character.book.closed")
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
                aiGeneratedExamples[item.id] != nil ? "AI Sentences Generated ✓" : "Make Sentences with Local AI",
                systemImage: "wand.and.stars"
            )
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.purple)
        }
        .buttonStyle(.bordered)
    }

    private var grammarList: some View {
        List(page.grammar) { item in
            NavigationLink(destination: GrammarCardView(item: item)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.pattern).font(.headline)
                    Text(item.meaning).font(.caption).foregroundStyle(.secondary)
                    Text(item.formation).font(.caption2).foregroundStyle(.blue)
                }
            }
        }
        .overlay {
            if page.grammar.isEmpty {
                ContentUnavailableView("No Grammar for this Page", systemImage: "book.pages")
            }
        }
    }

    private func generateSentences(for item: VocabularyItem) {
        Task {
            isGeneratingAI = true
            let examples = await localAIModel.generateSentences(for: item.word, reading: item.reading, meaning: item.meaning)
            aiGeneratedExamples[item.id] = examples
            isGeneratingAI = false
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
