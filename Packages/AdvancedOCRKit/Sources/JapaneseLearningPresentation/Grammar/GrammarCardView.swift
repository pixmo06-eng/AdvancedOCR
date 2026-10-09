import SwiftUI
import JapaneseLearningDomain

public struct GrammarCardView: View {
    let item: GrammarItem

    public init(item: GrammarItem) {
        self.item = item
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                formationSection
                explanationSection
                examplesSection
            }
            .padding()
        }
        .navigationTitle(item.pattern)
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.pattern)
                    .font(.title)
                    .fontWeight(.bold)
                if !item.meaning.isEmpty {
                    Text(item.meaning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if item.isNewGrammar {
                newBadge
            }
        }
    }

    private var formationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("接続・文型")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            Text(item.formation)
                .font(.callout)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("解説")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            Text(item.explanation)
                .font(.body)
        }
    }

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("例文")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            ForEach(item.examples) { example in
                exampleBox(example: example)
            }
        }
    }

    private func exampleBox(example: DailyLifeExample) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(example.scenario)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.purple.opacity(0.1))
                .clipShape(Capsule())

            Text(example.japanese)
                .font(.body)
                .fontWeight(.medium)

            if !example.reading.isEmpty && example.reading != example.japanese {
                Text(example.reading)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(example.displayRomaji)
                .font(.caption2)
                .foregroundStyle(.purple)

            if !example.english.isEmpty {
                Text(example.english)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }


    private var newBadge: some View {
        Text("新")
            .font(.caption)
            .fontWeight(.heavy)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.red)
            .clipShape(Capsule())
    }
}
