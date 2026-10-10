import SwiftUI
import JapaneseLearningDomain

public struct LessonListView: View {
    @Bindable var viewModel: LessonListViewModel
    @State private var isShowingScanner: Bool = false
    @State private var newLessonTitle: String = ""
    @State private var isAskingTitle: Bool = false
    @State private var pendingPages: [Data] = []

    public init(viewModel: LessonListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Lessons")
                .toolbar { toolbarContent }
                .sheet(isPresented: $isShowingScanner) {
                    DocumentCameraScannerView(
                        onComplete: handleScanCompletion,
                        onCancel: { isShowingScanner = false }
                    )
                }
                .alert("Lesson Title", isPresented: $isAskingTitle) {
                    titleAlertContent
                }
                .overlay { loadingOverlay }
                .task {
                    await viewModel.loadData()
                }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.lessons.isEmpty {
            emptyStateView
        } else {
            lessonsList
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Hard-Copy Lessons Yet",
            systemImage: "doc.viewfinder",
            description: Text("Tap '+' to scan lesson pages from your textbook or handouts.")
        )
    }

    private var lessonsList: some View {
        List {
            ForEach(viewModel.lessons) { lesson in
                NavigationLink(destination: BookReaderView(
                    lesson: lesson,
                    allVocabulary: viewModel.vocabularyList,
                    allGrammar: viewModel.grammarList,
                    onAddPages: { id, pages in
                        await viewModel.appendPages(to: id, pagesData: pages)
                    },
                    onUpdatePage: { updatedPage in
                        await viewModel.updatePage(lessonId: lesson.id, page: updatedPage)
                    },
                    onSplitPage: { lessonId, pageId in
                        await viewModel.splitPageInLesson(lessonId: lessonId, pageId: pageId)
                    }
                )) {
                    lessonRow(lesson: lesson)
                }
            }
            .onDelete(perform: deleteLesson)
        }
    }

    private func lessonRow(lesson: Lesson) -> some View {
        HStack(spacing: 12) {
            lessonThumbnail(lesson: lesson)
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(.headline)
                Text("\(lesson.pages.count) Pages • \(lesson.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func lessonThumbnail(lesson: Lesson) -> some View {
        Group {
            #if canImport(UIKit)
            if let firstPage = lesson.pages.first,
               let uiImage = UIImage(data: firstPage.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.secondary.opacity(0.2)
            }
            #elseif canImport(AppKit)
            if let firstPage = lesson.pages.first,
               let nsImage = NSImage(data: firstPage.imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.secondary.opacity(0.2)
            }
            #endif
        }
        .frame(width: 48, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: { isShowingScanner = true }) {
                Image(systemName: "plus")
            }
        }
    }

    @ViewBuilder
    private var titleAlertContent: some View {
        TextField("e.g. Lesson 5: In the Restaurant", text: $newLessonTitle)
        Button("Save & Analyze") {
            let pages = pendingPages
            let title = newLessonTitle
            pendingPages = []
            newLessonTitle = ""
            Task {
                await viewModel.processScannedPages(title: title, pagesData: pages)
            }
        }
        Button("Cancel", role: .cancel) {
            pendingPages = []
        }
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.isProcessing {
            ZStack {
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text(viewModel.statusMessage ?? "Processing...")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func handleScanCompletion(pages: [Data]) {
        isShowingScanner = false
        guard !pages.isEmpty else { return }
        pendingPages = pages
        newLessonTitle = "Lesson \(viewModel.lessons.count + 1)"
        isAskingTitle = true
    }

    private func deleteLesson(at offsets: IndexSet) {
        for index in offsets {
            let lesson = viewModel.lessons[index]
            Task {
                await viewModel.deleteLesson(id: lesson.id)
            }
        }
    }
}
