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
        panel.message = folder == .claudeCode
            ? (portuguese
                ? "Selecione .claude. O NotchAgent ativará a cota oficial no settings.json, preservando suas outras opções."
                : spanish
                    ? "Elige .claude. NotchAgent activará la cuota oficial en settings.json y conservará las demás opciones."
                    : "Select .claude. NotchAgent will enable official quota in settings.json and preserve your other settings.")
            : (portuguese
                ? "Selecione a pasta \(folder.expectedFolderName) e clique em Autorizar."
                : spanish
                    ? "Elige la carpeta \(folder.expectedFolderName) y haz clic en Autorizar."
                    : "Select the \(folder.expectedFolderName) folder, then click Authorize.")
        if let home = FileManager.default.homeDirectory(forUser: NSUserName()) {
            panel.directoryURL = folder.suggestedRoot(in: home).deletingLastPathComponent()
            panel.nameFieldStringValue = folder.expectedFolderName
        }
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        try SandboxBookmarkStore.shared.grant(folder, selectedRoot: url)
        guard SandboxBookmarkStore.shared.selectedRoot(for: folder) != nil else {
            throw SandboxBookmarkError.accessDenied
        }
        if folder == .claudeCode {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                try ClaudeStatuslineSetup.install(root: url)
            } catch ClaudeStatuslineSetupError.existingStatusline {
                let alert = NSAlert()
                alert.messageText = portuguese ? "Barra do Claude Code já configurada" : spanish
                    ? "La barra de Claude Code ya está configurada"
                    : "Claude Code status line is already configured"
                alert.informativeText = portuguese
                    ? "Para mostrar a cota no NotchAgent, substitua apenas a barra atual. As outras opções do Claude serão mantidas."
                    : spanish
                        ? "Para mostrar la cuota en NotchAgent, reemplaza solo la barra actual. Las demás opciones de Claude se conservarán."
                        : "To show quota in NotchAgent, replace only the current status line. Your other Claude settings will be kept."
                alert.addButton(withTitle: portuguese ? "Substituir e ativar" : spanish ? "Reemplazar y activar" : "Replace and enable")
                alert.addButton(withTitle: portuguese ? "Manter atual" : spanish ? "Conservar la actual" : "Keep current")
                guard alert.runModal() == .alertFirstButtonReturn else {
                    throw ClaudeStatuslineSetupError.existingStatusline
                }
                try ClaudeStatuslineSetup.install(root: url, replaceExisting: true)
            }
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
                "Você escolhe cada pasta. O acesso salvo é somente leitura; ao conectar Claude Code, o app ativa a cota em settings.json. Revogue o acesso aqui.",
                "You choose each folder. Saved access is read-only; connecting Claude Code enables quota in settings.json. Revoke access here.",
                "Eliges cada carpeta. El acceso guardado es de solo lectura; al conectar Claude Code se activa la cuota en settings.json. Revoca el acceso aquí."
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
                if folder == .claudeCode, let selected {
                    Text(ClaudeStatuslineSetup.isInstalled(root: selected)
                        ? language.text("Cota oficial ativada", "Official quota enabled", "Cuota oficial activada")
                        : language.text("Cota ainda não ativada", "Quota not enabled yet", "Cuota aún no activada"))
                        .font(.caption)
                        .foregroundStyle(ClaudeStatuslineSetup.isInstalled(root: selected) ? .green : .orange)
                }
            }
            Spacer()
            if selected == nil {
                Button(language.text("Conectar", "Connect", "Conectar")) { authorize(folder) }
            } else {
                Menu(language.text("Gerenciar", "Manage", "Gestionar")) {
                    Button(language.text("Atualizar", "Refresh", "Actualizar")) { inspect(folder) }
                    Button(folder == .claudeCode && selected.map { !ClaudeStatuslineSetup.isInstalled(root: $0) } == true
                        ? language.text("Reativar cota…", "Enable quota again…", "Reactivar cuota…")
                        : language.text("Escolher outra pasta", "Choose another folder", "Elegir otra carpeta")) { authorize(folder) }
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
            message = error is ClaudeStatuslineSetupError ? language.text(
                "Pasta conectada, mas a cota não foi ativada. Confira settings.json ou tente Reativar cota; suas outras opções foram preservadas.",
                "Folder connected, but quota was not enabled. Check settings.json or choose Enable quota again; your other settings were preserved.",
                "Carpeta conectada, pero no se activó la cuota. Revisa settings.json o elige Reactivar cuota; las demás opciones se conservaron."
            ) : language.text(
                "Não foi possível usar essa pasta. Escolha \(folder.expectedFolderName) e tente novamente.",
                "Could not use that folder. Choose \(folder.expectedFolderName) and try again.",
                "No se pudo usar esa carpeta. Elige \(folder.expectedFolderName) e inténtalo de nuevo."
            )
            inspect(folder)
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
