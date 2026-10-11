import SwiftUI
import OCRData
import JapaneseLearningDomain

public struct BookReaderView: View {
    @State var lesson: Lesson
    let allVocabulary: [VocabularyItem]
    let allGrammar: [GrammarItem]
    let onAddPages: ((UUID, [Data]) async -> Lesson?)?
    let onUpdatePage: ((LessonPage) async -> Void)?
    let onSplitPage: ((UUID, UUID) async -> Lesson?)?

    @State private var selectedPageIndex: Int = 0
    @State private var showExtractedText: Bool = false
    @State private var showStudySheet: Bool = false
    @State private var showEditTextSheet: Bool = false
    @State private var showAddScanner: Bool = false
    private let spreadSplitter = PageSpreadSplitter()

    public init(
        lesson: Lesson,
        allVocabulary: [VocabularyItem] = [],
        allGrammar: [GrammarItem] = [],
        onAddPages: ((UUID, [Data]) async -> Lesson?)? = nil,
        onUpdatePage: ((LessonPage) async -> Void)? = nil,
        onSplitPage: ((UUID, UUID) async -> Lesson?)? = nil
    ) {
        self._lesson = State(initialValue: lesson)
        self.allVocabulary = allVocabulary
        self.allGrammar = allGrammar
        self.onAddPages = onAddPages
        self.onUpdatePage = onUpdatePage
        self.onSplitPage = onSplitPage
    }

    private var currentPage: LessonPage? {
        guard selectedPageIndex >= 0 && selectedPageIndex < lesson.pages.count else { return nil }
        return lesson.pages[selectedPageIndex]
    }

    public var body: some View {
        VStack(spacing: 0) {
            topMetadataStrip
            mainContentWithOverlay
            bottomControlBar
        }
        .navigationTitle(currentPage?.title ?? lesson.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar { readerToolbar }
        .sheet(isPresented: $showStudySheet) {
            studySheetContent
        }
        .sheet(isPresented: $showEditTextSheet) {
            editPageTextContent
        }
        .sheet(isPresented: $showAddScanner) {
            DocumentCameraScannerView(
                onComplete: handleAddedPages,
                onCancel: { showAddScanner = false }
            )
        }
    }

    private var topMetadataStrip: some View {
        HStack(spacing: 8) {
            if let page = currentPage {
                metadataPill(text: page.pageCode, color: .blue)
                metadataPill(text: page.category, color: .purple)
            }
            Spacer()
            Text("Page \(selectedPageIndex + 1) of \(max(lesson.pages.count, 1))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.06))
    }

    private func metadataPill(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var mainContentWithOverlay: some View {
        ZStack(alignment: .bottom) {
            contentPageView
            floatingDisplayModePicker
                .padding(.bottom, 12)
        }
    }

    private var contentPageView: some View {
        TabView(selection: $selectedPageIndex) {
            ForEach(Array(lesson.pages.enumerated()), id: \.element.id) { index, page in
                pageView(for: page)
                    .tag(index)
            }
        }
        #if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        #endif
    }

    @ViewBuilder
    private func pageView(for page: LessonPage) -> some View {
        if showExtractedText {
            extractedTextView(page: page)
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

    private func extractedTextView(page: LessonPage) -> some View {
        ScrollView {
            Text(page.extractedText.isEmpty ? "No text recognized on this page." : page.extractedText)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .background(Color.secondary.opacity(0.04))
    }

    private var floatingDisplayModePicker: some View {
        HStack(spacing: 4) {
            modeToggleButton(title: "Image", icon: "photo", isSelected: !showExtractedText) {
                showExtractedText = false
            }
            modeToggleButton(title: "Text", icon: "doc.text", isSelected: showExtractedText) {
                showExtractedText = true
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 3)
    }

    private func modeToggleButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.purple : Color.clear)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var bottomControlBar: some View {
        VStack(spacing: 8) {
            studyCompanionDock
            pageStepperRow
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(Color.secondary.opacity(0.06))
    }

    private var studyCompanionDock: some View {
        Button(action: { showStudySheet = true }) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("✨ \(currentPageVocabCount) Words • \(currentPageGrammarCount) Grammar")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("Study Deck")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)
                Image(systemName: "chevron.up")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(uiColorOrSecondaryBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var pageStepperRow: some View {
        HStack {
            Button(action: goToPreviousPage) {
                Image(systemName: "chevron.left")
                    .font(.body)
            }
            .disabled(selectedPageIndex == 0)

            Spacer()

            Text("Page \(selectedPageIndex + 1) of \(max(lesson.pages.count, 1))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: goToNextPage) {
                Image(systemName: "chevron.right")
                    .font(.body)
            }
            .disabled(selectedPageIndex >= lesson.pages.count - 1)
        }
        .padding(.horizontal, 8)
    }

    @ToolbarContentBuilder
    private var readerToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button(action: { showEditTextSheet = true }) {
                    Label("Edit OCR Text", systemImage: "pencil")
                }
                if isCurrentPageSpread {
                    Button(action: splitCurrentPage) {
                        Label("Split 2-Page Spread", systemImage: "arrow.left.and.right.square")
                    }
                }
                if onAddPages != nil {
                    Button(action: { showAddScanner = true }) {
                        Label("Add Pages to Lesson", systemImage: "plus")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    @ViewBuilder
    private var studySheetContent: some View {
        if let page = currentPage {
            PageStudySheetView(
                page: page,
                onPageUpdated: { updatedPage in
                    handlePageSave(updatedPage)
                    await onUpdatePage?(updatedPage)
                }
            )
            .presentationDetents([.fraction(0.6), .large])
        }
    }

    @ViewBuilder
    private var editPageTextContent: some View {
        if selectedPageIndex < lesson.pages.count {
            EditPageTextSheet(
                page: $lesson.pages[selectedPageIndex],
                onSave: handlePageSave
            )
        }
    }

    private var isCurrentPageSpread: Bool {
        guard let page = currentPage, onSplitPage != nil else { return false }
        return spreadSplitter.isTwoPageSpread(imageData: page.imageData)
    }

    private func splitCurrentPage() {
        guard let page = currentPage, let onSplitPage else { return }
        Task {
            guard let updated = await onSplitPage(lesson.id, page.id) else { return }
            lesson = updated
        }
    }

    private func goToPreviousPage() {
        guard selectedPageIndex > 0 else { return }
        selectedPageIndex -= 1
    }

    private func goToNextPage() {
        guard selectedPageIndex < lesson.pages.count - 1 else { return }
        selectedPageIndex += 1
    }

    private func handlePageSave(_ updatedPage: LessonPage) {
        guard selectedPageIndex < lesson.pages.count else { return }
        lesson.pages[selectedPageIndex] = updatedPage
    }

    private func handleAddedPages(_ pagesData: [Data]) {
        showAddScanner = false
        guard let onAddPages else { return }
        let firstNewIndex = lesson.pages.count
        Task {
            guard let updated = await onAddPages(lesson.id, pagesData) else { return }
            lesson = updated
            selectedPageIndex = min(firstNewIndex, max(updated.pages.count - 1, 0))
        }
    }

    private var currentPageVocabCount: Int {
        guard let page = currentPage else { return 0 }
        if !page.vocabulary.isEmpty { return page.vocabulary.count }
        return allVocabulary.filter { v in
            page.extractedText.contains(v.word) || page.extractedText.contains(v.reading)
        }.count
    }

    private var currentPageGrammarCount: Int {
        guard let page = currentPage else { return 0 }
        if !page.grammar.isEmpty { return page.grammar.count }
        return allGrammar.filter { g in
            let keyword = g.pattern.replacingOccurrences(of: "〜", with: "")
            return page.extractedText.contains(keyword)
        }.count
    }

    private var uiColorOrSecondaryBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemBackground)
        #else
        return Color.secondary.opacity(0.1)
        #endif
    }
}
