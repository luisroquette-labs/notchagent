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

#if APP_STORE
import SwiftUI

extension StoreFolderReadiness {
    func message(_ language: SetupLanguage) -> String {
        switch self {
        case .checking:
            return language.text("Verificando sessões…", "Checking sessions…", "Comprobando sesiones…")
        case .missingSessionsFolder:
            return language.text("A pasta não contém os dados esperados.", "This folder has no expected session data.", "Esta carpeta no contiene los datos esperados.")
        case .noRecentSessions:
            return language.text("Nenhuma sessão nos últimos 8 dias. Use a ferramenta e atualize.", "No sessions in the last 8 days. Use the tool, then refresh.", "No hay sesiones en los últimos 8 días. Usa la herramienta y actualiza.")
        case .noUsageRecords:
            return language.text("Arquivos encontrados, mas sem dados de uso legíveis.", "Files found, but no readable usage records.", "Hay archivos, pero no datos de uso legibles.")
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

struct StoreOnboardingView: View {
    let finish: () -> Void

    @State private var language = SetupLanguage.current
    @State private var inspections: [StoreDataFolder: StoreFolderReadiness] = [:]
    @State private var inspectionIDs: [StoreDataFolder: UUID] = [:]
    @State private var error: String?
    @State private var showExample = false
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
                "Escolha a ferramenta que você usa. Cada botão abre o seletor na pasta esperada.",
                "Choose a tool you use. Each button opens the picker at the expected folder.",
                "Elige la herramienta que usas. Cada botón abre el selector en la carpeta esperada."
            ))
            Text(language.text(
                "Sem senha nem chave de API. O acesso salvo é somente leitura; para mostrar a cota oficial do Claude, o app ativa a barra de status em .claude/settings.json.",
                "No password or API key. Saved access is read-only; to show Claude's official quota, the app enables the status line in .claude/settings.json.",
                "Sin contraseña ni clave de API. El acceso guardado es de solo lectura; para mostrar la cuota oficial de Claude, la app activa la barra de estado en .claude/settings.json."
            ))
                .font(.caption)
                .foregroundStyle(.secondary)
            ScrollView {
                accessStep.frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Spacer()
                Button(language.text("Fazer depois", "Do later", "Hacerlo después")) { finishSetup() }
                Button(language.text("Concluir", "Finish", "Terminar")) { finishSetup() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!StoreDataFolder.allCases.contains {
                        SandboxBookmarkStore.shared.selectedRoot(for: $0) != nil
                    })
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
                        Button(language.text("Atualizar", "Refresh", "Actualizar")) { inspect(folder) }
                    }
                    Button(selected == nil
                        ? (folder == .claudeCode
                            ? language.text("Conectar + ativar cota", "Connect + enable quota", "Conectar + activar cuota")
                            : language.text("Conectar", "Connect", "Conectar"))
                        : (folder == .claudeCode && !quotaEnabled
                            ? language.text("Reativar cota", "Enable quota again", "Reactivar cuota")
                            : language.text("Escolher outra pasta", "Choose another folder", "Elegir otra carpeta"))) {
                        authorize(folder)
                    }
                }
                .padding(10)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            }
            Button(language.text("Ver exemplo", "See example", "Ver ejemplo")) { showExample.toggle() }
            if showExample {
                Text(language.text(
                    "EXEMPLO · Codex · sessão de 5h: 43% usado · semana: 28% usado",
                    "EXAMPLE · Codex · 5h session: 43% used · week: 28% used",
                    "EJEMPLO · Codex · sesión de 5 h: 43% usado · semana: 28% usado"
                ))
                    .font(.caption.monospaced())
            }
            if language == .es {
                Text("La configuración está en español; otras secciones pueden aparecer en portugués o inglés.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text(language.text(
                "O percentual vem da barra de status do Claude Code após uma resposta. Se você já usa outra barra, o app pede sua escolha antes de substituí-la.",
                "The percentage comes from Claude Code's status line after a response. If you already use another status line, the app asks before replacing it.",
                "El porcentaje llega desde la barra de Claude Code tras una respuesta. Si ya usas otra barra, la app pide permiso antes de reemplazarla."
            ))
                .font(.caption).foregroundStyle(.secondary)
            if let error {
                Text(error).foregroundStyle(.red).font(.caption)
            }
        }
    }

    private var orderedFolders: [StoreDataFolder] {
        guard let focus else { return [.codex, .claudeCode, .claudeDesktop] }
        return [focus] + StoreDataFolder.allCases.filter { $0 != focus }
    }

    private func status(for folder: StoreDataFolder) -> String {
        guard SandboxBookmarkStore.shared.selectedRoot(for: folder) != nil else {
            return language.text(
                "Selecione \(folder.expectedFolderName) para ler o uso local",
                "Select \(folder.expectedFolderName) to read local usage",
                "Elige \(folder.expectedFolderName) para leer el uso local"
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
