import AgentMeterCore
import Foundation

struct DecisionAdvice: Identifiable, Equatable {
    enum Severity: Int { case normal, warning, critical }
    var id: String { title }
    var title: String
    var detail: String
    var severity: Severity
}

enum DecisionAdvisor {
    static let cacheShareMin = 0.25
    static let modelDominanceShare = 0.40
    static let fablePoolWarnPercent = 70.0
    static let sessionTightPercent = 80.0
    static let limitedFreshness: TimeInterval = 30 * 60
    static let minTokensForAdvice = 50_000

    static func advise(
        snapshots: [ProviderID: UsageSnapshot],
        budget: MonthlyBudgetStatus?,
        now: Date = Date(),
        language: InterfaceLanguage = .ptBR
    ) -> [DecisionAdvice] {
        var advice: [DecisionAdvice] = []
        if let budget {
            let percent = Int(budget.projectedPercent.rounded())
            switch budget.level {
            case .exceeded:
                advice.append(.init(
                    title: language.text("Evite gasto adicional", "Avoid extra spend"),
                    detail: language.text("A previsão já excede o orçamento mensal.", "The forecast is already over the monthly budget."),
                    severity: .critical
                ))
            case .critical:
                advice.append(.init(
                    title: language.text("Reduza modelos caros", "Use cheaper models"),
                    detail: language.text("A previsão atingiu \(percent)% do orçamento.", "The forecast has reached \(percent)% of the budget."),
                    severity: .critical
                ))
            case .warning:
                advice.append(.init(
                    title: language.text("Use modelos caros com critério", "Be selective with expensive models"),
                    detail: language.text("A previsão atingiu \(percent)% do orçamento.", "The forecast has reached \(percent)% of the budget."),
                    severity: .warning
                ))
            case .normal: break
            }
        }
        for provider in ProviderID.allCases {
            if let coldCache = coldCacheAdvice(snapshots[provider], language: language) { advice.append(coldCache) }
            if let expensiveModel = dominantExpensiveModelAdvice(snapshots[provider], language: language) { advice.append(expensiveModel) }
            if let fablePool = fablePoolAdvice(snapshots[provider], language: language) { advice.append(fablePool) }
            if let limited = limitedModelAdvice(snapshots[provider], now: now, language: language) { advice.append(limited) }
            if let tight = tightSessionAdvice(snapshots[provider], now: now, language: language) { advice.append(tight) }
            guard let gauge = GaugeMetric.from(snapshots[provider]), gauge.remaining <= 20 else { continue }
            let left = Int(gauge.remaining.rounded())
            advice.append(.init(
                title: language.text("Poupe \(provider.shortName)", "Spare \(provider.shortName)"),
                detail: language.text("Restam \(left)% da quota atual.", "\(left)% of the current quota is left."),
                severity: .warning
            ))
        }
        let estimates = EstimatedCostLayers.fromSnapshots(snapshots)
        if let driver = estimates.byProvider.max(by: { $0.value < $1.value }), driver.value > 0 {
            let amount = String(format: "%.2f", driver.value)
            advice.append(.init(
                title: language.text("Maior custo local: \(driver.key.shortName)", "Largest local cost: \(driver.key.shortName)"),
                detail: language.text("~$\(amount) nos últimos 7 dias; é estimativa de tokens.", "~$\(amount) over the last 7 days; this is a token estimate."),
                severity: .normal
            ))
        }
        if advice.isEmpty {
            advice.append(.init(
                title: language.text("Pode continuar", "You can keep going"),
                detail: language.text("Sem pressão de orçamento ou quota detectada agora.", "No budget or quota pressure detected right now."),
                severity: .normal
            ))
        }
        return Array(advice.prefix(5))
    }

    /// Resumo da sessão ativa para o painel: share de cache lido (0...1) e
    /// modelo dominante. nil quando não há sessão relevante.
    static func cacheSummary(_ session: SessionUsage?) -> (share: Double, dominantModel: String?)? {
        guard let session, session.tokens.total >= minTokensForAdvice else { return nil }
        let share = Double(session.tokens.cacheRead) / Double(max(session.tokens.total, 1))
        let dominant = session.modelTokens?
            .max(by: { $0.value.total < $1.value.total })?.key
        return (share, dominant)
    }

    /// Um modelo respondeu 429 agora há pouco (o probe lê headers até em 429).
    private static func limitedModelAdvice(_ snapshot: UsageSnapshot?, now: Date = Date(), language: InterfaceLanguage = .ptBR) -> DecisionAdvice? {
        guard let limited = snapshot?.modelHealth?.first(where: {
            $0.status == .limited && now.timeIntervalSince($0.checkedAt) < limitedFreshness
        }) else { return nil }
        return DecisionAdvice(
            title: language.text("Modelo em limite (429)", "Model is rate-limited (429)"),
            detail: language.text(
                "\(limited.model) respondeu 429 agora há pouco; troque de modelo ou espere o reset da janela.",
                "\(limited.model) returned 429 just now; switch models or wait for the window to reset."
            ),
            severity: .critical
        )
    }

    /// Sessão ≥ 80% consumida com reset distante — modere o ritmo.
    private static func tightSessionAdvice(_ snapshot: UsageSnapshot?, now: Date = Date(), language: InterfaceLanguage = .ptBR) -> DecisionAdvice? {
        guard let session = snapshot?.session,
              let used = session.usedPercent, used >= sessionTightPercent,
              let resetsAt = session.resetsAt,
              resetsAt.timeIntervalSince(now) > 3600 else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .ptBR ? "pt_BR" : "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        let time = formatter.string(from: resetsAt)
        let usedText = Int(used.rounded())
        return DecisionAdvice(
            title: language.text("Sessão apertada", "Tight session"),
            detail: language.text(
                "\(usedText)% consumidos e o reset só às \(time); modere nas próximas horas.",
                "\(usedText)% used and the reset is only at \(time); ease off for the next few hours."
            ),
            severity: .warning
        )
    }

    /// Sessão com pouco cache lido (releitura de contexto cara). Só dispara
    /// acima do piso de tokens — sessão minúscula não merece conselho.
    private static func coldCacheAdvice(_ snapshot: UsageSnapshot?, language: InterfaceLanguage = .ptBR) -> DecisionAdvice? {
        guard let session = snapshot?.session,
              session.tokens.total >= minTokensForAdvice else { return nil }
        let share = Double(session.tokens.cacheRead) / Double(max(session.tokens.total, 1))
        guard share < cacheShareMin else { return nil }
        let pct = Int((share * 100).rounded())
        return DecisionAdvice(
            title: language.text("Sessão fria de cache", "Cold cache session"),
            detail: language.text(
                "Apenas \(pct)% dos tokens desta sessão são leitura de cache; manter a sessão ativa reutiliza contexto (cache expira em 1h).",
                "Only \(pct)% of this session's tokens are cache reads; keeping the session open reuses context (cache expires in 1h)."
            ),
            severity: .warning
        )
    }

    /// O modelo mais caro da sessão domina (≥ 40% dos tokens) enquanto um
    /// mais barato também foi usado — comparação de preço via PricingTable,
    /// sempre rotulada como estimativa local.
    private static func dominantExpensiveModelAdvice(_ snapshot: UsageSnapshot?, language: InterfaceLanguage = .ptBR) -> DecisionAdvice? {
        guard let modelTokens = snapshot?.session?.modelTokens else { return nil }
        let total = modelTokens.values.reduce(0) { $0 + $1.total }
        guard total >= minTokensForAdvice else { return nil }
        let priced = modelTokens.keys.compactMap { model -> (String, Double)? in
            guard let pricing = PricingTable.pricing(forModel: model) else { return nil }
            return (model, pricing.inputPerMTok)
        }
        guard let expensive = priced.max(by: { $0.1 < $1.1 }),
              let cheaper = priced.min(by: { $0.1 < $1.1 }),
              cheaper.0 != expensive.0 else { return nil }
        let share = Double(modelTokens[expensive.0]?.total ?? 0) / Double(max(total, 1))
        guard share >= modelDominanceShare else { return nil }
        let pct = Int((share * 100).rounded())
        let ratio = Int((expensive.1 / max(cheaper.1, 0.0001) * 100).rounded())
        return DecisionAdvice(
            title: language.text("Modelo mais caro dominando", "Most expensive model is dominating"),
            detail: language.text(
                "\(expensive.0) é \(pct)% da sessão; \(cheaper.0) tem preço ~\(ratio)% menor (estimativa local).",
                "\(expensive.0) is \(pct)% of the session; \(cheaper.0) is about \(ratio)% cheaper (local estimate)."
            ),
            severity: .normal
        )
    }

    /// A cota separada do Fable 5 (pool próprio, fora do agregado) está alta.
    private static func fablePoolAdvice(_ snapshot: UsageSnapshot?, language: InterfaceLanguage = .ptBR) -> DecisionAdvice? {
        guard let fable = snapshot?.session?.namedQuotas?
            .first(where: { $0.name.lowercased().contains("fable") }),
            fable.usedPercent >= fablePoolWarnPercent else { return nil }
        return DecisionAdvice(
            title: language.text("Fable 5: cota própria", "Fable 5: its own quota"),
            detail: language.text(
                "A cota separada do Fable 5 está em \(Int(fable.usedPercent.rounded()))%; o pool compartilhado pode estar intacto — verifique qual janela está limitando.",
                "Fable 5's separate quota is at \(Int(fable.usedPercent.rounded()))% used; the shared pool may still be fine — check which window is limiting you."
            ),
            severity: .warning
        )
    }
}
