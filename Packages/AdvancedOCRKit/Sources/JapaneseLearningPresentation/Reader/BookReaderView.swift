import SwiftUI
import JapaneseLearningDomain

public struct BookReaderView: View {
    let lesson: Lesson
    @State private var selectedPageIndex: Int = 0
    @State private var showExtractedText: Bool = false

    public init(lesson: Lesson) {
        self.lesson = lesson
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerBar
            contentArea
            bottomNavigationBar
        }
        .navigationTitle(lesson.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var headerBar: some View {
        HStack {
            Text("Page \(selectedPageIndex + 1) of \(max(lesson.pages.count, 1))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            textToggleSwitch
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.08))
    }

    private var textToggleSwitch: some View {
        Button(action: { showExtractedText.toggle() }) {
            Label(
                showExtractedText ? "Show Image" : "Show Text",
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

            Text("Swipe left/right to turn pages")
                .font(.caption2)
                .foregroundStyle(.tertiary)

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
