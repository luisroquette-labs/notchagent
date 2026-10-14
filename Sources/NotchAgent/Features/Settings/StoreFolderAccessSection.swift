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
    @State private var language = SetupLanguage.current
    @State private var inspections: [StoreDataFolder: StoreFolderReadiness] = [:]
    @State private var inspectionIDs: [StoreDataFolder: UUID] = [:]
    @State private var message: String?

    var body: some View {
        Section {
            Button(language.text("Abrir configuração guiada…", "Open guided setup…", "Abrir configuración guiada…")) {
                AppEnvironment.shared.router.openStoreOnboarding()
            }
            folderRow(.claudeCode)
            folderRow(.claudeDesktop)
            folderRow(.codex)
            if let message {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
        } header: {
            Text(language.text("Pastas autorizadas", "Authorized folders", "Carpetas autorizadas"))
        } footer: {
            Text(language.text(
                "A Mac App Store exige que você escolha cada pasta. O acesso é somente leitura e pode ser revogado aqui.",
                "The Mac App Store requires you to choose each folder. Access is read-only and can be revoked here.",
                "La Mac App Store exige que elijas cada carpeta. El acceso es de solo lectura y puedes revocarlo aquí."
            ))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear { language = .current; inspectAuthorizedFolders() }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            language = .current
            inspectAuthorizedFolders()
        }
    }

    @ViewBuilder
    private func folderRow(_ folder: StoreDataFolder) -> some View {
        let selected = SandboxBookmarkStore.shared.selectedRoot(for: folder)
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title(folder))
                Text(selected == nil
                    ? language.text("Acesso necessário", "Access required", "Acceso necesario")
                    : (inspections[folder] ?? .checking).message(language))
                    .font(.caption)
                    .foregroundStyle(selected == nil ? .orange : .secondary)
            }
            Spacer()
            if selected == nil {
                Button(language.text("Conectar", "Connect", "Conectar")) { authorize(folder) }
            } else {
                Menu(language.text("Gerenciar", "Manage", "Gestionar")) {
                    Button(language.text("Atualizar", "Refresh", "Actualizar")) { inspect(folder) }
                    Button(language.text("Escolher outra pasta", "Choose another folder", "Elegir otra carpeta")) { authorize(folder) }
                    Divider()
                    Button(language.text("Revogar", "Revoke", "Revocar"), role: .destructive) {
                        SandboxBookmarkStore.shared.revoke(folder)
                        inspections[folder] = nil
                        inspectionIDs[folder] = nil
                        AppEnvironment.shared.scheduler.refreshNow()
                        message = language.text("Acesso revogado.", "Access revoked.", "Acceso revocado.")
                    }
                }
            }
        }
    }

    private func authorize(_ folder: StoreDataFolder) {
        do {
            guard try StoreFolderPicker.choose(folder, portuguese: language == .pt, spanish: language == .es) else { return }
            AppEnvironment.shared.scheduler.refreshNow()
            inspect(folder)
            message = nil
        } catch {
            message = language.text(
                "Não foi possível usar essa pasta. Escolha \(folder.expectedFolderName) e tente novamente.",
                "Could not use that folder. Choose \(folder.expectedFolderName) and try again.",
                "No se pudo usar esa carpeta. Elige \(folder.expectedFolderName) e inténtalo de nuevo."
            )
        }
    }

    private func title(_ folder: StoreDataFolder) -> String {
        folder.title(language)
    }

    private func inspectAuthorizedFolders() {
        for folder in StoreDataFolder.allCases where SandboxBookmarkStore.shared.selectedRoot(for: folder) != nil {
            inspect(folder)
        }
    }

    private func inspect(_ folder: StoreDataFolder) {
        guard let root = SandboxBookmarkStore.shared.selectedRoot(for: folder) else { return }
        let id = UUID()
        inspectionIDs[folder] = id
        inspections[folder] = .checking
        Task { @MainActor in
            let result = await Task.detached(priority: .userInitiated) {
                StoreFolderInspector.inspect(folder, root: root)
            }.value
            guard inspectionIDs[folder] == id,
                  SandboxBookmarkStore.shared.selectedRoot(for: folder) == root else { return }
            inspections[folder] = result
        }
    }
}
#endif
