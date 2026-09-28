# Project Memory & Status

## Overview
- **Project Name**: AdvancedOCR
- **Goal**: Advanced iOS OCR application leveraging Clean Architecture, modern SwiftUI, and Swift async/await with SPM modularity.

## Architectural Guidelines
- **Modularity**: Swift Package Manager targets/modules.
- **Layers**:
  - `Domain`: Entities, UseCases/Interactors, Repository Interfaces (zero external dependencies).
  - `Data`: Repository Implementations, Data Sources, Vision/OCR Services.
  - `Presentation`: SwiftUI Views, ViewModels (`@Observable`), Coordinators/Navigation.
  - `Core` / `Common`: Shared utilities, extensions, models.
- **Max Nesting**: ≤ 2 nesting levels (enforce guard early return, flat decomposition).
- **File Length**: ≤ 450 lines per file.
- **Principles**: SOLID, KISS.

## Modular Structure
- `Packages/AdvancedOCRKit`:
  - `Core`: Common error models (`AppError`) and foundation types.
  - `OCRDomain`: Entities (`RecognizedBlock`, `ScanResult`), repository contracts (`OCRServiceProtocol`), and use cases (`RecognizeTextUseCase`). Zero framework dependencies.
  - `OCRData`: Implementations (`VisionOCRService` using Apple Vision framework with Japanese + English support).
  - `OCRPresentation`: SwiftUI Views (`ScannerView`) and `@Observable` ViewModels (`ScannerViewModel`).
  - `JapaneseLearningDomain`: Pure Swift domain layer:
    - Entities: `Lesson`, `LessonPage`, `VocabularyItem`, `GrammarItem`, `DailyLifeExample`, `MasteryStatus`.
    - Protocols: `LessonRepositoryProtocol`, `JapaneseAIServiceProtocol`.
    - Use Cases: `FilterDuplicateVocabularyUseCase`, `FilterDuplicateGrammarUseCase`, `AnalyzeLessonUseCase`.
  - `JapaneseLearningData`: Data layer implementations:
    - `JapaneseNLPService`: On-device tokenization and POS tagging via Apple `NaturalLanguage`.
    - `GeminiStudyAIService`: Hybrid AI service calling Gemini API with automatic offline fallback.
    - `LocalLessonRepository`: Thread-safe actor for local JSON persistence.
  - `JapaneseLearningPresentation`: Modern SwiftUI UI layer:
    - `DocumentCameraScannerView`: Multi-page camera scanning via `VNDocumentCameraViewController`.
    - `BookReaderView`: Digital lesson book reader with page turning and text inspection overlay.
    - `VocabularyListView` & `VocabularyCardView`: Filterable vocab list with "NEW" badges and interactive flashcards.
    - `GrammarListView` & `GrammarCardView`: Filterable grammar list with formation patterns and daily conversational examples.
    - `LessonListView` & `LessonListViewModel`: Lessons dashboard and scan-to-analyze coordinator.
- `App`: Main iOS application target (`AdvancedOCRApp.swift`), generated via XcodeGen (`project.yml`).

## Changelog & Feature Progress
- [x] Initialized Git repository, `.gitignore`, [AGENTS.md](file:///Users/pixmo/Documents/Github/AdvancedOCR/AGENTS.md), and [MEMORY.md](file:///Users/pixmo/Documents/Github/AdvancedOCR/MEMORY.md).
- [x] Scaffolded SPM modular architecture (`AdvancedOCRKit`) with Clean Architecture layers.
- [x] Implemented Domain entities, repository protocols, and text recognition use case.
- [x] Implemented Apple Vision OCR data service (`VisionOCRService`) with Japanese language recognition.
- [x] Built Japanese Learning domain with duplicate filtering use cases for vocabulary and grammar.
- [x] Built Japanese Learning data layer (`JapaneseNLPService`, `GeminiStudyAIService`, `LocalLessonRepository`).
- [x] Built Japanese presentation layer: Document Camera scanner, Book Reader, Vocabulary cards with daily life context, Grammar list with formation rules.
- [x] Built unit test suites (`JapaneseLearningDomainTests` and `OCRDomainTests`) - all passing.
- [x] Verified iOS Simulator build (`xcodebuild` succeeded with 0 errors).
- [ ] Next: Settings view for entering Gemini API key and choosing study preferences.
