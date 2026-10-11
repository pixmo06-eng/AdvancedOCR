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
        VStack(spacing: 10) {
            topBadgesRow
            Spacer()
            if !item.reading.isEmpty && item.reading != item.word {
                Text(item.reading)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(item.word)
                .font(.system(size: 40, weight: .bold))

            Text(item.displayRomaji)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.purple)

            if !item.displayMeaning.isEmpty {
                Text(item.displayMeaning)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Tap to reveal details")
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
            Text(item.displayRomaji)
                .font(.subheadline)
                .foregroundStyle(.purple)

            if !item.displayMeaning.isEmpty {
                Text(item.displayMeaning)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            badgesRow
        }
    }

    @ViewBuilder
    private var badgesRow: some View {
        if !item.partOfSpeech.isEmpty {
            Text(item.partOfSpeech)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
        }
    }

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Life Examples")
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

            Text(example.displayRomaji)
                .font(.caption2)
                .foregroundStyle(.purple)

            if !example.displayEnglish.isEmpty {
                Text(example.displayEnglish)
                    .font(.footnote)
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
        Text("NEW")
            .font(.caption2)
            .fontWeight(.heavy)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.red)
            .clipShape(Capsule())
    }

    private var occurrenceBadge: some View {
        Text("Seen \(item.occurrenceCount)x")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    private var cardBackground: some View {
        Color.white.opacity(0.01)
            .background(Color.secondary.opacity(0.08))
    }

    private var hintText: some View {
        Text(isFlipped ? "Tap card to flip back" : "Tap card to view details")
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }
}
