/// Pure decision for what UI response a Desk connection-phase change should
/// trigger, given current onboarding/mirroring settings. Kept separate from
/// AppEnvironment's closure so the branching is unit-testable without
/// standing up the full app composition root.
enum DeskOnboardingAction: Equatable {
    /// Nothing to do — already onboarded, or the phase isn't actionable yet.
    case none
    /// Firmware/protocol mismatch — a real problem, not a consent ask.
    case openRecoverySettings
    /// Hardware recognized but mirroring is still off — ask, one tap away.
    case askToEnableMirroring
}

enum DeskOnboardingDecision {
    static func action(
        for phase: NotchAgentDeskConnectionState.Phase,
        onboardingCompleted: Bool,
        mirroringEnabled: Bool
    ) -> DeskOnboardingAction {
        guard !onboardingCompleted else { return .none }
        switch phase {
        case .incompatible:
            return .openRecoverySettings
        case .connected:
            return mirroringEnabled ? .none : .askToEnableMirroring
        case .disabled, .searching, .handshaking:
            return .none
        }
    }
}
