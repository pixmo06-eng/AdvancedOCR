import SwiftUI
import Core
import OCRDomain
import OCRData
import JapaneseLearningDomain
import JapaneseLearningData
import JapaneseLearningPresentation

@main
struct AdvancedOCRApp: App {
    @State private var lessonViewModel: LessonListViewModel

    init() {
        let ocrService = VisionOCRService()
        let repository = LocalLessonRepository()
        let localAI = LocalJapaneseAIModel()
        let aiService = GeminiStudyAIService {
            UserDefaults.standard.string(forKey: "gemini_api_key")
        }
        let analyzeUseCase = AnalyzeLessonUseCase(
            aiService: aiService,
            repository: repository,
            localAI: localAI
        )
        let vm = LessonListViewModel(
            repository: repository,
            ocrService: ocrService,
            analyzeLessonUseCase: analyzeUseCase
        )
        _lessonViewModel = State(initialValue: vm)
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                lessonsTab
                vocabularyTab
                grammarTab
                localAITab
            }
        }
    }

    private var lessonsTab: some View {
        LessonListView(viewModel: lessonViewModel)
            .tabItem {
                Label("Lessons", systemImage: "book.pages")
            }
    }

    private var vocabularyTab: some View {
        VocabularyListView(items: lessonViewModel.vocabularyList)
            .tabItem {
                Label("Vocabulary", systemImage: "character.book.closed")
            }
    }

    private var grammarTab: some View {
        GrammarListView(items: lessonViewModel.grammarList)
            .tabItem {
                Label("Grammar", systemImage: "text.book.closed")
            }
    }

    private var localAITab: some View {
        CustomAISettingsView(isModal: false)
            .tabItem {
                Label("Local AI", systemImage: "server.rack")
            }
    }
}
