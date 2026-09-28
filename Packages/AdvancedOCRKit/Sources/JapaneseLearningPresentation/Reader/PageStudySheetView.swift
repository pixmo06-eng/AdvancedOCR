import SwiftUI
import JapaneseLearningDomain

public struct PageStudySheetView: View {
    let page: LessonPage
    let allVocabulary: [VocabularyItem]
    let allGrammar: [GrammarItem]

    @State private var selectedTab: StudyTab = .vocabulary
    @State private var filterByPageOnly: Bool = true
    @State private var selectedCardItem: VocabularyItem?

    public enum StudyTab: String, CaseIterable {
        case vocabulary = "Vocabulary"
        case grammar = "Grammar"
    }

    public init(page: LessonPage, allVocabulary: [VocabularyItem], allGrammar: [GrammarItem]) {
        self.page = page
        self.allVocabulary = allVocabulary
        self.allGrammar = allGrammar
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerBanner
                scopePicker
                contentSection
            }
            .navigationTitle("Study: \(page.title)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sheet(item: $selectedCardItem) { item in
                VocabularyCardView(item: item)
                    .presentationDetents([.medium])
            }
        }
    }

    private var headerBanner: some View {
        HStack(spacing: 8) {
            badgeView(title: page.pageCode, color: .blue)
            badgeView(title: page.category, color: .purple)
            Spacer()
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

    private var scopePicker: some View {
        Picker("Scope", selection: $filterByPageOnly) {
            Text("Page \(page.pageCode)").tag(true)
            Text("Category: \(page.category)").tag(false)
        }
        .pickerStyle(.segmented)
        .padding()
    }

    private var contentSection: some View {
        VStack(spacing: 0) {
            Picker("Content", selection: $selectedTab) {
                Text("Vocabulary (\(filteredVocab.count))").tag(StudyTab.vocabulary)
                Text("Grammar (\(filteredGrammar.count))").tag(StudyTab.grammar)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

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

    private var filteredVocab: [VocabularyItem] {
        if filterByPageOnly {
            return allVocabulary.filter { $0.pageId == page.id || $0.pageCode == page.pageCode }
        }
        return allVocabulary.filter { $0.category == page.category }
    }

    private var filteredGrammar: [GrammarItem] {
        if filterByPageOnly {
            return allGrammar.filter { $0.pageId == page.id || $0.pageCode == page.pageCode }
        }
        return allGrammar.filter { $0.category == page.category }
    }

    private var vocabList: some View {
        List(filteredVocab) { item in
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
        .overlay {
            if filteredVocab.isEmpty {
                ContentUnavailableView("No Vocabulary", systemImage: "character.book.closed")
            }
        }
    }

    private var grammarList: some View {
        List(filteredGrammar) { item in
            NavigationLink(destination: GrammarCardView(item: item)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.pattern).font(.headline)
                    Text(item.meaning).font(.caption).foregroundStyle(.secondary)
                    Text(item.formation).font(.caption2).foregroundStyle(.blue)
                }
            }
        }
        .overlay {
            if filteredGrammar.isEmpty {
                ContentUnavailableView("No Grammar", systemImage: "book.pages")
            }
        }
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
