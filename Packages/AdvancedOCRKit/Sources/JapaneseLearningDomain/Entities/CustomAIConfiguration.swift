import Foundation

public struct CustomAIConfiguration: Codable, Sendable, Equatable {
    public var endpoint: String
    public var apiKey: String
    public var selectedModel: String

    public init(
        endpoint: String = "http://localhost:11434/v1",
        apiKey: String = "",
        selectedModel: String = ""
    ) {
        self.endpoint = endpoint
        self.apiKey = apiKey
        self.selectedModel = selectedModel
    }

    public static let standardStorageKey: String = "custom_local_ai_config"

    public static func loadFromDefaults() -> CustomAIConfiguration {
        guard let data = UserDefaults.standard.data(forKey: standardStorageKey),
              let config = try? JSONDecoder().decode(CustomAIConfiguration.self, from: data) else {
            return CustomAIConfiguration()
        }
        return config
    }

    public func saveToDefaults() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.standardStorageKey)
    }
}
