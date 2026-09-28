import SwiftUI
import JapaneseLearningDomain

public struct BookReaderView: View {
    let lesson: Lesson
    let allVocabulary: [VocabularyItem]
    let allGrammar: [GrammarItem]

    @State private var selectedPageIndex: Int = 0
    @State private var showExtractedText: Bool = false
    @State private var showStudySheet: Bool = false

    public init(
        lesson: Lesson,
        allVocabulary: [VocabularyItem] = [],
        allGrammar: [GrammarItem] = []
    ) {
        self.lesson = lesson
        self.allVocabulary = allVocabulary
        self.allGrammar = allGrammar
    }

    private var currentPage: LessonPage? {
        guard selectedPageIndex >= 0 && selectedPageIndex < lesson.pages.count else { return nil }
        return lesson.pages[selectedPageIndex]
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerBar
            contentArea
            bottomNavigationBar
        }
        .navigationTitle(currentPage?.title ?? lesson.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showStudySheet) {
            if let page = currentPage {
                PageStudySheetView(
                    page: page,
                    allVocabulary: allVocabulary,
                    allGrammar: allGrammar
                )
            }
        }
    }

    private var headerBar: some View {
        HStack {
            pageMetadataBadges
            Spacer()
            studyPageButton
            textToggleSwitch
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.08))
    }

    private var pageMetadataBadges: some View {
        HStack(spacing: 6) {
            if let page = currentPage {
                Text(page.pageCode)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.12))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())

                Text(page.category)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.12))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
            }
        }
    }

    private var studyPageButton: some View {
        Button(action: { showStudySheet = true }) {
            Label("Study", systemImage: "sparkles")
                .font(.footnote)
                .fontWeight(.medium)
        }
        .buttonStyle(.bordered)
        .tint(.purple)
    }

    private var textToggleSwitch: some View {
        Button(action: { showExtractedText.toggle() }) {
            Label(
                showExtractedText ? "Image" : "Text",
                systemImage: showExtractedText ? "photo" : "doc.text"
            )
            .font(.footnote)
        }
        .buttonStyle(.borderedProminent)
        .tint(showExtractedText ? .orange : .blue)
    }

    private var contentArea: some View {
        TabView(selection: $selectedPageIndex) {
            ForEach(Array(lesson.pages.enumerated()), id: \.element.id) { index, page in
                pageContentView(page: page)
                    .tag(index)
            }
        }
        #if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        #endif
    }

    @ViewBuilder
    private func pageContentView(page: LessonPage) -> some View {
        if showExtractedText {
            extractedTextScroll(page: page)
        } else {
            pageImageView(page: page)
        }
    }

    private func pageImageView(page: LessonPage) -> some View {
        GeometryReader { proxy in
            #if canImport(UIKit)
            if let uiImage = UIImage(data: page.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width, height: proxy.size.height)
            } else {
                placeholderImage
            }
            #elseif canImport(AppKit)
            if let nsImage = NSImage(data: page.imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width, height: proxy.size.height)
            } else {
                placeholderImage
            }
            #endif
        }
    }

    private var placeholderImage: some View {
        ContentUnavailableView(
            "Page Image",
            systemImage: "photo",
            description: Text("Scanned image preview")
        )
    }

    private func extractedTextScroll(page: LessonPage) -> some View {
        ScrollView {
            Text(page.extractedText.isEmpty ? "No text recognized on this page." : page.extractedText)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .background(Color.secondary.opacity(0.05))
    }

    private var bottomNavigationBar: some View {
        HStack {
            Button(action: goToPreviousPage) {
                Image(systemName: "chevron.left")
            }
            .disabled(selectedPageIndex == 0)

            Spacer()

            Text("Page \(selectedPageIndex + 1) of \(max(lesson.pages.count, 1))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: goToNextPage) {
                Image(systemName: "chevron.right")
            }
            .disabled(selectedPageIndex >= lesson.pages.count - 1)
        }
        .padding()
    }

    private func goToPreviousPage() {
        guard selectedPageIndex > 0 else { return }
        selectedPageIndex -= 1
    }

    private func goToNextPage() {
        guard selectedPageIndex < lesson.pages.count - 1 else { return }
        selectedPageIndex += 1
    }
}
