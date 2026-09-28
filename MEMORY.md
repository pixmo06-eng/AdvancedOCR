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
  - `OCRData`: Implementations (`VisionOCRService` using Apple Vision framework).
  - `OCRPresentation`: SwiftUI Views (`ScannerView`) and `@Observable` ViewModels (`ScannerViewModel`).
- `App`: Main iOS application target (`AdvancedOCRApp.swift`), generated via XcodeGen (`project.yml`).

## Changelog & Feature Progress
- [x] Initialized Git repository, `.gitignore`, [AGENTS.md](file:///Users/pixmo/Documents/Github/AdvancedOCR/AGENTS.md), and [MEMORY.md](file:///Users/pixmo/Documents/Github/AdvancedOCR/MEMORY.md).
- [x] Scaffolded SPM modular architecture (`AdvancedOCRKit`) with Clean Architecture layers.
- [x] Implemented Domain entities, repository protocols, and text recognition use case.
- [x] Implemented Apple Vision OCR data service (`VisionOCRService`).
- [x] Implemented SwiftUI presentation layer (`ScannerView` and `@Observable` `ScannerViewModel`).
- [x] Added unit tests for domain use case with mock service.
- [x] Configured XcodeGen (`project.yml`) and verified successful iOS simulator build.
- [ ] Next: Camera capture & Photo Picker integration for document scanning.
