#if APP_STORE
import AppKit
import SwiftUI

enum StoreFolderPicker {
    @MainActor
    static func choose(_ folder: StoreDataFolder, portuguese: Bool, spanish: Bool = false) throws -> Bool {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = true
        panel.prompt = portuguese ? "Autorizar" : spanish ? "Autorizar" : "Authorize"
        panel.message = portuguese
            ? "Selecione a pasta \(folder.expectedFolderName) e clique em Autorizar."
            : spanish
                ? "Elige la carpeta \(folder.expectedFolderName) y haz clic en Autorizar."
                : "Select the \(folder.expectedFolderName) folder, then click Authorize."
        if let home = FileManager.default.homeDirectory(forUser: NSUserName()) {
            panel.directoryURL = folder.suggestedRoot(in: home).deletingLastPathComponent()
            panel.nameFieldStringValue = folder.expectedFolderName
        }
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        try SandboxBookmarkStore.shared.grant(folder, selectedRoot: url)
        guard SandboxBookmarkStore.shared.selectedRoot(for: folder) != nil else {
            throw SandboxBookmarkError.accessDenied
        }
        return true
    }
}

struct StoreFolderAccessSection: View {
    let portuguese: Bool
    @State private var message: String?
    @State private var revision = 0

    var body: some View {
        Section {
            Button(portuguese ? "Abrir configuração guiada…" : "Open guided setup…") {
                AppEnvironment.shared.router.openStoreOnboarding()
            }
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
                Button(portuguese ? "Conectar" : "Connect") { authorize(folder) }
            } else {
                Button(portuguese ? "Revogar" : "Revoke") {
                    SandboxBookmarkStore.shared.revoke(folder)
                    AppEnvironment.shared.scheduler.refreshNow()
                    message = portuguese ? "Acesso revogado." : "Access revoked."
                    revision += 1
                }
            }
        }
    }

    private func authorize(_ folder: StoreDataFolder) {
        do {
            guard try StoreFolderPicker.choose(folder, portuguese: portuguese) else { return }
            AppEnvironment.shared.scheduler.refreshNow()
            message = portuguese ? "Pasta autorizada." : "Folder authorized."
            revision += 1
        } catch {
            message = error.localizedDescription
        }
    }

    private func title(_ folder: StoreDataFolder) -> String {
        switch folder {
        case .claudeCode: "Claude Code"
        case .claudeDesktop: portuguese ? "Claude Desktop (opcional)" : "Claude Desktop (optional)"
        case .codex: "Codex"
        }
    }
}
#endif
