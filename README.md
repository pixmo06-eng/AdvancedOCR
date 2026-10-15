# AdvancedOCR

AdvancedOCR is an iOS app for scanning Japanese lesson materials and turning them into a searchable, interactive study library. It uses Apple Vision for text recognition and provides tools for reviewing vocabulary and grammar page by page.

## Features

- Scan documents with the camera or import lesson photos.
- Recognize Japanese text with Apple Vision OCR.
- Automatically split landscape images of two-page spreads into separate pages.
- Review and correct recognized page text, then re-analyze it.
- Organize scanned lessons in a library with page-specific vocabulary and grammar.
- Study with searchable lists, category filters, mastery tracking, and flashcards.
- Analyze text on-device, or connect to a compatible local AI server such as Ollama or LM Studio.
- Optionally use Gemini for study-content analysis; offline analysis is available as a fallback.

## Requirements

- macOS with Xcode 15 or later and the iOS 17 SDK.
- XcodeGen to generate the Xcode project from `project.yml`.
- An iPhone or iOS Simulator running iOS 17 or later.

## Build and run

Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) if it is not already installed, then generate and open the Xcode project:

```sh
xcodegen generate
open AdvancedOCR.xcodeproj
```

In Xcode, select the `AdvancedOCR` scheme and an iOS 17+ simulator or device, then build and run.

To build from the command line:

```sh
xcodebuild -project AdvancedOCR.xcodeproj \
  -scheme AdvancedOCR \
  -destination 'generic/platform=iOS Simulator' \
  build
```

## Tests

Run the Swift package test suites with:

```sh
swift test --package-path Packages/AdvancedOCRKit
```

The tests cover OCR domain behavior and Japanese-learning domain and data logic.

## AI configuration

On-device analysis works without a server. To use a local model, open **Settings**, enable **Use Custom Local AI Server**, enter an OpenAI-compatible endpoint, and fetch the available models. Presets are provided for Ollama (`http://localhost:11434/v1`) and LM Studio (`http://localhost:1234/v1`). When connecting to a server on another device, use that device's reachable network address instead of `localhost`; allow AdvancedOCR access to the local network when prompted.

## Project structure

```text
App/                         SwiftUI iOS app and app assets
Packages/AdvancedOCRKit/     Swift package containing the app modules
  Sources/Core/              Shared core types
  Sources/OCRDomain/         OCR entities, protocols, and use cases
  Sources/OCRData/           Apple Vision OCR and image processing
  Sources/OCRPresentation/   OCR scanning UI
  Sources/JapaneseLearningDomain/
                              Japanese-learning entities and use cases
  Sources/JapaneseLearningData/
                              Persistence, NLP, and AI services
  Sources/JapaneseLearningPresentation/
                              Library, reader, and study UI
  Tests/                     Swift package test suites
project.yml                  XcodeGen project definition
```

The app targets iOS 17 and uses SwiftUI, Swift concurrency, and a Clean Architecture-inspired separation of domain, data, and presentation modules.
