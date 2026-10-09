import SwiftUI
import JapaneseLearningDomain

public struct VocabularyListView: View {
    let items: [VocabularyItem]
    @State private var filterOnlyNew: Bool = false
    @State private var selectedCategory: String = "すべて"
    @State private var searchText: String = ""
    @State private var selectedItemForCard: VocabularyItem?

    public init(items: [VocabularyItem]) {
        self.items = items
    }

    private var availableCategories: [String] {
        var categories = Set(items.compactMap(\.category))
        categories.remove("General")
        var sorted = categories.sorted()
        sorted.insert("すべて", at: 0)
        return sorted
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterPicker
                categoryFilterRow
                listContent
            }
            .navigationTitle("語彙")
            .sheet(item: $selectedItemForCard) { item in
                VocabularyCardView(item: item)
                    .presentationDetents([.medium])
            }
        }
    }

    private var filterPicker: some View {
        Picker("フィルター", selection: $filterOnlyNew) {
            Text("すべて (\(items.count))").tag(false)
            Text("新出語のみ (\(newCount))").tag(true)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableCategories, id: \.self) { cat in
                    categoryChip(for: cat)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func categoryChip(for category: String) -> some View {
        Button(action: { selectedCategory = category }) {
            Text(category)
                .font(.footnote)
                .fontWeight(selectedCategory == category ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCategory == category ? Color.blue : Color.secondary.opacity(0.12))
                .foregroundStyle(selectedCategory == category ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var newCount: Int {
        items.filter(\.isNewWord).count
    }

    private var filteredItems: [VocabularyItem] {
        items.filter { item in
            let matchesNew = !filterOnlyNew || item.isNewWord
            let matchesCat = selectedCategory == "すべて" || item.category == selectedCategory
            let matchesSearch = searchText.isEmpty || item.word.contains(searchText) || item.reading.contains(searchText)
            return matchesNew && matchesCat && matchesSearch
        }
    }

    private struct VocabGroup: Identifiable {
        let id: String
        let title: String
        let items: [VocabularyItem]
    }

    private var groupedSections: [VocabGroup] {
        if selectedCategory == "すべて" {
            return groupByLessonCategory()
        }
        return groupByPage()
    }

    private func groupByLessonCategory() -> [VocabGroup] {
        let dict = Dictionary(grouping: filteredItems) { item in
            item.category ?? "その他"
        }
        return dict.keys.sorted().map { key in
            VocabGroup(id: key, title: key, items: dict[key] ?? [])
        }
    }

    private func groupByPage() -> [VocabGroup] {
        let dict = Dictionary(grouping: filteredItems) { item in
            item.pageCode.map { "Page \($0)" } ?? "その他"
        }
        return dict.keys.sorted().map { key in
            VocabGroup(id: key, title: key, items: dict[key] ?? [])
        }
    }

    @ViewBuilder
    private var listContent: some View {
        if groupedSections.isEmpty {
            emptyStateView
        } else {
            vocabularyList
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "語彙が見つかりません",
            systemImage: "character.book.closed",
            description: Text(filterOnlyNew ? "新出語はありません。" : "レッスンをスキャンして語彙を抽出してください。")
        )
    }

    private var vocabularyList: some View {
        List {
            ForEach(groupedSections) { section in
                Section(header: sectionHeaderView(title: section.title, count: section.items.count)) {
                    ForEach(section.items) { item in
                        Button(action: { selectedItemForCard = item }) {
                            vocabularyRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "語彙を検索")
    }

    private func sectionHeaderView(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.footnote)
                .fontWeight(.bold)
            Spacer()
            Text("\(count)語")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func vocabularyRow(item: VocabularyItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                wordTitleRow(item: item)
                detailsRow(item: item)
            }
            Spacer()
            itemBadgeColumn(item: item)
        }
        .padding(.vertical, 4)
    }

    private func wordTitleRow(item: VocabularyItem) -> some View {
        HStack(spacing: 8) {
            Text(item.word)
                .font(.headline)
            if !item.reading.isEmpty && item.reading != item.word {
                Text(item.reading)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if item.isNewWord {
                newBadge
            }
        }
    }

    @ViewBuilder
    private func detailsRow(item: VocabularyItem) -> some View {
        let hasJapaneseMeaning = !item.meaning.isEmpty && !item.meaning.unicodeScalars.contains(where: \.isASCII)
        let hasJapanesePOS = !item.partOfSpeech.isEmpty && !item.partOfSpeech.unicodeScalars.contains(where: \.isASCII)

        if hasJapaneseMeaning {
            Text(item.meaning)
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else if hasJapanesePOS {
            Text(item.partOfSpeech)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func itemBadgeColumn(item: VocabularyItem) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            if let pageCode = item.pageCode {
                Text(pageCode)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
            if let cat = item.category, cat != "General" && cat != "その他" {
                Text(cat)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.1))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
            }
        }
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
