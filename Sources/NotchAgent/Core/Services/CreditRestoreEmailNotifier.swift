import Foundation

/// Sends the "credits are back" email via Resend's HTTP API
/// (https://resend.com/docs/api-reference/emails/send-email). Pure functions
/// (subject/body/shouldSend) are unit-testable without a network call; the
/// gate is the only piece that touches URLSession, mirroring BurnoutNotifier's
/// NotificationGate split.
protocol EmailGate: Sendable {
    func send(to: String, subject: String, body: String, apiKey: String) async
}

struct ResendEmailGate: EmailGate {
    private static let endpoint = URL(string: "https://api.resend.com/emails")!
    /// Resend's shared test sender — works without a verified custom domain,
    /// which fits a single-user local app. Swap for a verified domain address
    /// if delivery to a work inbox gets marked spam.
    private static let from = "NotchAgent <onboarding@resend.dev>"

    func send(to: String, subject: String, body: String, apiKey: String) async {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "from": Self.from,
            "to": [to],
            "subject": subject,
            "text": body,
        ])
        _ = try? await URLSession.shared.data(for: request)
    }
}

enum ResendCredential {
    /// Keychain account key, stored via the same `APIAccountCredentialStore`
    /// helper the API-account monitors already use — no new Keychain plumbing.
    static let keychainAccount = "notchagent.resend-api-key"
}

enum CreditRestoreEmailNotifier {
    static func shouldSend(settings: AppSettings, apiKey: String?) -> Bool {
        settings.notifyEmailOnRestore
            && !settings.notificationEmail.trimmingCharacters(in: .whitespaces).isEmpty
            && !(apiKey ?? "").isEmpty
    }

    static func subject(for moment: RestoreMoment, settings: AppSettings) -> String {
        let pt = settings.interfaceLanguage == .ptBR
        let window = moment.isWeekly ? (pt ? "semanais" : "weekly") : (pt ? "de 5h" : "5h")
        return pt
            ? "\(moment.provider.displayName): créditos \(window) voltaram"
            : "\(moment.provider.displayName): \(window) credits are back"
    }

    static func body(for moment: RestoreMoment, settings: AppSettings) -> String {
        let pt = settings.interfaceLanguage == .ptBR
        let window = moment.isWeekly ? (pt ? "janela semanal" : "weekly window") : (pt ? "janela de 5h" : "5h window")
        let modelLine = moment.activeModel.map { pt ? "Modelo: \($0)\n" : "Model: \($0)\n" } ?? ""
        return pt
            ? "\(moment.provider.displayName) — \(window) resetou.\n\(modelLine)Restante: \(Int(moment.remaining.rounded()))%."
            : "\(moment.provider.displayName) — \(window) reset.\n\(modelLine)Remaining: \(Int(moment.remaining.rounded()))%."
    }

    static func evaluateAndSend(
        moment: RestoreMoment,
        settings: AppSettings,
        apiKey: String?,
        gate: any EmailGate
    ) async {
        guard shouldSend(settings: settings, apiKey: apiKey), let apiKey else { return }
        await gate.send(
            to: settings.notificationEmail,
            subject: subject(for: moment, settings: settings),
            body: body(for: moment, settings: settings),
            apiKey: apiKey
        )
    }
}
