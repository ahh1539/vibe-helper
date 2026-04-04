import SwiftUI

struct ModelEditorView: View {
    let model: VibeModel
    @ObservedObject var store: ConfigStore
    @Environment(\.dismiss) private var dismiss

    @State private var alias: String = ""
    @State private var provider: String = ""
    @State private var temperature: Double = 0.0
    @State private var inputPrice: String = ""
    @State private var outputPrice: String = ""
    @State private var thinking: String = "off"
    @State private var autoCompactThreshold: String = ""
    @State private var errorMessage: String? = nil
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Model")
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Read-only name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(model.name)
                            .font(.body.weight(.medium))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primary.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Alias")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Model alias", text: $alias)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Provider")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $provider) {
                            ForEach(store.providers) { p in
                                Text(p.name).tag(p.name)
                            }
                        }
                        .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Temperature")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.2f", temperature))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.vibePrimary)
                        }
                        Slider(value: $temperature, in: 0...1, step: 0.05)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Thinking Mode")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $thinking) {
                            Text("Off").tag("off")
                            Text("Low").tag("low")
                            Text("High").tag("high")
                        }
                        .pickerStyle(.segmented)
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Input Price ($/M tokens)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("0.0", text: $inputPrice)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Output Price ($/M tokens)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("0.0", text: $outputPrice)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto Compact Threshold")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("175000", text: $autoCompactThreshold)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding()
            }

            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.vibeDanger)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.vibeDanger)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Divider()

            HStack {
                Text("A backup will be created before saving")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(isSaving)
            }
            .padding()
        }
        .frame(minWidth: 480, minHeight: 500)
        .onAppear {
            alias = model.alias
            provider = model.provider
            temperature = model.temperature
            inputPrice = String(model.inputPrice)
            outputPrice = String(model.outputPrice)
            thinking = model.thinking
            autoCompactThreshold = String(model.autoCompactThreshold)
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil

        guard let inPrice = Double(inputPrice) else {
            errorMessage = "Input price must be a number"
            isSaving = false
            return
        }
        guard let outPrice = Double(outputPrice) else {
            errorMessage = "Output price must be a number"
            isSaving = false
            return
        }
        guard let threshold = Int(autoCompactThreshold) else {
            errorMessage = "Auto compact threshold must be a whole number"
            isSaving = false
            return
        }

        let updated = VibeModel(
            name: model.name,
            provider: provider,
            alias: alias,
            temperature: temperature,
            inputPrice: inPrice,
            outputPrice: outPrice,
            thinking: thinking,
            autoCompactThreshold: threshold
        )

        do {
            try store.updateModel(updated)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }
}

struct ProviderEditorView: View {
    let provider: VibeProvider
    @ObservedObject var store: ConfigStore
    @Environment(\.dismiss) private var dismiss

    @State private var apiBase: String = ""
    @State private var apiKeyEnvVar: String = ""
    @State private var apiStyle: String = "openai"
    @State private var backend: String = "generic"
    @State private var reasoningFieldName: String = ""
    @State private var errorMessage: String? = nil
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Edit Provider")
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Provider Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(provider.name)
                            .font(.body.weight(.medium))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primary.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Base URL")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("https://api.example.com/v1", text: $apiBase)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key Environment Variable")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("API_KEY_ENV_VAR", text: $apiKeyEnvVar)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Style")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $apiStyle) {
                            Text("OpenAI").tag("openai")
                            Text("Reasoning").tag("reasoning")
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Backend")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $backend) {
                            Text("Mistral").tag("mistral")
                            Text("Generic").tag("generic")
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reasoning Field Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("reasoning_content", text: $reasoningFieldName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding()
            }

            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.vibeDanger)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.vibeDanger)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Divider()

            HStack {
                Text("A backup will be created before saving")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(isSaving)
            }
            .padding()
        }
        .frame(minWidth: 450, minHeight: 400)
        .onAppear {
            apiBase = provider.apiBase
            apiKeyEnvVar = provider.apiKeyEnvVar
            apiStyle = provider.apiStyle
            backend = provider.backend
            reasoningFieldName = provider.reasoningFieldName
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil

        let updated = VibeProvider(
            name: provider.name,
            apiBase: apiBase,
            apiKeyEnvVar: apiKeyEnvVar,
            apiStyle: apiStyle,
            backend: backend,
            reasoningFieldName: reasoningFieldName,
            projectId: provider.projectId,
            region: provider.region
        )

        do {
            try store.updateProvider(updated)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }
}
