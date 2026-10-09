import SwiftUI
import JapaneseLearningDomain
import JapaneseLearningData

public struct PageStudySheetView: View {
    @State private var page: LessonPage
    private let onPageUpdated: ((LessonPage) async -> Void)?

    @State private var selectedTab: StudyTab = .vocabulary
    @State private var selectedCardItem: VocabularyItem?
    @State private var pageVocabulary: [VocabularyItem] = []
    @State private var pageGrammar: [GrammarItem] = []
    @State private var isLoading: Bool = false
    @State private var isReanalyzing: Bool = false
    @State private var isShowingSettings: Bool = false
    @State private var isShowingReview: Bool = false
    @State private var candidateContent: ExtractedStudyContent?
    @State private var errorMessage: String?
    @State private var localAIModel: LocalJapaneseAIModel = LocalJapaneseAIModel()
    @State private var customAIService: CustomLocalAIServiceProtocol = CustomLocalAIService()
    @State private var aiGeneratedExamples: [UUID: [DailyLifeExample]] = [:]

    public enum StudyTab: String, CaseIterable {
        case vocabulary = "語彙"
        case grammar = "文法"
    }

    public init(
        page: LessonPage,
        onPageUpdated: ((LessonPage) async -> Void)? = nil
    ) {
        self._page = State(initialValue: page)
        self.onPageUpdated = onPageUpdated
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerBanner
                contentSection
            }
            .navigationTitle("学習: \(page.title)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { toolbarContent }
            .sheet(item: $selectedCardItem) { item in
                VocabularyCardView(item: updatedItemWithAI(item))
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $isShowingSettings) {
                CustomAISettingsView()
            }
            .sheet(isPresented: $isShowingReview) {
                if let candidateContent {
                    ReanalysisReviewSheetView(
                        candidateContent: candidateContent,
                        currentVocabCount: pageVocabulary.count,
                        currentGrammarCount: pageGrammar.count,
                        onAccept: handleAcceptNewResult,
                        onReject: handleRejectNewResult
                    )
                }
            }
            .alert("エラー", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
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
            reanalyzeButton
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

    private var reanalyzeButton: some View {
        Button(action: { Task { await triggerReanalysis() } }) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                Text(isReanalyzing ? "再解析中..." : "再解析 (カスタムAI)")
            }
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.purple)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.purple.opacity(0.12))
            .clipShape(Capsule())
        }
        .disabled(isReanalyzing || isLoading)
    }

    private var contentSection: some View {
        VStack(spacing: 0) {
            tabPicker
            tabContent
        }
    }

    private var tabPicker: some View {
        Picker("区分", selection: $selectedTab) {
            Text("語彙 (\(pageVocabulary.count))").tag(StudyTab.vocabulary)
            Text("文法 (\(pageGrammar.count))").tag(StudyTab.grammar)
        }
        .pickerStyle(.segmented)
        .padding()
    }

    @ViewBuilder
    private var tabContent: some View {
        if isLoading || isReanalyzing {
            loadingView
        } else if selectedTab == .vocabulary {
            vocabList
        } else {
            grammarList
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(isReanalyzing ? "ローカルAIサーバーで再解析中..." : "テキスト解析中...")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            if pageVocabulary.isEmpty && !isLoading && !isReanalyzing {
                ContentUnavailableView("このページの語彙は見つかりませんでした", systemImage: "character.book.closed")
            }
        }
    }

    private func vocabRowButton(item: VocabularyItem) -> some View {
        Button(action: { selectedCardItem = item }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.word).font(.headline)
                    if !item.reading.isEmpty && item.reading != item.word {
                        Text(item.reading).font(.caption).foregroundStyle(.secondary)
                    }
                    if !item.meaning.isEmpty && !item.meaning.unicodeScalars.contains(where: \.isASCII) {
                        Text(item.meaning).font(.footnote).foregroundStyle(.secondary)
                    }
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
                aiGeneratedExamples[item.id] != nil ? "AI例文 作成済み ✓" : "AIで例文を作成",
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
                    if !item.meaning.isEmpty && !item.meaning.unicodeScalars.contains(where: \.isASCII) {
                        Text(item.meaning).font(.caption).foregroundStyle(.secondary)
                    }
                    Text(item.formation).font(.caption2).foregroundStyle(.blue)
                }
            }
        }
        .overlay {
            if pageGrammar.isEmpty && !isLoading && !isReanalyzing {
                ContentUnavailableView("このページの文法は見つかりませんでした", systemImage: "book.pages")
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            HStack(spacing: 8) {
                Button(action: { isShowingSettings = true }) {
                    Image(systemName: "gearshape")
                }
                Button(action: { Task { await forceReextractOnDevice() } }) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading || isReanalyzing)
            }
        }
    }

    private func triggerReanalysis() async {
        let config = CustomAIConfiguration.loadFromDefaults()
        guard !config.selectedModel.isEmpty else {
            isShowingSettings = true
            return
        }

        isReanalyzing = true
        errorMessage = nil

        do {
            let result = try await customAIService.reanalyzePage(
                text: page.extractedText,
                pageCode: page.pageCode,
                category: page.category,
                lessonId: page.id,
                config: config
            )
            candidateContent = result
            isShowingReview = true
        } catch {
            errorMessage = "再解析に失敗しました: \(error.localizedDescription)"
        }

        isReanalyzing = false
    }

    private func handleAcceptNewResult() {
        guard let candidateContent else { return }
        pageVocabulary = candidateContent.vocabulary
        pageGrammar = candidateContent.grammar

        var updatedPage = page
        updatedPage.vocabulary = candidateContent.vocabulary
        updatedPage.grammar = candidateContent.grammar
        page = updatedPage

        Task {
            await onPageUpdated?(updatedPage)
        }
    }

    private func handleRejectNewResult() {
        candidateContent = nil
    }

    private func loadPageContent() async {
        let matchingVocab = filterPageVocab(page.vocabulary)
        let matchingGrammar = filterPageGrammar(page.grammar)

        if !matchingVocab.isEmpty || !matchingGrammar.isEmpty {
            pageVocabulary = matchingVocab
            pageGrammar = matchingGrammar
            return
        }

        await forceReextractOnDevice()
    }

    private func forceReextractOnDevice() async {
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
        Text("新")
            .font(.system(size: 10, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red)
            .clipShape(Capsule())
    }
}
