import SwiftUI
import JapaneseLearningDomain

public struct FlashcardCardView: View {
    let item: VocabularyItem
    let isFlipped: Bool
    let onFlip: () -> Void

    public init(item: VocabularyItem, isFlipped: Bool, onFlip: @escaping () -> Void) {
        self.item = item
        self.isFlipped = isFlipped
        self.onFlip = onFlip
    }

    public var body: some View {
        Button(action: onFlip) {
            ZStack {
                cardBackground
                if isFlipped {
                    cardBackContent
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                } else {
                    cardFrontContent
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 360)
            .padding(.horizontal, 24)
        }
        .buttonStyle(.plain)
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isFlipped)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(uiColorOrSystemBackground))
            .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
    }

    private var cardFrontContent: some View {
        VStack(spacing: 16) {
            if !item.reading.isEmpty && item.reading != item.word {
                Text(item.reading)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Text(item.word)
                .font(.system(size: 48, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
            Text(item.displayRomaji)
                .font(.headline)
                .foregroundStyle(.purple)
            Spacer()
            flipHint
        }
        .padding(32)
    }

    private var cardBackContent: some View {
        VStack(spacing: 12) {
            backHeader
            Divider()
            meaningSection
            if let example = item.examples.first {
                exampleSection(example)
            }
            Spacer()
            statusBadge
        }
        .padding(24)
    }

    private var backHeader: some View {
        VStack(spacing: 2) {
            Text(item.word)
                .font(.title2)
                .fontWeight(.bold)
            Text(item.displayRomaji)
                .font(.caption)
                .foregroundStyle(.purple)
        }
    }

    private var meaningSection: some View {
        VStack(spacing: 4) {
            Text(item.meaning)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            if !item.partOfSpeech.isEmpty {
                Text(item.partOfSpeech)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func exampleSection(_ example: DailyLifeExample) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(example.japanese)
                .font(.footnote)
                .fontWeight(.medium)
            if !example.displayRomaji.isEmpty {
                Text(example.displayRomaji)
                    .font(.caption2)
                    .foregroundStyle(.purple)
            }
            Text(example.english)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var flipHint: some View {
        Label("Tap to flip", systemImage: "arrow.triangle.2.circlepath")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var statusBadge: some View {
        Text("Current: \(item.masteryStatus.rawValue)")
            .font(.caption2)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.purple.opacity(0.12))
            .foregroundStyle(.purple)
            .clipShape(Capsule())
    }

    private var uiColorOrSystemBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemBackground)
        #else
        return Color.secondary.opacity(0.1)
        #endif
    }
}
