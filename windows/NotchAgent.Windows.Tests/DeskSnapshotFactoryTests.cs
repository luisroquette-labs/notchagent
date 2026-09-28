using NotchAgent.Windows.Desk;
using NotchAgent.Windows.Models;
using NotchAgent.Windows.Services;
using Xunit;

namespace NotchAgent.Windows.Tests;

public sealed class DeskSnapshotFactoryTests
{
    [Fact]
    public void MakeReportsRemainingPercentAndTokensFromTheSessionGauge()
    {
        var store = new UsageStore(new AppSettings());
        store.Apply(new UsageSnapshot
        {
            Provider = ProviderId.ClaudeCode,
            Health = ProviderHealth.Ok,
            Session = new SessionUsage
            {
                UsedPercent = 30,
                Tokens = new TokenUsage { Input = 100, Output = 50 },
            },
        });

        var snapshot = DeskSnapshotFactory.Make(store, DateTimeOffset.UtcNow);

        var provider = Assert.Single(snapshot.Providers);
        Assert.Equal("claude-code", provider.Id);
        Assert.Equal("session", provider.Window);
        Assert.Equal(70, provider.RemainingPercent);
        Assert.Equal(150, provider.Tokens);
    }

    [Fact]
    public void MakeShowsEmptyGaugeAsAbsentRatherThanZero()
    {
        var store = new UsageStore(new AppSettings());
        store.Apply(new UsageSnapshot { Provider = ProviderId.Codex, Health = ProviderHealth.NoData });

        var snapshot = DeskSnapshotFactory.Make(store, DateTimeOffset.UtcNow);

        var provider = Assert.Single(snapshot.Providers);
        Assert.Null(provider.RemainingPercent);
        Assert.Null(provider.Window);
    }

    [Fact]
    public void MakePrivacyBlankCarriesNoProvidersAndMarksItselfPaused()
    {
        var snapshot = DeskSnapshotFactory.MakePrivacyBlank(DateTimeOffset.UtcNow);

        Assert.Empty(snapshot.Providers);
        Assert.True(snapshot.IsPaused);
        Assert.False(snapshot.RunnerEnabled);
    }
}
