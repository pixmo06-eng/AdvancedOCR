import SwiftUI
import JapaneseLearningDomain
import JapaneseLearningData

public struct CustomAISettingsView: View {
    private let isModal: Bool
    private let service: CustomLocalAIServiceProtocol
    private let onSaved: ((CustomAIConfiguration) -> Void)?

    public init(
        initialConfig: CustomAIConfiguration = CustomAIConfiguration.loadFromDefaults(),
        isModal: Bool = false,
        service: CustomLocalAIServiceProtocol = CustomLocalAIService(),
        onSaved: ((CustomAIConfiguration) -> Void)? = nil
    ) {
        self.isModal = isModal
        self.service = service
        self.onSaved = onSaved
    }

    public var body: some View {
        SettingsView(
            isModal: isModal,
            service: service,
            onSaved: onSaved
        )
    }
}
