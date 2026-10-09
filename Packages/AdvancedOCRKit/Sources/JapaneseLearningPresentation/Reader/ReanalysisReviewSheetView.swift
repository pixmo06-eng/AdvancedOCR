import SwiftUI
import JapaneseLearningDomain

public struct ReanalysisReviewSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let candidateContent: ExtractedStudyContent
    let currentVocabCount: Int
    let currentGrammarCount: Int
    let onAccept: () -> Void
    let onReject: () -> Void

    @State private var selectedTab: ReviewTab = .vocabulary

    public enum ReviewTab: String, CaseIterable {
        case vocabulary = "語彙"
        case grammar = "文法"
    }

    public init(
        candidateContent: ExtractedStudyContent,
        currentVocabCount: Int,
        currentGrammarCount: Int,
        onAccept: @escaping () -> Void,
        onReject: @escaping () -> Void
    ) {
        self.candidateContent = candidateContent
        self.currentVocabCount = currentVocabCount
        self.currentGrammarCount = currentGrammarCount
        self.onAccept = onAccept
        self.onReject = onReject
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                summaryBanner
                tabPicker
                tabContent
                actionButtonsBar
            }
            .navigationTitle("再解析結果の確認")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private var summaryBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ローカルAIサーバーによる解析完了")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(.purple)
            Text("新しく検出された語彙 \(candidateContent.vocabulary.count)語、文法 \(candidateContent.grammar.count)項目")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.08))
    }

    private var tabPicker: some View {
        Picker("区分", selection: $selectedTab) {
            Text("新出語彙 (\(candidateContent.vocabulary.count))").tag(ReviewTab.vocabulary)
            Text("新出文法 (\(candidateContent.grammar.count))").tag(ReviewTab.grammar)
        }
        .pickerStyle(.segmented)
        .padding()
    }

    @ViewBuilder
    private var tabContent: some View {
        if selectedTab == .vocabulary {
            vocabularyList
        } else {
            grammarList
        }
    }

    private var vocabularyList: some View {
        List(candidateContent.vocabulary) { item in
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.word)
                        .font(.headline)
                    if !item.reading.isEmpty && item.reading != item.word {
                        Text(item.reading)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !item.partOfSpeech.isEmpty {
                        Text(item.partOfSpeech)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
                if let example = item.examples.first {
                    Text(example.japanese)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var grammarList: some View {
        List(candidateContent.grammar) { item in
            VStack(alignment: .leading, spacing: 4) {
                Text(item.pattern)
                    .font(.headline)
                if !item.meaning.isEmpty {
                    Text(item.meaning)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !item.formation.isEmpty {
                    Text(item.formation)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var actionButtonsBar: some View {
        HStack(spacing: 12) {
            Button(action: handleReject) {
                Label("破棄する", systemImage: "xmark")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.red)

            Button(action: handleAccept) {
                Label("新結果を適用", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding()
        .background(Color.secondary.opacity(0.06))
    }

    private func handleAccept() {
        onAccept()
        dismiss()
    }

    private func handleReject() {
        onReject()
        dismiss()
    }
}
