import Foundation

enum StoreOnboardingState {
    static let completedKey = "appStore.guidedSetupCompleted.v1"

    static func shouldPresent(completed: Bool, hasAuthorizedFolder: Bool) -> Bool {
        !completed && !hasAuthorizedFolder
    }
}

#if APP_STORE
import SwiftUI

enum SetupLanguage: String, CaseIterable, Identifiable {
    case pt, en, es

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

struct StoreOnboardingView: View {
    let finish: () -> Void

    @Environment(UsageStore.self) private var store
    @State private var language = SetupLanguage.system
    @State private var step: Int
    @State private var selected: Set<StoreDataFolder>
    @State private var authorizedAt: [StoreDataFolder: Date] = [:]
    @State private var error: String?
    @State private var showExample = false
    @State private var revision = 0

    init(focus: StoreDataFolder? = nil, finish: @escaping () -> Void) {
        self.finish = finish
        _step = State(initialValue: focus == nil ? 0 : 1)
        _selected = State(initialValue: focus.map { Set([$0]) } ?? Set(
            StoreDataFolder.allCases.filter { SandboxBookmarkStore.shared.selectedRoot(for: $0) != nil }
        ))
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
            Text(language.text("Etapa \(step + 1) de 2", "Step \(step + 1) of 2", "Paso \(step + 1) de 2"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if step == 0 { sourceStep } else { accessStep }

            Spacer(minLength: 0)
            HStack {
                if step == 1 {
                    Button(language.text("Voltar", "Back", "Volver")) { step = 0 }
                }
                Spacer()
                Button(language.text("Fazer depois", "Do later", "Hacerlo después")) { finishSetup() }
                if step == 0 {
                    Button(language.text("Continuar", "Continue", "Continuar")) { step = 1 }
                        .buttonStyle(.borderedProminent)
                        .disabled(selected.isEmpty)
                } else {
                    Button(language.text("Concluir", "Finish", "Terminar")) { finishSetup() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!selected.allSatisfy { SandboxBookmarkStore.shared.selectedRoot(for: $0) != nil })
                }
            }
        }
        .padding(24)
        .frame(minWidth: 560, minHeight: 440)
        .id(revision)
    }

    private var sourceStep: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(language.text(
                "O NotchAgent lê os dados de uso salvos neste computador. Quais ferramentas você usa?",
                "NotchAgent reads usage data saved on this computer. Which tools do you use?",
                "NotchAgent lee los datos de uso guardados en este equipo. ¿Qué herramientas usas?"
            ))
            sourceToggle(.codex, title: "Codex")
            sourceToggle(.claudeCode, title: "Claude Code")
            sourceToggle(.claudeDesktop, title: language.text(
                "Claude Desktop (opcional)", "Claude Desktop (optional)", "Claude Desktop (opcional)"
            ))
            Text(language.text(
                "Acesso somente leitura. Você escolhe cada pasta e pode revogar o acesso nos Ajustes. Não precisa de senha nem chave de API.",
                "Read-only access. You choose each folder and can revoke access in Settings. No password or API key needed.",
                "Acceso de solo lectura. Tú eliges cada carpeta y puedes revocarlo en Ajustes. No necesitas contraseña ni clave de API."
            ))
                .font(.caption)
                .foregroundStyle(.secondary)
            Button(language.text("Ver exemplo", "See example", "Ver ejemplo")) {
                showExample.toggle()
            }
            if showExample {
                Text(language.text(
                    "EXEMPLO · Codex · sessão de 5h: 43% usado · semana: 28% usado",
                    "EXAMPLE · Codex · 5h session: 43% used · week: 28% used",
                    "EJEMPLO · Codex · sesión de 5 h: 43% usado · semana: 28% usado"
                ))
                    .font(.caption.monospaced())
                    .padding(10)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            }
            if language == .es {
                Text("La guía está en español; el resto de la interfaz está disponible en inglés.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func sourceToggle(_ folder: StoreDataFolder, title: String) -> some View {
        Toggle(title, isOn: Binding(
            get: { selected.contains(folder) },
            set: { enabled in
                if enabled { selected.insert(folder) } else { selected.remove(folder) }
            }
        ))
    }

    private var accessStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.text(
                "Confirme o acesso. O seletor já abre no lugar certo; escolha a pasta indicada.",
                "Confirm access. The picker opens in the right place; select the named folder.",
                "Confirma el acceso. El selector se abre en el lugar correcto; elige la carpeta indicada."
            ))
            ForEach(StoreDataFolder.allCases.filter { selected.contains($0) }, id: \.self) { folder in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(folder == .codex ? "Codex" : folder == .claudeCode ? "Claude Code" : "Claude Desktop")
                            .fontWeight(.semibold)
                        Text(status(for: folder))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if SandboxBookmarkStore.shared.selectedRoot(for: folder) == nil {
                        Button(language.text("Conectar", "Connect", "Conectar")) { authorize(folder) }
                    } else if hasReadError(for: folder) {
                        Button(language.text("Tentar novamente", "Try again", "Reintentar")) {
                            authorizedAt[folder] = Date()
                            AppEnvironment.shared.scheduler.refreshNow()
                        }
                    }
                }
                .padding(10)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            }
            Text(language.text(
                "\(connectedCount) de \(selected.count) conectado(s)",
                "\(connectedCount) of \(selected.count) connected",
                "\(connectedCount) de \(selected.count) conectado(s)"
            ))
                .font(.caption.weight(.semibold))
            if let error {
                Text(error).foregroundStyle(.red).font(.caption)
            }
        }
    }

    private var connectedCount: Int {
        selected.filter { SandboxBookmarkStore.shared.selectedRoot(for: $0) != nil }.count
    }

    private func status(for folder: StoreDataFolder) -> String {
        guard SandboxBookmarkStore.shared.selectedRoot(for: folder) != nil else {
            return language.text(
                "Selecione a pasta \(folder.expectedFolderName)",
                "Select the \(folder.expectedFolderName) folder",
                "Elige la carpeta \(folder.expectedFolderName)"
            )
        }
        guard let authorizedAt = authorizedAt[folder] else {
            return language.text("Conectado", "Connected", "Conectado")
        }
        let provider: ProviderID = folder == .codex ? .codex : .claudeCode
        switch store.refreshStates[provider] {
        case .success(let date) where date >= authorizedAt:
            let health = store.snapshots[provider]?.health
            switch health {
            case .ok, .degraded:
                return language.text("Dados encontrados", "Data found", "Datos encontrados")
            case .parseError:
                return language.text("Não foi possível ler as sessões", "Could not read sessions", "No se pudieron leer las sesiones")
            case .notInstalled:
                return language.text("Pasta de sessões não encontrada", "Session folder not found", "No se encontró la carpeta de sesiones")
            default:
                return language.text("Nenhuma sessão recente", "No recent sessions", "No hay sesiones recientes")
            }
        case .failure(let date, _) where date >= authorizedAt:
            return language.text("Falha na leitura", "Could not read sessions", "No se pudieron leer las sesiones")
        default:
            return language.text("Lendo sessões…", "Reading sessions…", "Leyendo sesiones…")
        }
    }

    private func hasReadError(for folder: StoreDataFolder) -> Bool {
        guard let authorizedAt = authorizedAt[folder] else { return false }
        let provider: ProviderID = folder == .codex ? .codex : .claudeCode
        switch store.refreshStates[provider] {
        case .failure(let date, _) where date >= authorizedAt: return true
        case .success(let date) where date >= authorizedAt:
            return store.snapshots[provider]?.health == .parseError
        default: return false
        }
    }

    private func finishSetup() {
        AppEnvironment.shared.preferences.settings.interfaceLanguage = language == .pt ? .ptBR : .en
        finish()
    }

    private func authorize(_ folder: StoreDataFolder) {
        do {
            guard try StoreFolderPicker.choose(folder, portuguese: language == .pt, spanish: language == .es) else { return }
            authorizedAt[folder] = Date()
            AppEnvironment.shared.scheduler.refreshNow()
            error = nil
            revision += 1
        } catch {
            self.error = language.text(
                "Não foi possível usar essa pasta. Escolha \(folder.expectedFolderName) e tente novamente.",
                "Could not use that folder. Choose \(folder.expectedFolderName) and try again.",
                "No se pudo usar esa carpeta. Elige \(folder.expectedFolderName) e inténtalo de nuevo."
            )
        }
    }
}
#endif
