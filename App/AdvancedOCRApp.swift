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
                libraryTab
                studyHubTab
                settingsTab
            }
        }
    }

    private var libraryTab: some View {
        LessonListView(viewModel: lessonViewModel)
            .tabItem {
                Label("Library", systemImage: "book.closed.fill")
            }
    }

    private var studyHubTab: some View {
        StudyHubView(
            vocabulary: lessonViewModel.vocabularyList,
            grammar: lessonViewModel.grammarList,
            onUpdateVocabularyMastery: { item, status in
                await lessonViewModel.updateVocabularyMastery(item: item, status: status)
            }
        )
        .tabItem {
            Label("Study Hub", systemImage: "sparkles.rectangle.stack.fill")
        }
    }

    private var settingsTab: some View {
        SettingsView()
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
    }
}
