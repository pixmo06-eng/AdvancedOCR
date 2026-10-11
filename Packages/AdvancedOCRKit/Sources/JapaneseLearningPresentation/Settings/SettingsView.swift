import SwiftUI
import JapaneseLearningDomain
import JapaneseLearningData

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var useCustomAI: Bool
    @State private var endpoint: String
    @State private var apiKey: String
    @State private var selectedModel: String
    @State private var availableModels: [String] = []
    @State private var autoSplitSpreads: Bool
    @State private var isLoadingModels: Bool = false
    @State private var statusMessage: String?
    @State private var isError: Bool = false

    private let isModal: Bool
    private let service: CustomLocalAIServiceProtocol
    private let onSaved: ((CustomAIConfiguration) -> Void)?

    public init(
        isModal: Bool = false,
        service: CustomLocalAIServiceProtocol = CustomLocalAIService(),
        onSaved: ((CustomAIConfiguration) -> Void)? = nil
    ) {
        let config = CustomAIConfiguration.loadFromDefaults()
        self._useCustomAI = State(initialValue: UserDefaults.standard.bool(forKey: "use_custom_local_ai"))
        self._endpoint = State(initialValue: config.endpoint)
        self._apiKey = State(initialValue: config.apiKey)
        self._selectedModel = State(initialValue: config.selectedModel)
        let autoSplit = UserDefaults.standard.object(forKey: "auto_split_two_page_spreads") as? Bool ?? true
        self._autoSplitSpreads = State(initialValue: autoSplit)
        self.isModal = isModal
        self.service = service
        self.onSaved = onSaved
    }

    public var body: some View {
        NavigationStack {
            Form {
                aiEngineSection
                if useCustomAI {
                    serverConfigSection
                    presetsSection
                    modelSection
                }
                scanningSection
                statusSection
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(isModal ? .inline : .automatic)
            #endif
            .toolbar { toolbarContent }
            .task {
                if useCustomAI && !endpoint.isEmpty && availableModels.isEmpty {
                    await fetchModels()
                }
            }
        }
    }

    private var aiEngineSection: some View {
        Section(
            header: Text("AI Analysis Engine"),
            footer: Text(useCustomAI ? "Analysis will be processed by your local LLM server." : "Analysis runs directly on-device using Apple NaturalLanguage frameworks.")
        ) {
            Toggle("Use Custom Local AI Server", isOn: $useCustomAI)
                .tint(.purple)
        }
    }

    private var serverConfigSection: some View {
        Section(header: Text("Server Configuration")) {
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
        Section(header: Text("Quick Presets")) {
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
        Section(header: Text("Model Selection")) {
            Button(action: { Task { await fetchModels() } }) {
                HStack {
                    Label(isLoadingModels ? "Fetching Models..." : "Fetch Available Models", systemImage: "arrow.triangle.2.circlepath")
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
                Text("Selected: \(selectedModel)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var scanningSection: some View {
        Section(
            header: Text("Scanning & OCR"),
            footer: Text("Automatically detect and slice horizontal two-page book spreads into two individual pages.")
        ) {
            Toggle("Auto-Split 2-Page Spreads", isOn: $autoSplitSpreads)
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
            Button("Save") { saveAllSettings() }
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
            statusMessage = "Connected: found \(fetched.count) models"
            isError = false
        } catch {
            statusMessage = formatErrorMessage(error)
            isError = true
        }

        isLoadingModels = false
    }

    private func formatErrorMessage(_ error: Error) -> String {
        let nsError = error as NSError
        if nsError.code == -1009 {
            return "Connection failed: Local network access required. Please check Local Network permission for AdvancedOCR in iOS Settings."
        }
        return "Connection failed: \(error.localizedDescription)"
    }

    private func saveAllSettings() {
        UserDefaults.standard.set(useCustomAI, forKey: "use_custom_local_ai")
        UserDefaults.standard.set(autoSplitSpreads, forKey: "auto_split_two_page_spreads")

        let config = CustomAIConfiguration(
            endpoint: endpoint,
            apiKey: apiKey,
            selectedModel: selectedModel
        )
        config.saveToDefaults()
        onSaved?(config)

        if isModal {
            dismiss()
            return
        }
        statusMessage = "Settings saved successfully ✓"
        isError = false
    }
}
