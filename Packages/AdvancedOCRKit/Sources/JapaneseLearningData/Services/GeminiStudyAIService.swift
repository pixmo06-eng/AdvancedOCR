import Foundation
import Core
import JapaneseLearningDomain

public final class GeminiStudyAIService: JapaneseAIServiceProtocol {
    private let apiKeyProvider: @Sendable () -> String?
    private let nlpService: JapaneseNLPService
    private let session: URLSession

    public init(
        apiKeyProvider: @escaping @Sendable () -> String? = { nil },
        nlpService: JapaneseNLPService = JapaneseNLPService(),
        session: URLSession = .shared
    ) {
        self.apiKeyProvider = apiKeyProvider
        self.nlpService = nlpService
        self.session = session
    }

    public func extractStudyContent(
        from text: String,
        lessonId: UUID,
        pageId: UUID? = nil,
        pageCode: String? = nil,
        category: String? = nil
    ) async throws -> ExtractedStudyContent {
        guard let apiKey = apiKeyProvider(), !apiKey.isEmpty else {
            return fallbackOfflineContent(from: text, lessonId: lessonId, pageId: pageId, pageCode: pageCode, category: category)
        }

        do {
            return try await requestGeminiContent(
                text: text,
                apiKey: apiKey,
                lessonId: lessonId,
                pageId: pageId,
                pageCode: pageCode,
                category: category
            )
        } catch {
            return fallbackOfflineContent(from: text, lessonId: lessonId, pageId: pageId, pageCode: pageCode, category: category)
        }
    }

    private func requestGeminiContent(
        text: String,
        apiKey: String,
        lessonId: UUID,
        pageId: UUID?,
        pageCode: String?,
        category: String?
    ) async throws -> ExtractedStudyContent {
        let url = try buildURL(apiKey: apiKey)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try buildRequestBody(text: text)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AppError.ocrRecognitionFailed("Gemini API request failed")
        }

        return try parseGeminiResponse(
            data: data,
            lessonId: lessonId,
            pageId: pageId,
            pageCode: pageCode,
            category: category
        )
    }

    private func buildURL(apiKey: String) throws -> URL {
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: endpoint) else {
            throw AppError.ocrRecognitionFailed("Invalid Gemini URL")
        }
        return url
    }

    private func buildRequestBody(text: String) throws -> Data {
        let prompt = """
        Analyze this Japanese lesson text. Output ONLY valid JSON with keys "vocabulary" and "grammar".
        "vocabulary": array of objects with keys: "word", "reading", "meaning", "jlptLevel", "exampleJapanese", "exampleReading", "exampleEnglish", "scenario".
        "grammar": array of objects with keys: "pattern", "meaning", "formation", "explanation", "jlptLevel", "exampleJapanese", "exampleReading", "exampleEnglish", "scenario".
        Lesson text:
        \(text)
        """

        let payload: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "responseMimeType": "application/json"
            ]
        ]
        return try JSONSerialization.data(withJSONObject: payload)
    }

    private func parseGeminiResponse(
        data: Data,
        lessonId: UUID,
        pageId: UUID?,
        pageCode: String?,
        category: String?
    ) throws -> ExtractedStudyContent {
        let root = try JSONDecoder().decode(GeminiResponseDTO.self, from: data)
        guard let jsonString = root.candidates?.first?.content?.parts?.first?.text,
              let jsonData = jsonString.data(using: .utf8) else {
            throw AppError.ocrRecognitionFailed("Empty Gemini response")
        }

        let studyDTO = try JSONDecoder().decode(StudyContentDTO.self, from: jsonData)
        let vocab = studyDTO.vocabulary.map {
            $0.toDomain(lessonId: lessonId, pageId: pageId, pageCode: pageCode, category: category)
        }
        let grammar = studyDTO.grammar.map {
            $0.toDomain(lessonId: lessonId, pageId: pageId, pageCode: pageCode, category: category)
        }
        return ExtractedStudyContent(vocabulary: vocab, grammar: grammar)
    }

    private func fallbackOfflineContent(
        from text: String,
        lessonId: UUID,
        pageId: UUID?,
        pageCode: String?,
        category: String?
    ) -> ExtractedStudyContent {
        let words = nlpService.extractTokens(from: text).map { word -> VocabularyItem in
            var updated = word
            updated.pageId = pageId
            updated.pageCode = pageCode
            updated.category = category
            return updated
        }
        let sampleGrammar = detectBasicGrammar(
            in: text,
            lessonId: lessonId,
            pageId: pageId,
            pageCode: pageCode,
            category: category
        )
        return ExtractedStudyContent(vocabulary: words, grammar: sampleGrammar)
    }

    private func detectBasicGrammar(
        in text: String,
        lessonId: UUID,
        pageId: UUID?,
        pageCode: String?,
        category: String?
    ) -> [GrammarItem] {
        var items: [GrammarItem] = []
        let patterns: [(pattern: String, meaning: String, formation: String, explanation: String)] = [
            ("〜てください", "Please do", "Te-form + ください", "Used to make polite requests in daily life."),
            ("〜てもいい", "May do / Permission", "Te-form + もいい", "Used to ask or grant permission."),
            ("〜なければならない", "Must do / Obligation", "Nai-stem + ければならない", "Indicates strong necessity or duty.")
        ]

        for item in patterns {
            guard text.contains(item.pattern.replacingOccurrences(of: "〜", with: "")) else {
                continue
            }
            let example = DailyLifeExample(
                japanese: "\(item.pattern.replacingOccurrences(of: "〜", with: ""))の文脈です。",
                reading: "ぶんみゃくです。",
                english: "Used in everyday context.",
                scenario: "Daily Practice"
            )
            items.append(GrammarItem(
                pattern: item.pattern,
                meaning: item.meaning,
                formation: item.formation,
                explanation: item.explanation,
                examples: [example],
                lessonId: lessonId,
                pageId: pageId,
                pageCode: pageCode,
                category: category
            ))
        }
        return items
    }
}

// MARK: - DTOs
struct GeminiResponseDTO: Codable {
    let candidates: [GeminiCandidateDTO]?
}

struct GeminiCandidateDTO: Codable {
    let content: GeminiContentDTO?
}

struct GeminiContentDTO: Codable {
    let parts: [GeminiPartDTO]?
}

struct GeminiPartDTO: Codable {
    let text: String?
}

struct StudyContentDTO: Codable {
    let vocabulary: [VocabDTO]
    let grammar: [GrammarDTO]
}

struct VocabDTO: Codable {
    let word: String
    let reading: String
    let meaning: String
    let jlptLevel: String?
    let exampleJapanese: String?
    let exampleReading: String?
    let exampleEnglish: String?
    let scenario: String?

    func toDomain(
        lessonId: UUID,
        pageId: UUID?,
        pageCode: String?,
        category: String?
    ) -> VocabularyItem {
        let example = DailyLifeExample(
            japanese: exampleJapanese ?? word,
            reading: exampleReading ?? reading,
            english: exampleEnglish ?? meaning,
            scenario: scenario ?? "Everyday conversation"
        )
        return VocabularyItem(
            word: word,
            reading: reading,
            meaning: meaning,
            jlptLevel: jlptLevel,
            isNewWord: true,
            examples: [example],
            firstLessonId: lessonId,
            pageId: pageId,
            pageCode: pageCode,
            category: category
        )
    }
}

struct GrammarDTO: Codable {
    let pattern: String
    let meaning: String
    let formation: String
    let explanation: String
    let jlptLevel: String?
    let exampleJapanese: String?
    let exampleReading: String?
    let exampleEnglish: String?
    let scenario: String?

    func toDomain(
        lessonId: UUID,
        pageId: UUID?,
        pageCode: String?,
        category: String?
    ) -> GrammarItem {
        let example = DailyLifeExample(
            japanese: exampleJapanese ?? pattern,
            reading: exampleReading ?? "",
            english: exampleEnglish ?? meaning,
            scenario: scenario ?? "Daily use"
        )
        return GrammarItem(
            pattern: pattern,
            meaning: meaning,
            formation: formation,
            explanation: explanation,
            jlptLevel: jlptLevel,
            isNewGrammar: true,
            examples: [example],
            lessonId: lessonId,
            pageId: pageId,
            pageCode: pageCode,
            category: category
        )
    }
}
