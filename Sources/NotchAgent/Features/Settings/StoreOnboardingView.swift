import Foundation

enum StoreOnboardingState {
    static let completedKey = "appStore.guidedSetupCompleted.v1"

    static func shouldPresent(completed: Bool, hasAuthorizedFolder: Bool) -> Bool {
        !completed && !hasAuthorizedFolder
    }
}

enum SetupLanguage: String, CaseIterable, Identifiable {
    case pt, en, es

    static let savedKey = "appStore.setupLanguage"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .pt: "Português"
        case .en: "English"
        case .es: "Español"
        }
    }

    static var system: Self {
        preferred(for: Locale.preferredLanguages.first)
    }

    static var current: Self {
        UserDefaults.standard.string(forKey: savedKey).flatMap(Self.init(rawValue:)) ?? system
    }

    static func preferred(for identifier: String?) -> Self {
        let code = identifier?.prefix(2).lowercased() ?? "en"
        return Self(rawValue: code) ?? .en
    }

    func text(_ pt: String, _ en: String, _ es: String) -> String {
        switch self {
        case .pt: pt
        case .en: en
        case .es: es
        }
    }
}

extension StoreFolderReadiness {
    func message(_ language: SetupLanguage) -> String {
        switch self {
        case .checking:
            return language.text("Verificando sessões…", "Checking sessions…", "Comprobando sesiones…")
        case .missingSessionsFolder:
            return language.text(
                "Pasta conectada · nenhuma sessão local encontrada.",
                "Folder connected · no local sessions found.",
                "Carpeta conectada · no se encontraron sesiones locales."
            )
        case .noRecentSessions:
            return language.text("Pasta conectada · nenhuma sessão nos últimos 8 dias.", "Folder connected · no sessions in the last 8 days.", "Carpeta conectada · sin sesiones en los últimos 8 días.")
        case .noUsageRecords:
            return language.text("Pasta conectada · arquivos sem dados de uso legíveis.", "Folder connected · files have no readable usage data.", "Carpeta conectada · archivos sin datos de uso legibles.")
        case .readFailed:
            return language.text("Não foi possível ler as sessões.", "Could not read sessions.", "No se pudieron leer las sesiones.")
        case let .found(files, verifiedActivity):
            let number = files == 500 ? "500+" : "\(files)"
            let count = language.text(
                "\(number) \(files == 1 ? "arquivo" : "arquivos") de sessão · uso confirmado",
                "\(number) session \(files == 1 ? "file" : "files") · usage confirmed",
                "\(number) \(files == 1 ? "archivo" : "archivos") de sesión · uso confirmado"
            )
            guard let verifiedActivity else { return count }
            let date = verifiedActivity.formatted(.dateTime.day().month().hour().minute().locale(Locale(identifier: language.rawValue)))
            return count + language.text(" em \(date)", " at \(date)", " el \(date)")
        }
    }
}

extension StoreDataFolder {
    func title(_ language: SetupLanguage) -> String {
        switch self {
        case .codex: "Codex"
        case .claudeCode: "Claude Code"
        case .claudeDesktop: language.text("Claude Desktop (opcional)", "Claude Desktop (optional)", "Claude Desktop (opcional)")
        }
    }
}

extension ProviderHealth {
    func storeBadge(for provider: ProviderID, hasFolderAccess: Bool, language: SetupLanguage) -> String {
        guard hasFolderAccess else {
            return language.text("ACESSO NECESSÁRIO", "ACCESS NEEDED", "ACCESO NECESARIO")
        }
        if (provider == .codex || provider == .claudeCode) && self == .notInstalled {
            return language.text("SEM SESSÕES LOCAIS", "NO LOCAL SESSIONS", "SIN SESIONES LOCALES")
        }
        if (provider == .codex || provider == .claudeCode) && self == .noData {
            return language.text("SEM DADOS DE USO", "NO USAGE DATA", "SIN DATOS DE USO")
        }
        return badgeText
    }
}

#if APP_STORE
import SwiftUI

struct StoreOnboardingView: View {
    let finish: () -> Void

    @State private var language = SetupLanguage.current
    @State private var inspections: [StoreDataFolder: StoreFolderReadiness] = [:]
    @State private var inspectionIDs: [StoreDataFolder: UUID] = [:]
    @State private var error: String?
    private let focus: StoreDataFolder?

    init(focus: StoreDataFolder? = nil, finish: @escaping () -> Void) {
        self.focus = focus
        self.finish = finish
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(language.text("Configurar o NotchAgent", "Set up NotchAgent", "Configurar NotchAgent"))
                    .font(.title2.bold())
                Spacer()
                Picker(language.text("Idioma", "Language", "Idioma"), selection: $language) {
                    ForEach(SetupLanguage.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .labelsHidden()
                .accessibilityLabel(language.text("Idioma", "Language", "Idioma"))
                .frame(width: 135)
            }
            Text(language.text(
                "Conecte as ferramentas que você usa neste Mac. A autorização da pasta é pedida pelo macOS.",
                "Connect the tools you use on this Mac. macOS will ask you to authorize the folder.",
                "Conecta las herramientas que usas en este Mac. macOS te pedirá autorizar la carpeta."
            ))
            Text(language.text(
                "Tarefas na nuvem não ficam neste Mac, mesmo quando você as abre no aplicativo. Elas ainda não aparecem no NotchAgent.",
                "Cloud tasks are not stored on this Mac, even when you open them in the app. NotchAgent cannot show them yet.",
                "Las tareas en la nube no se guardan en este Mac, aunque las abras en la aplicación. NotchAgent todavía no las muestra."
            ))
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(language.text(
                "Sem senha ou chave de API. O acesso salvo é somente leitura. Ao conectar Claude Code, o app altera uma vez a barra de status em .claude/settings.json para mostrar a cota.",
                "No password or API key. Saved access is read-only. When you connect Claude Code, the app makes a one-time change to the status line in .claude/settings.json to show quota.",
                "Sin contraseña ni clave de API. El acceso guardado es de solo lectura. Al conectar Claude Code, la app cambia una vez la barra de estado en .claude/settings.json para mostrar la cuota."
            ))
                .font(.caption)
                .foregroundStyle(.secondary)
            ScrollView {
                accessStep.frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Spacer()
                Button(language.text("Abrir NotchAgent", "Open NotchAgent", "Abrir NotchAgent")) { finishSetup() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(minWidth: 600, minHeight: 440)
        .task { inspectAuthorizedFolders() }
        .onChange(of: language) { _, newValue in
            UserDefaults.standard.set(newValue.rawValue, forKey: SetupLanguage.savedKey)
        }
    }

    private var accessStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(orderedFolders, id: \.self) { folder in
                let selected = SandboxBookmarkStore.shared.selectedRoot(for: folder)
                let quotaEnabled = folder == .claudeCode && selected.map { ClaudeStatuslineSetup.isInstalled(root: $0) } == true
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(folder.title(language))
                            .fontWeight(.semibold)
                        Text(status(for: folder))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if folder == .codex && shouldExplainCodexCloud {
                            Text(language.text(
                                "Conversas iniciadas no navegador podem rodar na nuvem e não gerar sessões aqui.",
                                "Chats started in a browser may run in the cloud and leave no sessions here.",
                                "Las conversaciones iniciadas en el navegador pueden ejecutarse en la nube y no dejar sesiones aquí."
                            ))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Link(language.text("Ver cota oficial", "View official quota", "Ver cuota oficial"), destination: ProviderCardView.codexUsageSettingsURL)
                                .font(.caption)
                        }
                        if folder == .claudeCode, selected != nil {
                            Text(quotaEnabled
                                ? language.text("Cota oficial ativada · aparece após a próxima resposta do Claude Code", "Official quota enabled · appears after Claude Code's next response", "Cuota oficial activada · aparece tras la próxima respuesta de Claude Code")
                                : language.text("Cota não ativada · conecte novamente", "Quota not enabled · connect again", "Cuota no activada · conecta de nuevo"))
                                .font(.caption)
                                .foregroundStyle(quotaEnabled ? .green : .orange)
                        }
                    }
                    Spacer()
                    if selected != nil {
                        Button(language.text("Verificar", "Check", "Comprobar")) { inspect(folder) }
                    }
                    Button(selected == nil
                        ? (folder == .claudeCode
                            ? language.text("Conectar + ativar cota", "Connect + enable quota", "Conectar + activar cuota")
                            : language.text("Conectar", "Connect", "Conectar"))
                        : (folder == .claudeCode && !quotaEnabled
                            ? language.text("Reativar cota", "Enable quota again", "Reactivar cuota")
                            : language.text("Trocar pasta", "Change folder", "Cambiar carpeta"))) {
                        authorize(folder)
                    }
                }
                .padding(10)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            }
            if language == .es {
                Text("La configuración está en español; otras secciones pueden aparecer en portugués o inglés.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let error {
                Text(error).foregroundStyle(.red).font(.caption)
            }
        }
    }

    private var orderedFolders: [StoreDataFolder] {
        guard let focus else { return [.codex, .claudeCode, .claudeDesktop] }
        return [focus] + StoreDataFolder.allCases.filter { $0 != focus }
    }

    private var shouldExplainCodexCloud: Bool {
        switch inspections[.codex] {
        case nil, .some(.missingSessionsFolder), .some(.noRecentSessions): true
        default: false
        }
    }

    private func status(for folder: StoreDataFolder) -> String {
        guard SandboxBookmarkStore.shared.selectedRoot(for: folder) != nil else {
            return language.text(
                "Conecte para ler as sessões salvas neste Mac",
                "Connect to read sessions saved on this Mac",
                "Conecta para leer las sesiones guardadas en este Mac"
            )
        }
        return (inspections[folder] ?? .checking).message(language)
    }

    private func finishSetup() {
        UserDefaults.standard.set(language.rawValue, forKey: SetupLanguage.savedKey)
        AppEnvironment.shared.preferences.settings.interfaceLanguage = language == .pt ? .ptBR : .en
        finish()
    }

    private func authorize(_ folder: StoreDataFolder) {
        do {
            guard try StoreFolderPicker.choose(folder, portuguese: language == .pt, spanish: language == .es) else { return }
            inspect(folder)
            AppEnvironment.shared.scheduler.refreshNow()
            error = nil
        } catch {
            self.error = error is ClaudeStatuslineSetupError ? language.text(
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
