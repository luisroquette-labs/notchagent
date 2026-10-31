import XCTest
@testable import NotchAgent

/// REGRESSÃO: a Anthropic removeu o limite de 5h das contas Ultra verificadas
/// (ex-"Max 20x") a partir de out/2026 — a API para de enviar os headers
/// `anthropic-ratelimit-unified-5h-*` enquanto os `-7d-*` continuam. O app
/// caía no bloco de 5h ESTIMADO do transcript (`SessionBlocks.currentBlock`) e
/// pintava uma "sessão de 5h" que não existe mais para essas contas — um
/// limite fantasma. A supressão tem de vir da PRESENÇA DOS HEADERS, nunca do
/// nome do plano: conta Ultra nova/não-verificada ainda recebe um limite de 5h
/// temporário (headers presentes) e precisa continuar vendo a sessão.
final class FiveHourLimitRemovedTests: XCTestCase {
    private func quota(
        sessionPercent: Double? = nil,
        weeklyPercent: Double? = nil,
        sessionResetsAt: Date? = nil,
        weeklyResetsAt: Date? = nil
    ) -> ClaudeQuota {
        ClaudeQuota(
            sessionPercent: sessionPercent,
            weeklyPercent: weeklyPercent,
            sessionResetsAt: sessionResetsAt,
            weeklyResetsAt: weeklyResetsAt,
            status: nil,
            limitingWindow: nil,
            fetchedAt: Date()
        )
    }

    func testWeeklyPresentNoSessionIsRemoved() {
        // Caso real do dono: Ultra verificado — só semanal reportado.
        XCTAssertTrue(ClaudeProvider.fiveHourLimitRemoved(
            quota: quota(weeklyPercent: 30, weeklyResetsAt: Date().addingTimeInterval(500_000))
        ))
    }

    func testWeeklyResetOnlyNoSessionIsRemoved() {
        // Semanal sinalizado só pelo reset (0% usado, sem util): ainda conta.
        XCTAssertTrue(ClaudeProvider.fiveHourLimitRemoved(
            quota: quota(weeklyResetsAt: Date().addingTimeInterval(500_000))
        ))
    }

    func testSessionPresentIsNotRemoved() {
        // Conta COM limite de 5h (Max/Pro/Ultra não-verificado): mantém sessão.
        XCTAssertFalse(ClaudeProvider.fiveHourLimitRemoved(
            quota: quota(sessionPercent: 20, weeklyPercent: 30)
        ))
    }

    func testSessionResetOnlyIsNotRemoved() {
        // Header de reset de 5h presente (sem util) ainda é um limite de 5h.
        XCTAssertFalse(ClaudeProvider.fiveHourLimitRemoved(
            quota: quota(weeklyPercent: 30, sessionResetsAt: Date().addingTimeInterval(9000))
        ))
    }

    func testNilQuotaIsNotRemoved() {
        // Probe desligada / sem token: não há como saber — mantém a estimativa.
        XCTAssertFalse(ClaudeProvider.fiveHourLimitRemoved(quota: nil))
    }

    func testEmptyQuotaIsNotRemoved() {
        // Probe retornou sem nenhum header útil (falha): não afirmar remoção.
        XCTAssertFalse(ClaudeProvider.fiveHourLimitRemoved(quota: quota()))
    }

    func testSuppressedSessionPromotesWeeklyHeadline() {
        // Contrato de UI: sessão suprimida (nil) + semanal presente → o
        // headline do medidor vira o SEMANAL (NotchCompactView lê "WK LEFT").
        let snap = UsageSnapshot(
            provider: .claudeCode,
            health: .ok,
            session: nil,
            weekly: WeeklyUsage(usedPercent: 42)
        )
        let metric = GaugeMetric.from(snap)
        XCTAssertEqual(metric?.used, 42)
        XCTAssertTrue(metric?.isWeekly ?? false, "sem sessão, o semanal é o headline")
    }

    func testSuppressedSessionWithExhaustedWeeklyStillBlocks() {
        // Coerência com a hierarquia: sem sessão e semanal exausto → bloqueado.
        let snap = UsageSnapshot(
            provider: .claudeCode,
            health: .ok,
            session: nil,
            weekly: WeeklyUsage(usedPercent: 100)
        )
        let metric = GaugeMetric.from(snap)
        XCTAssertEqual(metric?.used, 100)
        XCTAssertTrue(metric?.isWeekly ?? false)
    }
}
