import SwiftUI

struct SettingsView: View {
    let onSave: () -> Void

    @State private var apiKey: String = ""
    @State private var showSaveSuccess = false
    @State private var showDeleteConfirm = false

    private let apiService = MiniMaxAPIService()

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()

            formSection
            Divider()

            footerView
        }
        .frame(width: 280, height: 220)
        .onAppear {
            apiKey = apiService.getAPIKey() ?? ""
        }
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "gear")
                .foregroundColor(.blue)
            Text("设置")
                .font(.headline)
            Spacer()
        }
        .padding()
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("API Key")
                .font(.caption)
                .foregroundColor(.secondary)

            SecureField("输入你的 MiniMax API Key", text: $apiKey)
                .textFieldStyle(.roundedBorder)

            if showSaveSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("保存成功")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Button(action: saveAPIKey) {
                Text("保存")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(apiKey.isEmpty)

            if apiService.getAPIKey() != nil {
                Button(action: { showDeleteConfirm = true }) {
                    Text("删除 API Key")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
                .alert("确认删除", isPresented: $showDeleteConfirm) {
                    Button("取消", role: .cancel) { }
                    Button("删除", role: .destructive) {
                        deleteAPIKey()
                    }
                } message: {
                    Text("确定要删除保存的 API Key 吗？")
                }
            }
        }
        .padding()
    }

    private var footerView: some View {
        HStack {
            Text("API Key 将安全存储在 Keychain 中")
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal)
    }

    private func saveAPIKey() {
        if apiService.saveAPIKey(apiKey) {
            showSaveSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showSaveSuccess = false
                onSave()
            }
        }
    }

    private func deleteAPIKey() {
        if apiService.deleteAPIKey() {
            apiKey = ""
            onSave()
        }
    }
}
