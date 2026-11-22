import Foundation
import AgentMeterCore

/// Sinal CALMA AÍ: projeção de esgotamento (burn rate) diz que a cota acaba
/// antes do reset e dentro do lead. Puro — samples e datas entram, sinal sai.
enum BurnoutAlerter {
    static let leadMinutes: TimeInterval = 30

    static func signal(
        samples: [PercentSample],
        resetsAt: Date?,
        now: Date = Date(),
        language: InterfaceLanguage = .ptBR
    ) -> SessionInsightsPayload.BurnoutSignal? {
        guard samples.count >= 2,
              let projection = BurnRate.project(samples: samples, resetsAt: resetsAt, now: now),
              let exhaustsAt = projection.exhaustsAt,
              let resetsAt,
              exhaustsAt < resetsAt,
              exhaustsAt.timeIntervalSince(now) <= leadMinutes * 60 else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .ptBR ? "pt_BR" : "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        let time = formatter.string(from: exhaustsAt)
        return SessionInsightsPayload.BurnoutSignal(
            title: language.text("CALMA AÍ", "EASE UP"),
            detail: language.text(
                "Nesse ritmo você ficará sem token às \(time).",
                "At this pace you run out of tokens at \(time)."
            ),
            exhaustsAt: exhaustsAt
        )
    }

    /// Um sinal por provider (usa percentHistory do UsageStore + reset do snapshot).
    static func signals(
        snapshots: [ProviderID: UsageSnapshot],
        percentHistory: [ProviderID: [PercentSample]],
        now: Date = Date(),
        language: InterfaceLanguage = .ptBR
    ) -> [ProviderID: SessionInsightsPayload.BurnoutSignal] {
        var result: [ProviderID: SessionInsightsPayload.BurnoutSignal] = [:]
        for (provider, snapshot) in snapshots {
            guard let samples = percentHistory[provider], !samples.isEmpty else { continue }
            if let signal = signal(samples: samples, resetsAt: snapshot.session?.resetsAt, now: now, language: language) {
                result[provider] = signal
            }
        }
        return result
    }
}
