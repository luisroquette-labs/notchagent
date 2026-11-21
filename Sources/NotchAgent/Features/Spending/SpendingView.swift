import AgentMeterCore
import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SpendingView: View {
    @Environment(UsageStore.self) private var usageStore
    @Environment(PreferencesStore.self) private var preferences
    @EnvironmentObject private var store: SubscriptionStore
    @State private var showingPlanEditor = false
    @State private var showingExpenseEditor = false
    @State private var showingInvoiceImporter = false
    @State private var invoicePreview: InvoiceImportPreview?

    private var language: InterfaceLanguage { preferences.settings.interfaceLanguage }

    var body: some View {
        List {
            Section(language.text("Gasto no mês", "Spend this month")) {
                TextField(language.text("Orçamento mensal em R$", "Monthly budget in BRL"), text: Binding(
                    get: { store.monthlyBudgetBRL.map { NSDecimalNumber(decimal: $0).stringValue } ?? "" },
                    set: { store.setMonthlyBudgetBRL(BRLFormat.decimal($0)) }
                ))
                Picker(language.text("Moeda", "Currency"), selection: Binding(
                    get: { store.displayCurrency },
                    set: { store.setDisplayCurrency($0) }
                )) {
                    Text("BRL").tag(SpendDisplayCurrency.brl)
                    Text("USD").tag(SpendDisplayCurrency.usd)
                }
                if store.displayCurrency == .usd {
                    TextField(language.text("Cotação: R$ por US$", "Rate: BRL per US$"), text: Binding(
                        get: { store.brlPerUSD.map { NSDecimalNumber(decimal: $0).stringValue } ?? "" },
                        set: { store.setBRLPerUSD(BRLFormat.decimal($0)) }
                    ))
                    Text(language.text("Conversão manual; não consultamos cotação externa.", "Manual conversion; we do not look up a live rate."))
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    metric(language.text("Pago", "Paid"), store.monthlySpend.paidBRL)
                    Spacer()
                    metric(language.text("Previsto", "Forecast"), store.monthlySpend.forecastPlanBRL)
                    Spacer()
                    estimateMetric
                }
                .padding(.vertical, 6)
                if let budget = store.monthlyBudgetStatus {
                    VStack(alignment: .leading, spacing: 5) {
                        ProgressView(value: min(budget.projectedPercent, 100), total: 100)
                            .tint(budgetColor(budget.level))
                        Text(language.text(
                            "Previsão de fechamento: \(store.format(budget.projectedBRL)) / \(store.format(budget.budgetBRL)) · \(Int(budget.projectedPercent.rounded()))%",
                            "Closing forecast: \(store.format(budget.projectedBRL)) / \(store.format(budget.budgetBRL)) · \(Int(budget.projectedPercent.rounded()))%"
                        ))
                            .font(.caption)
                            .foregroundStyle(budgetColor(budget.level))
                    }
                }
                Text(language.text(
                    "Pago = cobrança confirmada. Previsto = próxima renovação. Estimado = tokens locais; não é cobrança.",
                    "Paid = confirmed charge. Forecast = next renewal. Estimated = local tokens; it is not a charge."
                ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(language.text("Planos", "Plans")) {
                if store.subscriptions.isEmpty {
                    Text(language.text("Nenhum plano cadastrado.", "No plans yet.")).foregroundStyle(.secondary)
                }
                ForEach(store.subscriptions) { plan in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(plan.provider.displayName) · \(plan.planName)")
                            Text(language.text(
                                "Próxima renovação: \(plan.nextRenewalDate.formatted(date: .abbreviated, time: .omitted))",
                                "Next renewal: \(plan.nextRenewalDate.formatted(date: .abbreviated, time: .omitted))"
                            ))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(store.format(plan.cycleTotalBRL)).monospacedDigit()
                        Button(language.text("Confirmar", "Confirm")) { _ = store.confirmRenewal(id: plan.id) }
                            .controlSize(.small)
                    }
                }
                Button(language.text("Adicionar plano", "Add plan"), systemImage: "plus") { showingPlanEditor = true }
            }

            connectedSubscriptionsSection

            Section(language.text("Chamadas extras e créditos", "Extra calls and credits")) {
                let currentExpenses = store.expenses.filter {
                    Calendar.current.isDate($0.incurredAt, equalTo: .now, toGranularity: .month)
                }
                if currentExpenses.isEmpty {
                    Text(language.text("Nenhum gasto extra neste mês.", "No extra spend this month.")).foregroundStyle(.secondary)
                }
                ForEach(currentExpenses) { expense in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(expense.title.isEmpty ? expense.kind.label : expense.title)
                            Text("\(expense.provider.displayName) · \(expense.source.title(language))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(store.format(expense.amountBRL)).monospacedDigit()
                        Button(role: .destructive) { store.removeExpense(id: expense.id) } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                Button(language.text("Adicionar gasto extra", "Add extra spend"), systemImage: "plus") { showingExpenseEditor = true }
            }

            Section(language.text("Conciliação", "Reconciliation")) {
                let estimates = EstimatedCostLayers.fromSnapshots(usageStore.snapshots)
                let reconciliation = CostReconciliation.currentMonth(expenses: store.expenses, estimates: estimates)
                if reconciliation.isEmpty {
                    Text(language.text("Importe uma fatura CSV ou gere uso local para comparar.", "Import a CSV invoice or generate local usage to compare.")).foregroundStyle(.secondary)
                }
                ForEach(reconciliation) { row in
                    HStack {
                        Text(row.provider.displayName)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(language.text("Oficial: \(store.format(row.officialBRL))", "Official: \(store.format(row.officialBRL))"))
                            Text(language.text("Local: \(store.formatEstimatedUSD(row.estimatedUSD))", "Local: \(store.formatEstimatedUSD(row.estimatedUSD))"))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Button(language.text("Importar fatura CSV", "Import CSV invoice"), systemImage: "square.and.arrow.down") { showingInvoiceImporter = true }
                Text(language.text(
                    "CSV: date, provider, amount_brl, description. A comparação só é aproximada: sessões web e desktop podem não existir nos arquivos locais.",
                    "CSV: date, provider, amount_brl, description. The comparison is approximate: web and desktop sessions may be missing from local files."
                ))
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section(language.text("Histórico mensal", "Monthly history")) {
                let rows = FinancialHistory.monthlyPayments(history: store.history, expenses: store.expenses)
                if rows.isEmpty {
                    Text(language.text("O histórico começa após confirmar cobranças ou importar faturas.", "History starts after you confirm charges or import invoices.")).foregroundStyle(.secondary)
                }
                ForEach(rows) { row in
                    HStack {
                        Text(row.month.formatted(.dateTime.month(.abbreviated).year()))
                        Text(row.provider.displayName).foregroundStyle(.secondary)
                        Spacer()
                        Text(store.format(row.amountBRL)).monospacedDigit()
                    }
                }
                Button(language.text("Exportar CSV", "Export CSV"), systemImage: "square.and.arrow.up") { exportHistory(rows) }
            }
        }
        .navigationTitle(language.text("Gastos", "Spend"))
        .frame(minWidth: 560, minHeight: 500)
        .sheet(isPresented: $showingPlanEditor) { PlanEditor(store: store) }
        .sheet(isPresented: $showingExpenseEditor) { ExpenseEditor(store: store) }
        .fileImporter(isPresented: $showingInvoiceImporter, allowedContentTypes: [.commaSeparatedText], allowsMultipleSelection: false) { result in
            guard case let .success(urls) = result, let url = urls.first else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else { return }
            invoicePreview = InvoiceImportParser.preview(data: data)
        }
        .alert(language.text("Importar fatura", "Import invoice"), isPresented: Binding(get: { invoicePreview != nil }, set: { if !$0 { invoicePreview = nil } })) {
            Button(language.text("Cancelar", "Cancel"), role: .cancel) { invoicePreview = nil }
            Button(language.text("Importar", "Import")) {
                if let invoicePreview { store.addExpenses(invoicePreview.expenses) }
                invoicePreview = nil
            }
        } message: {
            Text(language.text(
                "\(invoicePreview?.expenses.count ?? 0) lançamento(s) oficial(is). \(invoicePreview?.issues.count ?? 0) linha(s) ignorada(s).",
                "\(invoicePreview?.expenses.count ?? 0) official row(s). \(invoicePreview?.issues.count ?? 0) skipped row(s)."
            ))
        }
    }

    private var connectedSubscriptions: [APIAccountUsage] {
        (usageStore.snapshots[.apiAccounts]?.accountUsage ?? [])
            .filter { $0.service == .anthropicConsole && $0.monthlyPlanBRL != nil }
    }

    @ViewBuilder
    private var connectedSubscriptionsSection: some View {
        Section(language.text("Assinaturas conectadas", "Connected subscriptions")) {
            if connectedSubscriptions.isEmpty {
                Text(language.text("Nenhuma assinatura conectada.", "No connected subscription."))
                    .foregroundStyle(.secondary)
            }
            ForEach(connectedSubscriptions) { plan in
                connectedSubscriptionRow(plan)
            }
            Text(language.text("Assinaturas conectadas não são consumo de API.", "Connected subscriptions are not API spend."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func connectedSubscriptionRow(_ plan: APIAccountUsage) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Claude · \(plan.planName ?? language.text("Assinatura", "Subscription"))")
                Text(language.text("Oficial · lido diretamente do portal Claude", "Official · read directly from the Claude portal"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let amount = plan.monthlyPlanBRL {
                Text(store.format(amount))
                    .monospacedDigit()
            }
        }
        if let credits = plan.balanceBRL {
            LabeledContent(language.text("Créditos de uso", "Usage credits")) {
                Text(store.format(credits))
                    .foregroundStyle(credits >= 0 ? Color.secondary : Color.red)
                    .monospacedDigit()
            }
            .font(.caption)
        }
    }

    private func metric(_ title: String, _ amount: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased()).font(.caption2.bold()).foregroundStyle(.secondary)
            Text(store.format(amount)).font(.title3.bold()).monospacedDigit()
        }
    }

    private var estimateMetric: some View {
        let estimate = EstimatedCostLayers.fromSnapshots(usageStore.snapshots)
        return VStack(alignment: .leading, spacing: 3) {
            Text(language.text("ESTIMADO · 7D", "ESTIMATED · 7D")).font(.caption2.bold()).foregroundStyle(.secondary)
            Text(store.formatEstimatedUSD(estimate.totalUSD)).font(.title3.bold()).monospacedDigit()
        }
    }

    private func budgetColor(_ level: MonthlyBudgetLevel) -> Color {
        switch level { case .normal: .secondary; case .warning: .orange; case .critical, .exceeded: .red }
    }

    private func exportHistory(_ rows: [MonthlyProviderSpend]) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = language == .ptBR ? "notchagent-historico-mensal.csv" : "notchagent-monthly-history.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? FinancialHistory.csv(rows).data(using: .utf8)?.write(to: url, options: .atomic)
    }
}

private struct PlanEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PreferencesStore.self) private var preferences
    let store: SubscriptionStore
    @State private var provider: AgentMeterProvider = .claude
    @State private var name = ""
    @State private var amount = ""
    @State private var renewal = Date()

    var body: some View {
        Form {
            Picker(preferences.settings.interfaceLanguage.text("Fornecedor", "Provider"), selection: $provider) { ForEach(AgentMeterProvider.allCases) { Text($0.displayName).tag($0) } }
            TextField(preferences.settings.interfaceLanguage.text("Plano", "Plan"), text: $name)
            TextField(preferences.settings.interfaceLanguage.text("Valor em R$", "Amount in BRL"), text: $amount)
            DatePicker(preferences.settings.interfaceLanguage.text("Próxima renovação", "Next renewal"), selection: $renewal, displayedComponents: .date)
            HStack { Spacer(); Button(preferences.settings.interfaceLanguage.text("Cancelar", "Cancel")) { dismiss() }; Button(preferences.settings.interfaceLanguage.text("Salvar", "Save")) {
                guard let value = BRLFormat.decimal(amount), value > 0 else { return }
                store.add(AISubscription(provider: provider, planName: name, basePriceBRL: value, nextRenewalDate: renewal))
                dismiss()
            }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || BRLFormat.decimal(amount) == nil) }
        }
        .padding().frame(width: 390)
    }
}

private struct ExpenseEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PreferencesStore.self) private var preferences
    let store: SubscriptionStore
    @State private var provider: AgentMeterProvider = .claude
    @State private var title = ""
    @State private var amount = ""
    @State private var kind: AIExpense.Kind = .usageCredits
    @State private var source: AIExpense.Source = .manual

    var body: some View {
        Form {
            Picker(preferences.settings.interfaceLanguage.text("Fornecedor", "Provider"), selection: $provider) { ForEach(AgentMeterProvider.allCases) { Text($0.displayName).tag($0) } }
            TextField(preferences.settings.interfaceLanguage.text("Descrição", "Description"), text: $title)
            TextField(preferences.settings.interfaceLanguage.text("Valor em R$", "Amount in BRL"), text: $amount)
            Picker(preferences.settings.interfaceLanguage.text("Tipo", "Kind"), selection: $kind) { ForEach(AIExpense.Kind.allCases, id: \.self) { Text($0.title(preferences.settings.interfaceLanguage)).tag($0) } }
            Picker(preferences.settings.interfaceLanguage.text("Origem", "Source"), selection: $source) { ForEach(AIExpense.Source.allCases, id: \.self) { Text($0.title(preferences.settings.interfaceLanguage)).tag($0) } }
            HStack { Spacer(); Button(preferences.settings.interfaceLanguage.text("Cancelar", "Cancel")) { dismiss() }; Button(preferences.settings.interfaceLanguage.text("Salvar", "Save")) {
                guard let value = BRLFormat.decimal(amount), value > 0 else { return }
                store.addExpense(AIExpense(provider: provider, title: title, amountBRL: value, kind: kind, source: source))
                dismiss()
            }.disabled(BRLFormat.decimal(amount) == nil) }
        }
        .padding().frame(width: 390)
    }
}

private extension AIExpense.Kind {
    func title(_ language: InterfaceLanguage) -> String {
        switch self {
        case .apiUsage: language.text("Uso de API", "API usage")
        case .usageCredits: language.text("Créditos de uso", "Usage credits")
        case .tokenPurchase: language.text("Compra de tokens", "Token purchase")
        case .other: language.text("Outro", "Other")
        }
    }
}

private extension AIExpense.Source {
    func title(_ language: InterfaceLanguage) -> String {
        switch self {
        case .manual: language.text("Informado manualmente", "Entered manually")
        case .officialInvoice: language.text("Fatura oficial", "Official invoice")
        case .localEstimate: language.text("Estimativa local", "Local estimate")
        }
    }
}

enum BRLFormat {
    static func string(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: amount as NSDecimalNumber) ?? "R$ 0,00"
    }

    static func decimal(_ input: String) -> Decimal? {
        let trimmed = input
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: " ", with: "")
        let normalized: String
        if trimmed.contains(",") {
            // Brazilian input: 1.234,56. A plain dot remains a decimal separator.
            normalized = trimmed.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        } else {
            normalized = trimmed
        }
        return Decimal(string: normalized)
    }
}
