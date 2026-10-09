import Foundation

public protocol CustomLocalAIServiceProtocol: Sendable {
    func fetchModels(from endpoint: String, apiKey: String?) async throws -> [String]
    func reanalyzePage(
        text: String,
        pageCode: String?,
        category: String?,
        lessonId: UUID,
        config: CustomAIConfiguration
    ) async throws -> ExtractedStudyContent
}
