import SwiftUI
import JapaneseLearningDomain

public struct VocabularyListView: View {
    let items: [VocabularyItem]
    @State private var filterOnlyNew: Bool = false
    @State private var searchText: String = ""
    @State private var selectedItemForCard: VocabularyItem?

    public init(items: [VocabularyItem]) {
        self.items = items
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterPicker
                listContent
            }
            .navigationTitle("Vocabulary")
            .sheet(item: $selectedItemForCard) { item in
                VocabularyCardView(item: item)
                    .presentationDetents([.medium])
            }
        }
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $filterOnlyNew) {
            Text("All (\(items.count))").tag(false)
            Text("New Words Only (\(newCount))").tag(true)
        }
        .pickerStyle(.segmented)
        .padding()
    }

    private var newCount: Int {
        items.filter(\.isNewWord).count
    }

    private var filteredItems: [VocabularyItem] {
        items.filter { item in
            let matchesFilter = !filterOnlyNew || item.isNewWord
            let matchesSearch = searchText.isEmpty || item.word.contains(searchText) || item.meaning.localizedCaseInsensitiveContains(searchText)
            return matchesFilter && matchesSearch
        }
    }

    @ViewBuilder
    private var listContent: some View {
        if filteredItems.isEmpty {
            emptyStateView
        } else {
            vocabularyList
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Vocabulary Found",
            systemImage: "character.book.closed",
            description: Text(filterOnlyNew ? "No newly marked words in this lesson." : "Scan a lesson to extract vocabulary.")
        )
    }

    private var vocabularyList: some View {
        List(filteredItems) { item in
            Button(action: { selectedItemForCard = item }) {
                vocabularyRow(item: item)
            }
            .buttonStyle(.plain)
        }
        .searchable(text: $searchText, prompt: "Search vocabulary or meaning")
    }

    private func vocabularyRow(item: VocabularyItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.word)
                        .font(.headline)
                    Text(item.reading)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if item.isNewWord {
                        newBadge
                    }
                }
                Text(item.meaning)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
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
