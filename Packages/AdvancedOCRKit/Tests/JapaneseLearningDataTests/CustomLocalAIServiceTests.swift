import XCTest
@testable import JapaneseLearningDomain
@testable import JapaneseLearningData

final class CustomLocalAIServiceTests: XCTestCase {
    func testOpenAIModelParsing() throws {
        let json = """
        {
          "data": [
            {"id": "qwen2.5:7b"},
            {"id": "llama3.2:3b"}
          ]
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let decoded = try JSONDecoder().decode(OpenAIModelsDTO.self, from: data)
        let ids = decoded.data?.map(\.id) ?? []

        XCTAssertEqual(ids.count, 2)
        XCTAssertTrue(ids.contains("qwen2.5:7b"))
        XCTAssertTrue(ids.contains("llama3.2:3b"))
    }

    func testOllamaTagsParsing() throws {
        let json = """
        {
          "models": [
            {"name": "mistral-nemo"},
            {"name": "gemma2:9b"}
          ]
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let decoded = try JSONDecoder().decode(OllamaTagsDTO.self, from: data)
        let names = decoded.models?.map(\.name) ?? []

        XCTAssertEqual(names.count, 2)
        XCTAssertTrue(names.contains("mistral-nemo"))
        XCTAssertTrue(names.contains("gemma2:9b"))
    }

    func testStudyContentDTO_omitsEnglishAndMapsCorrectly() throws {
        let json = """
        {
          "vocabulary": [
            {
              "word": "漢字",
              "reading": "かんじ",
              "meaning": "Chinese characters",
              "partOfSpeech": "名詞",
              "exampleJapanese": "漢字を毎日練習します。",
              "exampleReading": "かんじを まいにち れんしゅう します。",
              "scenario": "Daily Life"
            }
          ],
          "grammar": [
            {
              "pattern": "〜てください",
              "meaning": "Please do",
              "formation": "動詞て形＋ください",
              "explanation": "丁寧な依頼",
              "jlptLevel": "N5",
              "exampleJapanese": "ここを読んでください。",
              "exampleReading": "ここを よんで ください。",
              "scenario": "Conversation"
            }
          ]
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let dto = try JSONDecoder().decode(CustomStudyContentDTO.self, from: data)

        let vocab = dto.vocabulary.map { $0.toDomain(lessonId: UUID(), pageCode: "A 1a", category: "Kanji 1") }
        let grammar = dto.grammar.map { $0.toDomain(lessonId: UUID(), pageCode: "A 1a", category: "Kanji 1") }

        XCTAssertEqual(vocab.count, 1)
        XCTAssertEqual(vocab.first?.word, "漢字")
        XCTAssertEqual(vocab.first?.meaning, "") // English omitted
        XCTAssertEqual(vocab.first?.examples.first?.english, "") // English omitted
        XCTAssertEqual(vocab.first?.examples.first?.scenario, "日常生活") // Sanitized to Japanese

        XCTAssertEqual(grammar.count, 1)
        XCTAssertEqual(grammar.first?.pattern, "〜てください")
        XCTAssertEqual(grammar.first?.meaning, "") // English omitted
        XCTAssertEqual(grammar.first?.examples.first?.english, "") // English omitted
    }
}
