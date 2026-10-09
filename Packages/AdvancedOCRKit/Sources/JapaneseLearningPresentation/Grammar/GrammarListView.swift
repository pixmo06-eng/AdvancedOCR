import SwiftUI
import JapaneseLearningDomain

public struct GrammarListView: View {
    let items: [GrammarItem]
    @State private var filterOnlyNew: Bool = false
    @State private var selectedCategory: String = "すべて"
    @State private var searchText: String = ""

    public init(items: [GrammarItem]) {
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
            .navigationTitle("文法")
        }
    }

    private var filterPicker: some View {
        Picker("フィルター", selection: $filterOnlyNew) {
            Text("すべて (\(items.count))").tag(false)
            Text("新出文法のみ (\(newCount))").tag(true)
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
        items.filter(\.isNewGrammar).count
    }

    private var filteredItems: [GrammarItem] {
        items.filter { item in
            let matchesNew = !filterOnlyNew || item.isNewGrammar
            let matchesCat = selectedCategory == "すべて" || item.category == selectedCategory
            let matchesSearch = searchText.isEmpty || item.pattern.contains(searchText)
            return matchesNew && matchesCat && matchesSearch
        }
    }

    private struct GrammarGroup: Identifiable {
        let id: String
        let title: String
        let items: [GrammarItem]
    }

    private var groupedSections: [GrammarGroup] {
        if selectedCategory == "すべて" {
            return groupByLessonCategory()
        }
        return groupByPage()
    }

    private func groupByLessonCategory() -> [GrammarGroup] {
        let dict = Dictionary(grouping: filteredItems) { item in
            item.category ?? "その他"
        }
        return dict.keys.sorted().map { key in
            GrammarGroup(id: key, title: key, items: dict[key] ?? [])
        }
    }

    private func groupByPage() -> [GrammarGroup] {
        let dict = Dictionary(grouping: filteredItems) { item in
            item.pageCode.map { "Page \($0)" } ?? "その他"
        }
        return dict.keys.sorted().map { key in
            GrammarGroup(id: key, title: key, items: dict[key] ?? [])
        }
    }

    @ViewBuilder
    private var listContent: some View {
        if groupedSections.isEmpty {
            emptyStateView
        } else {
            grammarList
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "文法が見つかりません",
            systemImage: "book.pages",
            description: Text(filterOnlyNew ? "新出文法はありません。" : "レッスンをスキャンして文法を抽出してください。")
        )
    }

    private var grammarList: some View {
        List {
            ForEach(groupedSections) { section in
                Section(header: sectionHeaderView(title: section.title, count: section.items.count)) {
                    ForEach(section.items) { item in
                        NavigationLink(destination: GrammarCardView(item: item)) {
                            grammarRow(item: item)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "文法を検索")
    }

    private func sectionHeaderView(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.footnote)
                .fontWeight(.bold)
            Spacer()
            Text("\(count)項目")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func grammarRow(item: GrammarItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            grammarTitleRow(item: item)
            if !item.meaning.isEmpty && !item.meaning.unicodeScalars.contains(where: \.isASCII) {
                Text(item.meaning)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            grammarFooterRow(item: item)
        }
        .padding(.vertical, 4)
    }

    private func grammarTitleRow(item: GrammarItem) -> some View {
        HStack {
            Text(item.pattern)
                .font(.headline)
            Spacer()
            if item.isNewGrammar {
                newBadge
            }
        }
    }

    private func grammarFooterRow(item: GrammarItem) -> some View {
        HStack {
            Text(item.formation)
                .font(.caption)
                .foregroundStyle(.blue)
            Spacer()
            if let pageCode = item.pageCode {
                Text(pageCode)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
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
