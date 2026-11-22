import AgentMeterCore
import SwiftUI

/// Compact control center: one purpose per tab, without a dashboard crammed
/// into the menu bar popover.
struct MenuBarContentView: View {
    private enum Tab: String, CaseIterable, Identifiable {
        case overview, costs, settings
        var id: Self { self }
        var icon: String {
            switch self {
            case .overview: "gauge.with.dots.needle.33percent"
            case .costs: "brazilianrealsign.circle"
            case .settings: "slider.horizontal.3"
            }
        }
        func label(_ language: InterfaceLanguage) -> String {
            switch self {
            case .overview: language.text("Agora", "Now")
            case .costs: language.text("Gastos", "Spend")
            case .settings: language.text("Ajustes", "Settings")
            }
        }
    }

    @Environment(UsageStore.self) private var store
    @Environment(PreferencesStore.self) private var preferences
    @Environment(WindowRouter.self) private var router
    @EnvironmentObject private var spending: SubscriptionStore
    @State private var selectedTab: Tab = .overview

    var body: some View {
        @Bindable var preferences = preferences

        VStack(alignment: .leading, spacing: 14) {
            header
            tabPicker
            tabContent(preferences: $preferences)
            Divider()
            HStack {
                Button(preferences.settings.interfaceLanguage == .ptBR ? "Encerrar NotchAgent" : "Quit NotchAgent",
                       systemImage: "power") { NSApp.terminate(nil) }
                    .foregroundStyle(.orange)
                Spacer()
                Button(selectedTab == .costs
                       ? preferences.settings.interfaceLanguage.text("Abrir gastos", "Open spend")
                       : "Dashboard") {
                    selectedTab == .costs ? router.openSpending() : router.openDashboard()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .controlSize(.small)
        }
        .padding(14)
        .frame(width: 340)
        .preferredColorScheme(preferences.settings.themeMode.colorScheme)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundStyle(.orange)
                .font(.system(size: 14, weight: .semibold))
            VStack(alignment: .leading, spacing: 1) {
                Text("NOTCHAGENT").font(.system(size: 11, weight: .bold, design: .rounded)).tracking(1.4)
                Text(preferences.settings.interfaceLanguage.text("Controle de capacidade e custo", "Capacity and cost")).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if store.isPaused { Text(preferences.settings.interfaceLanguage.text("PAUSADO", "PAUSED")).font(.caption2.bold()).foregroundStyle(.orange) }
        }
    }

    private var tabPicker: some View {
        HStack(spacing: 4) {
            ForEach(Tab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Label(tab.label(preferences.settings.interfaceLanguage), systemImage: tab.icon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(selectedTab == tab ? .orange : .gray)
                .controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private func tabContent(preferences: Bindable<PreferencesStore>) -> some View {
        switch selectedTab {
        case .overview: overview
        case .costs: costs
        case .settings: settings(preferences: preferences)
        }
    }

    private var overview: some View {
        VStack(spacing: 8) {
            ForEach(ProviderID.allCases) { provider in providerRow(provider) }
            HStack {
                Button(preferences.settings.interfaceLanguage.text("Atualizar", "Refresh"), systemImage: "arrow.clockwise") { AppEnvironment.shared.scheduler.refreshNow() }
                Spacer()
                Button(store.isPaused
                       ? preferences.settings.interfaceLanguage.text("Retomar", "Resume")
                       : preferences.settings.interfaceLanguage.text("Pausar", "Pause"),
                       systemImage: store.isPaused ? "play.fill" : "pause.fill") {
                    store.isPaused.toggle()
                }
            }
            .controlSize(.small)
        }
    }

    private var costs: some View {
        let estimate = EstimatedCostLayers.fromSnapshots(store.snapshots)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 0) {
                costMetric(preferences.settings.interfaceLanguage.text("PAGO · MÊS", "PAID · MONTH"), spending.format(spending.monthlySpend.paidBRL))
                Divider().frame(height: 34).padding(.horizontal, 12)
                costMetric("EST. · 7D", spending.formatEstimatedUSD(estimate.totalUSD))
            }
            if let budget = spending.monthlyBudgetStatus {
                VStack(alignment: .leading, spacing: 4) {
                    HStack { Text(preferences.settings.interfaceLanguage.text("ORÇAMENTO", "BUDGET")).font(.caption2.bold()).foregroundStyle(.secondary); Spacer(); Text("\(Int(budget.projectedPercent.rounded()))%") .font(.caption.bold()) }
                    ProgressView(value: min(budget.projectedPercent, 100), total: 100).tint(budget.level == .normal ? .green : budget.level == .warning ? .orange : .red)
                }
            } else {
                Text(preferences.settings.interfaceLanguage.text("Defina um orçamento para receber alertas.", "Set a budget to get alerts.")).font(.caption).foregroundStyle(.secondary)
            }
            Button(preferences.settings.interfaceLanguage.text("Gerenciar gastos e orçamento", "Manage spend and budget"), systemImage: "arrow.up.right.square") { router.openSpending() }
                .controlSize(.small)
        }
    }

    private func settings(preferences: Bindable<PreferencesStore>) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Toggle(preferences.wrappedValue.settings.interfaceLanguage.text("Alertas do sistema", "System alerts"), isOn: preferences.settings.notificationsEnabled)
            Picker(preferences.wrappedValue.settings.interfaceLanguage.text("Aparência", "Appearance"), selection: preferences.settings.themeMode) {
                ForEach(ThemeMode.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            Picker(preferences.wrappedValue.settings.interfaceLanguage.text("Idioma", "Language"), selection: preferences.settings.interfaceLanguage) {
                ForEach(InterfaceLanguage.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            Button(preferences.wrappedValue.settings.interfaceLanguage.text("Abrir todos os ajustes", "Open all settings"), systemImage: "gearshape") { router.openSettings() }
                .controlSize(.small)
            if !AppEnvironment.shared.appUpdates.isManagedByStore {
                Button(preferences.wrappedValue.settings.interfaceLanguage.text("Buscar atualização…", "Check for updates…"), systemImage: "arrow.down.circle") {
                    AppEnvironment.shared.appUpdates.checkForUpdates()
                }
                .controlSize(.small)
                .disabled(!AppEnvironment.shared.appUpdates.isConfigured)
            }
        }
    }

    private func providerRow(_ provider: ProviderID) -> some View {
        let snapshot = store.snapshots[provider]
        return HStack(spacing: 9) {
            Image(systemName: provider.symbolName).frame(width: 16).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(provider.displayName).font(.subheadline.weight(.semibold))
                Text(detail(for: snapshot)).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            AttentionDot(level: store.attention(for: provider))
        }
        .padding(8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private func costMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2.bold()).foregroundStyle(.secondary)
            Text(value).font(.system(size: 16, weight: .semibold, design: .rounded)).monospacedDigit()
        }
    }

    private func detail(for snapshot: UsageSnapshot?) -> String {
        let language = preferences.settings.interfaceLanguage
        guard let snapshot else { return language.text("Aguardando dados", "Waiting for data") }
        guard snapshot.health.isUsable else { return snapshot.health.badgeText }
        if let metric = GaugeMetric.from(snapshot) { return language.text("\(Int(metric.remaining.rounded()))% restante", "\(Int(metric.remaining.rounded()))% left") }
        return snapshot.note ?? language.text("Sem limite disponível", "No limit available")
    }
}
