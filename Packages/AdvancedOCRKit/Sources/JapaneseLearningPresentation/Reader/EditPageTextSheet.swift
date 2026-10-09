import SwiftUI
import JapaneseLearningDomain
import JapaneseLearningData

public struct EditPageTextSheet: View {
    @Binding var page: LessonPage
    let onSave: (LessonPage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var editedText: String = ""
    @State private var isProcessing: Bool = false
    private let aiModel = LocalJapaneseAIModel()

    public init(page: Binding<LessonPage>, onSave: @escaping (LessonPage) -> Void) {
        self._page = page
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                instructionsBanner
                textEditorSection
            }
            .padding()
            .navigationTitle("Edit OCR Text: \(page.pageCode)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { toolbarContent }
            .onAppear {
                editedText = page.extractedText
            }
        }
    }

    private var instructionsBanner: some View {
        HStack {
            Image(systemName: "pencil.and.outline")
                .foregroundStyle(.blue)
            Text("Fix any misrecognized Japanese kanji or words below. Local AI will regenerate page study cards on save.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var textEditorSection: some View {
        TextEditor(text: $editedText)
            .font(.body)
            .padding(8)
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save & Update AI") {
                saveAndReanalyze()
            }
            .fontWeight(.semibold)
            .disabled(isProcessing)
        }
    }

    private func saveAndReanalyze() {
        isProcessing = true
        Task {
            let cleaned = aiModel.correctOCRText(editedText)
            let newVocab = await aiModel.suggestVocabulary(
                from: cleaned,
                pageCode: page.pageCode,
                category: page.category,
                lessonId: page.id
            )
            let newGrammar = await aiModel.extractGrammar(
                from: cleaned,
                pageCode: page.pageCode,
                category: page.category,
                lessonId: page.id
            )

            var updatedPage = page
            updatedPage.extractedText = cleaned
            updatedPage.vocabulary = newVocab
            updatedPage.grammar = newGrammar

            page = updatedPage
            onSave(updatedPage)
            isProcessing = false
            dismiss()
        }
    }
}
