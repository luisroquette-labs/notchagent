import Foundation

/// Codex's free "Full reset" credits expire on their own schedule — warn
/// before one lapses unused. Pure — credits and now go in, a signal comes out.
enum ResetCreditAlerter {
    static let leadHours: TimeInterval = 72

    struct Signal: Equatable {
        var title: String
        var detail: String
    }

    static func signal(credits: RateLimitResetCredits?, now: Date = Date(), language: InterfaceLanguage = .ptBR) -> Signal? {
        guard let credits, credits.availableCount > 0,
              let expiresAt = credits.soonestExpiresAt,
              expiresAt > now,
              expiresAt.timeIntervalSince(now) <= leadHours * 3600 else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .ptBR ? "pt_BR" : "en_US_POSIX")
        formatter.dateFormat = language == .ptBR ? "dd/MM 'às' HH:mm" : "MMM d 'at' HH:mm"
        let when = formatter.string(from: expiresAt)
        return Signal(
            title: language.text("RESET GRÁTIS DO CODEX EXPIRANDO", "FREE CODEX RESET EXPIRING"),
            detail: language.text(
                "Você tem \(credits.availableCount) redefinição(ões) de limite — a mais próxima expira em \(when).",
                "You have \(credits.availableCount) limit reset(s) — the soonest expires \(when)."
            )
        )
    }
}
