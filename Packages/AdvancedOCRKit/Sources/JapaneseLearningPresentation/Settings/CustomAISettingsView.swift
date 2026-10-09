import SwiftUI
import JapaneseLearningDomain
import JapaneseLearningData

public struct CustomAISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var endpoint: String
    @State private var apiKey: String
    @State private var selectedModel: String
    @State private var availableModels: [String] = []
    @State private var isLoadingModels: Bool = false
    @State private var statusMessage: String?
    @State private var isError: Bool = false

    private let isModal: Bool
    private let service: CustomLocalAIServiceProtocol
    private let onSaved: ((CustomAIConfiguration) -> Void)?

    public init(
        initialConfig: CustomAIConfiguration = CustomAIConfiguration.loadFromDefaults(),
        isModal: Bool = false,
        service: CustomLocalAIServiceProtocol = CustomLocalAIService(),
        onSaved: ((CustomAIConfiguration) -> Void)? = nil
    ) {
        self._endpoint = State(initialValue: initialConfig.endpoint)
        self._apiKey = State(initialValue: initialConfig.apiKey)
        self._selectedModel = State(initialValue: initialConfig.selectedModel)
        self.isModal = isModal
        self.service = service
        self.onSaved = onSaved
    }

    public var body: some View {
        NavigationStack {
            Form {
                endpointSection
                presetsSection
                modelSection
                statusSection
            }
            .navigationTitle("Local AI Server Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(isModal ? .inline : .automatic)
            #endif
            .toolbar { toolbarContent }
            .task {
                if !endpoint.isEmpty && availableModels.isEmpty {
                    await fetchModels()
                }
            }
        }
    }

    private var endpointSection: some View {
        Section(header: Text("Server Endpoint")) {
            TextField("Endpoint URL", text: $endpoint)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                #endif
            SecureField("API Key (Optional)", text: $apiKey)
        }
    }

    private var presetsSection: some View {
        Section(header: Text("Presets")) {
            HStack(spacing: 8) {
                Button("Ollama (11434)") {
                    endpoint = "http://localhost:11434/v1"
                }
                .buttonStyle(.bordered)
                .font(.caption)

                Button("LM Studio (1234)") {
                    endpoint = "http://localhost:1234/v1"
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
        }
    }

    private var modelSection: some View {
        Section(header: Text("Model")) {
            Button(action: { Task { await fetchModels() } }) {
                HStack {
                    Label(isLoadingModels ? "Fetching Models..." : "Fetch Models", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    if isLoadingModels {
                        ProgressView()
                    }
                }
            }
            .disabled(isLoadingModels || endpoint.isEmpty)

            if !availableModels.isEmpty {
                Picker("Selected Model", selection: $selectedModel) {
                    ForEach(availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
            } else if !selectedModel.isEmpty {
                Text("Current: \(selectedModel)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        if let statusMessage {
            Section {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(isError ? .red : .green)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isModal {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") { saveSettings() }
                .fontWeight(.bold)
        }
    }

    private func fetchModels() async {
        isLoadingModels = true
        statusMessage = nil
        isError = false

        do {
            let fetched = try await service.fetchModels(from: endpoint, apiKey: apiKey.isEmpty ? nil : apiKey)
            availableModels = fetched
            if selectedModel.isEmpty || !fetched.contains(selectedModel) {
                selectedModel = fetched.first ?? ""
            }
            statusMessage = "Found \(fetched.count) models"
            isError = false
        } catch {
            statusMessage = "Connection failed: Please check server URL"
            isError = true
        }

        isLoadingModels = false
    }

    private func saveSettings() {
        let config = CustomAIConfiguration(
            endpoint: endpoint,
            apiKey: apiKey,
            selectedModel: selectedModel
        )
        config.saveToDefaults()
        onSaved?(config)
        if isModal {
            dismiss()
        } else {
            statusMessage = "Settings saved successfully ✓"
            isError = false
        }
    }
}
