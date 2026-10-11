import SwiftUI
import JapaneseLearningDomain

public struct FlashcardSessionView: View {
    @Environment(\.dismiss) private var dismiss
    let cards: [VocabularyItem]
    let onUpdateMastery: ((VocabularyItem, MasteryStatus) async -> Void)?

    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var masteredCount: Int = 0
    @State private var reviewCount: Int = 0
    @State private var isCompleted: Bool = false

    public init(
        cards: [VocabularyItem],
        onUpdateMastery: ((VocabularyItem, MasteryStatus) async -> Void)? = nil
    ) {
        self.cards = cards
        self.onUpdateMastery = onUpdateMastery
    }

    private var currentCard: VocabularyItem? {
        guard currentIndex >= 0 && currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isCompleted {
                    completionView
                } else if let card = currentCard {
                    sessionHeader
                    Spacer()
                    FlashcardCardView(
                        item: card,
                        isFlipped: isFlipped,
                        onFlip: { isFlipped.toggle() }
                    )
                    Spacer()
                    actionButtons
                } else {
                    emptyCardsView
                }
            }
            .padding()
            .navigationTitle("Flashcards")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var sessionHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Card \(currentIndex + 1) of \(cards.count)")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(masteredCount) Mastered • \(reviewCount) Review")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(currentIndex), total: Double(max(cards.count, 1)))
                .tint(.purple)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button(action: handleReviewAgain) {
                Label("Review Again", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)

            Button(action: handleMarkMastered) {
                Label("Mastered", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding(.horizontal, 8)
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(.purple)
            Text("Session Completed!")
                .font(.title)
                .fontWeight(.bold)
            Text("You practiced \(cards.count) cards.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                statBox(title: "Mastered", count: masteredCount, color: .green)
                statBox(title: "Needs Review", count: reviewCount, color: .orange)
            }
            .padding(.vertical, 16)

            Spacer()
            restartButton
            dismissButton
        }
    }

    private func statBox(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 100)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var restartButton: some View {
        Button(action: restartSession) {
            Text("Practice Again")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(.purple)
    }

    private var dismissButton: some View {
        Button("Finish & Close") {
            dismiss()
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var emptyCardsView: some View {
        ContentUnavailableView(
            "No Cards to Study",
            systemImage: "rectangle.stack.badge.person.crop",
            description: Text("Scan lessons or add vocabulary to start practicing.")
        )
    }

    private func handleReviewAgain() {
        guard let card = currentCard else { return }
        reviewCount += 1
        Task {
            await onUpdateMastery?(card, .learning)
        }
        advanceCard()
    }

    private func handleMarkMastered() {
        guard let card = currentCard else { return }
        masteredCount += 1
        Task {
            await onUpdateMastery?(card, .mastered)
        }
        advanceCard()
    }

    private func advanceCard() {
        isFlipped = false
        if currentIndex + 1 < cards.count {
            currentIndex += 1
            return
        }
        isCompleted = true
    }

    private func restartSession() {
        currentIndex = 0
        isFlipped = false
        masteredCount = 0
        reviewCount = 0
        isCompleted = false
    }
}
