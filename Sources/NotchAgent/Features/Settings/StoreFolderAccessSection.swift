#if APP_STORE
import AppKit
import SwiftUI

struct StoreFolderAccessSection: View {
    let portuguese: Bool
    @State private var message: String?
    @State private var revision = 0

    var body: some View {
        Section {
            folderRow(.claudeCode)
            folderRow(.claudeDesktop)
            folderRow(.codex)
            if let message {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
        } header: {
            Text(portuguese ? "Pastas autorizadas" : "Authorized folders")
        } footer: {
            Text(portuguese
                ? "A Mac App Store exige que você escolha cada pasta. O acesso é somente leitura e pode ser revogado aqui."
                : "The Mac App Store requires you to choose each folder. Access is read-only and can be revoked here.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .id(revision)
    }

    @ViewBuilder
    private func folderRow(_ folder: StoreDataFolder) -> some View {
        let selected = SandboxBookmarkStore.shared.selectedRoot(for: folder)
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title(folder))
                Text(selected == nil
                    ? (portuguese ? "Acesso necessário" : "Access required")
                    : (portuguese ? "Autorizada" : "Authorized"))
                    .font(.caption)
                    .foregroundStyle(selected == nil ? .orange : .secondary)
            }
            Spacer()
            if selected == nil {
                Button(portuguese ? "Escolher…" : "Choose…") { authorize(folder) }
            } else {
                Button(portuguese ? "Revogar" : "Revoke") {
                    SandboxBookmarkStore.shared.revoke(folder)
                    message = portuguese ? "Acesso revogado." : "Access revoked."
                    revision += 1
                }
            }
        }
    }

    private func authorize(_ folder: StoreDataFolder) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = true
        panel.prompt = portuguese ? "Autorizar" : "Authorize"
        panel.message = portuguese
            ? "Escolha a pasta \(folder.expectedFolderName)."
            : "Choose the \(folder.expectedFolderName) folder."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try SandboxBookmarkStore.shared.grant(folder, selectedRoot: url)
            _ = SandboxBookmarkStore.shared.selectedRoot(for: folder)
            message = portuguese ? "Pasta autorizada." : "Folder authorized."
            revision += 1
        } catch {
            message = error.localizedDescription
        }
    }

    private func title(_ folder: StoreDataFolder) -> String {
        switch folder {
        case .claudeCode: "Claude Code — .claude"
        case .claudeDesktop: "Claude Desktop — Claude"
        case .codex: "Codex — .codex"
        }
    }
}
#endif
