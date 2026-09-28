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

## Changelog & Feature Progress
- [x] Initialized Git repository, `.gitignore`, [AGENTS.md](file:///Users/pixmo/Documents/Github/AdvancedOCR/AGENTS.md), and [MEMORY.md](file:///Users/pixmo/Documents/Github/AdvancedOCR/MEMORY.md).
- [ ] Next: Set up SPM modular structure / Xcode project workspace.
