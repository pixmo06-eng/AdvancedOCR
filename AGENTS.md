# Project Guidelines & Rules

## 1. Architecture & Tech Stack
- **Platform**: iOS (SwiftUI, iOS 17+)
- **Architecture**: Clean Architecture (Domain, Data, Presentation layers)
- **Concurrency**: Modern Swift Concurrency (`async`/`await`, `Sendable`, Actors)
- **Modularity**: Swift Package Manager (SPM) multi-package / multi-target modular design
- **Design Principles**: SOLID & KISS (Keep It Simple, Stupid)

## 2. Code Quality & Formatting Constraints
- **Max Nesting Depth**: Maximum 2 levels of indentation/nesting in any code block.
  - Use `guard` statements and early returns.
  - Decompose SwiftUI views into smaller subviews/computed view properties.
  - Extract helper functions rather than deep nested closures or control flow.
- **Max File Length**: Strict maximum of 450 lines per file.
  - Split large views, extensions, models, and protocols across separate files.

## 3. Workflow & AI Agent Discipline
- **Memory Updates**: Every agent MUST check and update `MEMORY.md` whenever features, architectural decisions, or modules are added or modified.
- **Git Commits**: Commit automatically after finishing each feature with a clear, descriptive conventional commit message (e.g., `feat: ...`, `refactor: ...`, `fix: ...`).
