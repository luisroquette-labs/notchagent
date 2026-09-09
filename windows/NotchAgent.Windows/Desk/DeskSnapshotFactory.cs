using NotchAgent.Desk.Protocol;
using NotchAgent.Windows.Models;
using NotchAgent.Windows.Services;

namespace NotchAgent.Windows.Desk;

/// Maps `UsageStore` to the wire `DeskSnapshot`. Pure function — no I/O, no
/// service dependencies — so it stays unit-testable without a live UsageStore.
///
/// Only NOW-page fields are real (see the ponytail note on
/// DeskSnapshotProvider for why BURN/RHYTHM/MODELS ship empty).
public static class DeskSnapshotFactory
{
    public static DeskSnapshot Make(UsageStore store, DateTimeOffset now)
    {
        var providers = new List<DeskSnapshotProvider>();
        foreach (var providerId in Enum.GetValues<ProviderId>())
        {
            if (!store.Snapshots.TryGetValue(providerId, out var snapshot)) continue;
            var gauge = GaugeMetric.From(snapshot);
            providers.Add(new DeskSnapshotProvider(
                Id: WireProviderId(providerId),
                Health: WireHealth(snapshot.Health),
                RefreshState: WireRefreshState(store.RefreshStates.GetValueOrDefault(providerId)),
                RemainingPercent: gauge is { } g ? Math.Clamp(g.Remaining, 0, 100) : null,
                Window: gauge is { } gw ? (gw.IsWeekly ? "weekly" : "session") : null,
                ResetsAt: gauge?.IsWeekly == true ? snapshot.Weekly?.ResetsAt : snapshot.Session?.ResetsAt,
                Tokens: TokenTotal(gauge?.IsWeekly == true ? snapshot.Weekly?.Tokens : snapshot.Session?.Tokens),
                Attention: (int)store.Attention(providerId)
            ));
        }

        return new DeskSnapshot(
            Product: DeskProtocolContract.Product,
            ProtocolMajor: DeskProtocolContract.Major,
            ProtocolMinor: DeskProtocolContract.Minor,
            GeneratedAt: now,
            OverallAttention: (int)store.OverallAttention,
            IsPaused: store.IsPaused,
            Providers: providers.Take(8).ToList(),
            BurnHistory: [],
            Rhythm: [],
            CurrentHour: now.Hour,
            CurrentHourElapsedFraction: now.Minute / 60.0,
            Models: [],
            AlertThresholds: ThresholdAlerts.Levels.ToList(),
            RunnerEnabled: store.Settings.RunnerEnabled
        );
    }

    public static DeskSnapshot MakePrivacyBlank(DateTimeOffset now) => new(
        Product: DeskProtocolContract.Product,
        ProtocolMajor: DeskProtocolContract.Major,
        ProtocolMinor: DeskProtocolContract.Minor,
        GeneratedAt: now,
        OverallAttention: (int)AttentionLevel.Normal,
        IsPaused: true,
        Providers: [],
        BurnHistory: [],
        Rhythm: [],
        CurrentHour: now.Hour,
        CurrentHourElapsedFraction: now.Minute / 60.0,
        Models: [],
        AlertThresholds: ThresholdAlerts.Levels.ToList(),
        RunnerEnabled: false
    );

    private static string WireProviderId(ProviderId id) => id switch
    {
        ProviderId.ClaudeCode => "claude-code",
        ProviderId.Codex => "codex",
        _ => throw new ArgumentOutOfRangeException(nameof(id)),
    };

    private static string WireHealth(ProviderHealth health) => health switch
    {
        ProviderHealth.Ok => "ok",
        ProviderHealth.Degraded => "degraded",
        ProviderHealth.ParseError => "parseError",
        ProviderHealth.NotInstalled => "notInstalled",
        ProviderHealth.NoData => "noData",
        _ => "noData",
    };

    private static string WireRefreshState(RefreshState? state) => state switch
    {
        RefreshState.Refreshing => "refreshing",
        RefreshState.Success => "updated",
        RefreshState.Failure => "error",
        _ => "idle",
    };

    private static long TokenTotal(TokenUsage? usage) => usage?.Total ?? 0;
}
