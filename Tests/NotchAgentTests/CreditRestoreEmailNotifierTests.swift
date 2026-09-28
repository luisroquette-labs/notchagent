import XCTest
@testable import NotchAgent

final class CreditRestoreEmailNotifierTests: XCTestCase {
    private actor RecordingGate: EmailGate {
        private(set) var calls: [(to: String, subject: String, body: String, apiKey: String)] = []

        func send(to: String, subject: String, body: String, apiKey: String) async {
            calls.append((to, subject, body, apiKey))
        }

        func callCount() -> Int { calls.count }
        func lastCall() -> (to: String, subject: String, body: String, apiKey: String)? { calls.last }
    }

    private func settings(enabled: Bool = true, email: String = "user@example.com") -> AppSettings {
        var settings = AppSettings()
        settings.notifyEmailOnRestore = enabled
        settings.notificationEmail = email
        return settings
    }

    // REGRESSÃO: toggle desligado nunca deve mandar e-mail, mesmo com
    // endereço e chave configurados.
    func testShouldSendFalseWhenToggleOff() {
        XCTAssertFalse(CreditRestoreEmailNotifier.shouldSend(settings: settings(enabled: false), apiKey: "re_key"))
    }

    // REGRESSÃO: sem endereço de destino, não dispara mesmo com toggle ligado.
    func testShouldSendFalseWhenEmailBlank() {
        XCTAssertFalse(CreditRestoreEmailNotifier.shouldSend(settings: settings(email: ""), apiKey: "re_key"))
    }

    // REGRESSÃO: sem chave Resend no Keychain, não dispara.
    func testShouldSendFalseWhenAPIKeyMissing() {
        XCTAssertFalse(CreditRestoreEmailNotifier.shouldSend(settings: settings(), apiKey: nil))
        XCTAssertFalse(CreditRestoreEmailNotifier.shouldSend(settings: settings(), apiKey: ""))
    }

    func testShouldSendTrueWhenFullyConfigured() {
        #if APP_STORE
        XCTAssertFalse(CreditRestoreEmailNotifier.shouldSend(settings: settings(), apiKey: "re_key"))
        #else
        XCTAssertTrue(CreditRestoreEmailNotifier.shouldSend(settings: settings(), apiKey: "re_key"))
        #endif
    }

    // Especifica qual janela (semanal vs 5h) e qual modelo estava ativo.
    func testSubjectAndBodyNameWindowAndModel() {
        var pt = settings()
        pt.interfaceLanguage = .ptBR
        let weekly = RestoreMoment(provider: .claudeCode, previousRemaining: 3, remaining: 100, isWeekly: true, activeModel: "claude-opus-4")
        XCTAssertTrue(CreditRestoreEmailNotifier.subject(for: weekly, settings: pt).contains("semanais"))
        let weeklyBody = CreditRestoreEmailNotifier.body(for: weekly, settings: pt)
        XCTAssertTrue(weeklyBody.contains("claude-opus-4"))
        XCTAssertTrue(weeklyBody.contains("semanal"))

        let session = RestoreMoment(provider: .claudeCode, previousRemaining: 3, remaining: 100, isWeekly: false, activeModel: "claude-sonnet-4.6")
        XCTAssertTrue(CreditRestoreEmailNotifier.subject(for: session, settings: pt).contains("5h"))
        XCTAssertTrue(CreditRestoreEmailNotifier.body(for: session, settings: pt).contains("claude-sonnet-4.6"))

        var en = settings()
        en.interfaceLanguage = .en
        XCTAssertTrue(CreditRestoreEmailNotifier.subject(for: weekly, settings: en).contains("weekly"))
    }

    // REGRESSÃO: modelo desconhecido não deve quebrar o corpo do e-mail — só
    // omite a linha "Modelo:" em vez de imprimir algo falso.
    func testBodyOmitsModelLineWhenUnknown() {
        let moment = RestoreMoment(provider: .claudeCode, previousRemaining: 3, remaining: 100, isWeekly: true, activeModel: nil)
        let body = CreditRestoreEmailNotifier.body(for: moment, settings: settings())
        XCTAssertFalse(body.contains("Modelo:"))
    }

    func testEvaluateAndSendCallsGateOnlyWhenConfigured() async {
        let gate = RecordingGate()
        let moment = RestoreMoment(provider: .claudeCode, previousRemaining: 3, remaining: 100, isWeekly: true, activeModel: "claude-opus-4")

        await CreditRestoreEmailNotifier.evaluateAndSend(moment: moment, settings: settings(enabled: false), apiKey: "re_key", gate: gate)
        let countAfterDisabled = await gate.callCount()
        XCTAssertEqual(countAfterDisabled, 0, "toggle off must not call the gate")

        await CreditRestoreEmailNotifier.evaluateAndSend(moment: moment, settings: settings(), apiKey: "re_key", gate: gate)
        let call = await gate.lastCall()
        #if APP_STORE
        XCTAssertNil(call)
        #else
        XCTAssertEqual(call?.to, "user@example.com")
        XCTAssertEqual(call?.apiKey, "re_key")
        XCTAssertTrue(call?.body.contains("claude-opus-4") == true)
        #endif
    }
}
