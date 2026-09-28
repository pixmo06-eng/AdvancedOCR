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
            Text(item.reading)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(item.word)
                .font(.system(size: 42, weight: .bold))
            Spacer()
            Text("Tap to reveal meaning & daily examples")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }

    private var cardBack: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(item.meaning)
                .font(.title2)
                .fontWeight(.semibold)

            if !item.examples.isEmpty {
                examplesSection
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Life Context")
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

            Text(example.english)
                .font(.footnote)
                .foregroundStyle(.secondary)
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
