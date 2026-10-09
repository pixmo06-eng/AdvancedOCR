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
    - Protocols: `LessonRepositoryProtocol`, `JapaneseAIServiceProtocol`, `LocalJapaneseAIProtocol`.
    - Services: `LessonHeaderParser`, `JapaneseTextCleaner` (cleans split kana and OCR spacing artifacts).
    - Use Cases: `FilterDuplicateVocabularyUseCase`, `FilterDuplicateGrammarUseCase`, `AnalyzeLessonUseCase`.
  - `JapaneseLearningData`: Data layer implementations:
    - `JapaneseNLPService`: On-device tokenization and POS tagging via Apple `NaturalLanguage`.
    - `LocalJapaneseAIModel`: On-device local AI intelligence engine for instant sentence and grammar synthesis.
    - `GeminiStudyAIService`: Hybrid AI service with page tagging (`pageId`, `pageCode`, `category`) and offline fallback.
    - `LocalLessonRepository`: Thread-safe actor for local JSON persistence.
  - `JapaneseLearningPresentation`: Modern SwiftUI UI layer:
    - `DocumentCameraScannerView`: Multi-page camera scanning via `VNDocumentCameraViewController`.
    - `BookReaderView`: Digital lesson book reader with page turning, text toggle, and category/page badges.
    - `PageStudySheetView`: Strictly page-specific study drawer displaying only the active page's vocabulary/grammar with Local AI sentence generation button.
    - `EditPageTextSheet`: In-app OCR correction sheet with instant Local AI regeneration.
    - `VocabularyListView` & `VocabularyCardView`: Filterable vocab list with category chips, page tags, "NEW" badges, and interactive flashcards.
    - `GrammarListView` & `GrammarCardView`: Filterable grammar list with category chips, page tags, and conversational examples.
    - `LessonListView` & `LessonListViewModel`: Lessons dashboard and scan-to-analyze coordinator with automatic title generation.
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
- [x] Added `LessonHeaderParser` to auto-generate page titles and category grouping from worksheet headers (e.g. `A 2a - Kanji 1`, `A 1b`, `Kanji 2`).
- [x] Linked vocabulary and grammar directly to each page with `pageId`, `pageCode`, and `category`.
- [x] Added `PageStudySheetView` in `BookReaderView` to navigate directly to linked vocabulary/grammar from the reader screen.
- [x] Added category filter chips to `VocabularyListView` and `GrammarListView`.
- [x] Enhanced Vision OCR with EXIF orientation metadata handling and `VNRecognizeTextRequestRevision3`.
- [x] Added `JapaneseTextCleaner` for normalizing split Kana and OCR artifacts.
- [x] Enforced strictly page-specific vocabulary and grammar in `PageStudySheetView` and `LessonPage`.
- [x] Implemented `LocalJapaneseAIModel` for instant on-device daily life sentence and grammar generation.
- [x] Added `EditPageTextSheet` to allow direct correction of misread OCR text and instant Local AI re-analysis.
- [x] Added `JapaneseLearningDataTests` and expanded test suite to 13 passing unit tests.
- [x] Single-kanji extraction fix, strictly page-specific Study sheet, Local AI model, OCR text editor.
- [x] Add pages to an existing lesson: `+` in `BookReaderView` toolbar -> scanner -> `LessonListViewModel.appendPages` (OCR continues page index/category, analysis per new page, merged lesson persisted).
- [x] Group vocabulary properly by category and page code sections in `VocabularyListView` & `GrammarListView`.
- [x] Complete immersion: omitted all English from vocabulary list, flashcards, reader study sheets, and AI daily life examples.
- [x] Verified vocabulary extraction using Local AI morphological validation (`NLTagger`), filtering out particles, textbook metadata, and OCR artifacts.
- [x] Custom local AI server integration: configurable endpoint & API key with automatic model discovery from Ollama and OpenAI-compatible servers (`CustomAISettingsView`).
- [x] Page Re-Analyze flow: send page text to locally hosted AI server instead of on-device AI, with interactive review sheet (`ReanalysisReviewSheetView`) to accept or reject results.
- [x] Added Romaji transliteration and English translations for vocabulary items and daily life examples across cards, lists, study sheets, and re-analysis preview.
- [x] Entire app UI localized into English: navigation bars, tab bars, buttons, empty states, search prompts, section headers, badges, alerts, settings, and re-analysis review flows.

