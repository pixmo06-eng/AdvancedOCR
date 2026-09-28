import SwiftUI
import JapaneseLearningDomain

public struct GrammarListView: View {
    let items: [GrammarItem]
    @State private var filterOnlyNew: Bool = false
    @State private var searchText: String = ""

    public init(items: [GrammarItem]) {
        self.items = items
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterPicker
                listContent
            }
            .navigationTitle("Grammar")
        }
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $filterOnlyNew) {
            Text("All (\(items.count))").tag(false)
            Text("New Grammar Only (\(newCount))").tag(true)
        }
        .pickerStyle(.segmented)
        .padding()
    }

    private var newCount: Int {
        items.filter(\.isNewGrammar).count
    }

    private var filteredItems: [GrammarItem] {
        items.filter { item in
            let matchesFilter = !filterOnlyNew || item.isNewGrammar
            let matchesSearch = searchText.isEmpty || item.pattern.contains(searchText) || item.meaning.localizedCaseInsensitiveContains(searchText)
            return matchesFilter && matchesSearch
        }
    }

    @ViewBuilder
    private var listContent: some View {
        if filteredItems.isEmpty {
            emptyStateView
        } else {
            grammarList
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Grammar Found",
            systemImage: "book.pages",
            description: Text(filterOnlyNew ? "No newly marked grammar in this lesson." : "Scan a lesson to extract grammar patterns.")
        )
    }

    private var grammarList: some View {
        List(filteredItems) { item in
            NavigationLink(destination: GrammarCardView(item: item)) {
                grammarRow(item: item)
            }
        }
        .searchable(text: $searchText, prompt: "Search grammar pattern or meaning")
    }

    private func grammarRow(item: GrammarItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.pattern)
                    .font(.headline)
                Spacer()
                if item.isNewGrammar {
                    newBadge
                }
            }
            Text(item.meaning)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(item.formation)
                .font(.caption)
                .foregroundStyle(.blue)
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
