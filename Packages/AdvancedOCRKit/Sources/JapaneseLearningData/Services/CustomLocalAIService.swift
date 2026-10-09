import Foundation
import Core
import JapaneseLearningDomain

public final class CustomLocalAIService: CustomLocalAIServiceProtocol {
    private let session: URLSession
    private let localAI: LocalJapaneseAIProtocol

    public init(
        session: URLSession = .shared,
        localAI: LocalJapaneseAIProtocol = LocalJapaneseAIModel()
    ) {
        self.session = session
        self.localAI = localAI
    }

    public func fetchModels(from endpoint: String, apiKey: String?) async throws -> [String] {
        let cleanEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let baseURL = URL(string: cleanEndpoint) else {
            throw AppError.ocrRecognitionFailed("Invalid endpoint URL")
        }

        let candidateURLs = buildCandidateModelURLs(baseURL: baseURL, original: cleanEndpoint)
        var lastError: Error?

        for url in candidateURLs {
            do {
                let models = try await requestModelList(url: url, apiKey: apiKey)
                if !models.isEmpty {
                    return models
                }
            } catch {
                lastError = error
            }
        }

        throw lastError ?? AppError.ocrRecognitionFailed("Failed to connect to local AI endpoint")
    }

    public func reanalyzePage(
        text: String,
        pageCode: String?,
        category: String?,
        lessonId: UUID,
        config: CustomAIConfiguration
    ) async throws -> ExtractedStudyContent {
        let cleanEndpoint = config.endpoint.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let chatURL = resolveChatURL(endpoint: cleanEndpoint)

        let request = try buildChatRequest(url: chatURL, config: config, text: text)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw AppError.ocrRecognitionFailed("Custom AI model server returned an error")
        }

        let content = try parseChatResponse(data: data)
        let rawStudy = try decodeStudyContent(from: content)

        let vocabCandidates = rawStudy.vocabulary.map {
            $0.toDomain(lessonId: lessonId, pageCode: pageCode, category: category)
        }
        let grammarItems = rawStudy.grammar.map {
            $0.toDomain(lessonId: lessonId, pageCode: pageCode, category: category)
        }

        let verifiedVocab = await localAI.verifyVocabulary(candidates: vocabCandidates, contextText: text)
        return ExtractedStudyContent(vocabulary: verifiedVocab, grammar: grammarItems)
    }

    private func buildCandidateModelURLs(baseURL: URL, original: String) -> [URL] {
        var urls: [URL] = []
        if original.hasSuffix("/v1") {
            urls.append(baseURL.appendingPathComponent("models"))
            if let root = URL(string: original.replacingOccurrences(of: "/v1", with: "")) {
                urls.append(root.appendingPathComponent("models"))
                urls.append(root.appendingPathComponent("api/tags"))
            }
        } else {
            urls.append(baseURL.appendingPathComponent("v1/models"))
            urls.append(baseURL.appendingPathComponent("models"))
            urls.append(baseURL.appendingPathComponent("api/tags"))
        }
        return urls
    }

    private func requestModelList(url: URL, apiKey: String?) async throws -> [String] {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 8
        applyAuthHeader(to: &request, apiKey: apiKey)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw AppError.ocrRecognitionFailed("HTTP error querying models")
        }

        return parseModelIDs(data: data)
    }

    private func parseModelIDs(data: Data) -> [String] {
        if let root = try? JSONDecoder().decode(OpenAIModelsDTO.self, from: data), let dataList = root.data {
            return dataList.map(\.id).filter { !$0.isEmpty }.sorted()
        }
        if let ollamaRoot = try? JSONDecoder().decode(OllamaTagsDTO.self, from: data), let models = ollamaRoot.models {
            return models.map(\.name).filter { !$0.isEmpty }.sorted()
        }
        return []
    }

    private func resolveChatURL(endpoint: String) -> URL {
        if endpoint.hasSuffix("/v1") {
            return URL(string: "\(endpoint)/chat/completions")!
        }
        return URL(string: "\(endpoint)/v1/chat/completions") ?? URL(string: "\(endpoint)/chat/completions")!
    }

    private func buildChatRequest(url: URL, config: CustomAIConfiguration, text: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        applyAuthHeader(to: &request, apiKey: config.apiKey)

        let prompt = """
        Analyze this Japanese lesson text and extract important vocabulary words and grammar patterns.
        Include romaji and english translations for both vocabulary and examples.
        Output ONLY valid JSON matching this exact format:
        {
          "vocabulary": [
            {
              "word": "勉強",
              "reading": "べんきょう",
              "romaji": "benkyou",
              "meaning": "study",
              "partOfSpeech": "名詞",
              "exampleJapanese": "毎日勉強します。",
              "exampleReading": "まいにち べんきょう します。",
              "exampleRomaji": "mainichi benkyou shimasu.",
              "exampleEnglish": "I study every day.",
              "scenario": "日常練習"
            }
          ],
          "grammar": [
            {
              "pattern": "〜てください",
              "meaning": "Please do",
              "formation": "動詞て形 ＋ ください",
              "explanation": "丁寧にお願いする表現",
              "jlptLevel": "N5",
              "exampleJapanese": "本を読んでください。",
              "exampleReading": "ほんを よんで ください。",
              "exampleRomaji": "hon wo yonde kudasai.",
              "exampleEnglish": "Please read the book.",
              "scenario": "日常会話"
            }
          ]
        }
        Lesson text:
        \(text)
        """

        let payload: [String: Any] = [
            "model": config.selectedModel,
            "messages": [
                ["role": "system", "content": "You are a Japanese language analysis assistant. You respond only with valid JSON containing vocabulary, grammar, readings, romaji, and english translations."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.2
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        return request
    }

    private func applyAuthHeader(to request: inout URLRequest, apiKey: String?) {
        guard let apiKey = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines), !apiKey.isEmpty else { return }
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    }

    private func parseChatResponse(data: Data) throws -> String {
        let chatDTO = try JSONDecoder().decode(OpenAIChatResponseDTO.self, from: data)
        guard let content = chatDTO.choices?.first?.message?.content else {
            throw AppError.ocrRecognitionFailed("No response content from custom AI")
        }
        return extractJSONString(from: content)
    }

    private func extractJSONString(from text: String) -> String {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("```json") {
            trimmed = String(trimmed.dropFirst(7))
        } else if trimmed.hasPrefix("```") {
            trimmed = String(trimmed.dropFirst(3))
        }
        if trimmed.hasSuffix("```") {
            trimmed = String(trimmed.dropLast(3))
        }
        return trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func decodeStudyContent(from jsonString: String) throws -> CustomStudyContentDTO {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AppError.ocrRecognitionFailed("Invalid JSON encoding")
        }
        return try JSONDecoder().decode(CustomStudyContentDTO.self, from: jsonData)
    }
}

// MARK: - Internal DTOs

struct OpenAIModelsDTO: Codable {
    let data: [OpenAIModelEntryDTO]?
}

struct OpenAIModelEntryDTO: Codable {
    let id: String
}

struct OllamaTagsDTO: Codable {
    let models: [OllamaModelEntryDTO]?
}

struct OllamaModelEntryDTO: Codable {
    let name: String
}

struct OpenAIChatResponseDTO: Codable {
    let choices: [OpenAIChatChoiceDTO]?
}

struct OpenAIChatChoiceDTO: Codable {
    let message: OpenAIChatMessageDTO?
}

struct OpenAIChatMessageDTO: Codable {
    let content: String?
}

struct CustomStudyContentDTO: Codable {
    let vocabulary: [CustomVocabDTO]
    let grammar: [CustomGrammarDTO]
}

struct CustomVocabDTO: Codable {
    let word: String
    let reading: String?
    let romaji: String?
    let meaning: String?
    let partOfSpeech: String?
    let exampleJapanese: String?
    let exampleReading: String?
    let exampleRomaji: String?
    let exampleEnglish: String?
    let scenario: String?

    func toDomain(lessonId: UUID, pageCode: String?, category: String?) -> VocabularyItem {
        let cleanWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanReading = reading?.trimmingCharacters(in: .whitespacesAndNewlines) ?? cleanWord
        let cleanRomaji = romaji?.trimmingCharacters(in: .whitespacesAndNewlines) ?? JapaneseRomajiConverter.toRomaji(from: cleanReading)
        let cleanMeaning = meaning?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let cleanPOS = partOfSpeech?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "語彙"
        let exJap = exampleJapanese ?? "\(cleanWord)を使います。"
        let exReading = exampleReading ?? cleanReading
        let exRomaji = exampleRomaji ?? JapaneseRomajiConverter.toRomaji(from: exReading)
        let exEng = exampleEnglish ?? "Example using \(cleanWord)"
        let example = DailyLifeExample(
            japanese: exJap,
            reading: exReading,
            romaji: exRomaji,
            english: exEng,
            scenario: scenario ?? "日常生活"
        )

        return VocabularyItem(
            word: cleanWord,
            reading: cleanReading,
            romaji: cleanRomaji,
            meaning: cleanMeaning,
            partOfSpeech: cleanPOS,
            isNewWord: true,
            examples: [example],
            firstLessonId: lessonId,
            pageCode: pageCode,
            category: category
        )
    }
}

struct CustomGrammarDTO: Codable {
    let pattern: String
    let meaning: String?
    let formation: String?
    let explanation: String?
    let jlptLevel: String?
    let exampleJapanese: String?
    let exampleReading: String?
    let exampleRomaji: String?
    let exampleEnglish: String?
    let scenario: String?

    func toDomain(lessonId: UUID, pageCode: String?, category: String?) -> GrammarItem {
        let cleanPattern = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanMeaning = meaning?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let exJap = exampleJapanese ?? cleanPattern
        let exReading = exampleReading ?? ""
        let exRomaji = exampleRomaji ?? JapaneseRomajiConverter.toRomaji(from: exReading.isEmpty ? exJap : exReading)
        let exEng = exampleEnglish ?? "Example using \(cleanPattern)"
        let example = DailyLifeExample(
            japanese: exJap,
            reading: exReading,
            romaji: exRomaji,
            english: exEng,
            scenario: scenario ?? "文法練習"
        )

        return GrammarItem(
            pattern: cleanPattern,
            meaning: cleanMeaning,
            formation: formation ?? "",
            explanation: explanation ?? "",
            jlptLevel: jlptLevel,
            isNewGrammar: true,
            examples: [example],
            lessonId: lessonId,
            pageCode: pageCode,
            category: category
        )
    }
}

