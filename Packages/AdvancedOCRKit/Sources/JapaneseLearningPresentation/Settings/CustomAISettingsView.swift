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

    private let service: CustomLocalAIServiceProtocol
    private let onSaved: ((CustomAIConfiguration) -> Void)?

    public init(
        initialConfig: CustomAIConfiguration = CustomAIConfiguration.loadFromDefaults(),
        service: CustomLocalAIServiceProtocol = CustomLocalAIService(),
        onSaved: ((CustomAIConfiguration) -> Void)? = nil
    ) {
        self._endpoint = State(initialValue: initialConfig.endpoint)
        self._apiKey = State(initialValue: initialConfig.apiKey)
        self._selectedModel = State(initialValue: initialConfig.selectedModel)
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
            .navigationTitle("ローカルAIサーバー設定")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
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
        Section(header: Text("サーバー接続先")) {
            TextField("エンドポイントURL", text: $endpoint)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                #endif
            SecureField("APIキー (任意)", text: $apiKey)
        }
    }

    private var presetsSection: some View {
        Section(header: Text("プリセット")) {
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
        Section(header: Text("モデル")) {
            Button(action: { Task { await fetchModels() } }) {
                HStack {
                    Label(isLoadingModels ? "モデル取得中..." : "モデル一覧を取得", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    if isLoadingModels {
                        ProgressView()
                    }
                }
            }
            .disabled(isLoadingModels || endpoint.isEmpty)

            if !availableModels.isEmpty {
                Picker("使用モデル", selection: $selectedModel) {
                    ForEach(availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
            } else if !selectedModel.isEmpty {
                Text("現在: \(selectedModel)")
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
        ToolbarItem(placement: .cancellationAction) {
            Button("閉じる") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("保存") { saveSettings() }
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
            statusMessage = "\(fetched.count)個のモデルを検出しました"
            isError = false
        } catch {
            statusMessage = "接続失敗: サーバーURLを確認してください"
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
        dismiss()
    }
}
