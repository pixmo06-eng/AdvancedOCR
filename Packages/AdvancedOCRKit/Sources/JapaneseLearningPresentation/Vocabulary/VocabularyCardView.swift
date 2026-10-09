import SwiftUI
import JapaneseLearningDomain

public struct VocabularyCardView: View {
    let item: VocabularyItem
    @State private var isFlipped: Bool = false

    public init(item: VocabularyItem) {
        self.item = item
    }

    public var body: some View {
        VStack {
            cardContent
                .frame(maxWidth: .infinity, minHeight: 280)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                .onTapGesture {
                    withAnimation(.spring(duration: 0.35)) {
                        isFlipped.toggle()
                    }
                }

            hintText
        }
        .padding()
    }

    @ViewBuilder
    private var cardContent: some View {
        if isFlipped {
            cardBack
        } else {
            cardFront
        }
    }

    private var cardFront: some View {
        VStack(spacing: 16) {
            topBadgesRow
            Spacer()
            if !item.reading.isEmpty && item.reading != item.word {
                Text(item.reading)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(item.word)
                .font(.system(size: 42, weight: .bold))
            Spacer()
            Text("タップして詳細を表示")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }

    private var cardBack: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardBackHeader
            if !item.examples.isEmpty {
                examplesSection
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    private var cardBackHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(item.word)
                    .font(.title2)
                    .fontWeight(.bold)
                if !item.reading.isEmpty && item.reading != item.word {
                    Text(item.reading)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            badgesRow
            meaningRow
        }
    }

    @ViewBuilder
    private var badgesRow: some View {
        let hasJapanesePOS = !item.partOfSpeech.isEmpty && !item.partOfSpeech.unicodeScalars.contains(where: \.isASCII)
        if hasJapanesePOS {
            Text(item.partOfSpeech)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var meaningRow: some View {
        let hasJapaneseMeaning = !item.meaning.isEmpty && !item.meaning.unicodeScalars.contains(where: \.isASCII)
        if hasJapaneseMeaning {
            Text(item.meaning)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("日常生活の例文")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            ForEach(item.examples) { example in
                exampleRow(example: example)
            }
        }
    }

    private func exampleRow(example: DailyLifeExample) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(example.scenario)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())

            Text(example.japanese)
                .font(.body)
                .fontWeight(.medium)

            if !example.reading.isEmpty && example.reading != example.japanese {
                Text(example.reading)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var topBadgesRow: some View {
        HStack {
            if item.isNewWord {
                newWordBadge
            }
            Spacer()
            occurrenceBadge
        }
    }

    private var newWordBadge: some View {
        Text("新")
            .font(.caption2)
            .fontWeight(.heavy)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.red)
            .clipShape(Capsule())
    }

    private var occurrenceBadge: some View {
        Text("\(item.occurrenceCount)回 登場")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    private var cardBackground: some View {
        Color.white.opacity(0.01)
            .background(Color.secondary.opacity(0.08))
    }

    private var hintText: some View {
        Text(isFlipped ? "タップして戻る" : "タップして詳細を見る")
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }
}
