using System.Text.Json.Serialization;
using NotchAgent.Windows.Models;

namespace NotchAgent.Windows.Desk;

/// Wire-JSON shapes for the frame payloads. Field names and the
/// milliseconds-since-epoch date encoding must match the Mac app's
/// `NotchAgentDeskProtocol.swift` byte-for-byte — the firmware doesn't know
/// which host produced a frame.
public sealed class DeskMillisecondsDateConverter : JsonConverter<DateTimeOffset>
{
    public override DateTimeOffset Read(ref System.Text.Json.Utf8JsonReader reader, Type typeToConvert, System.Text.Json.JsonSerializerOptions options) =>
        DateTimeOffset.FromUnixTimeMilliseconds(reader.GetInt64());

    public override void Write(System.Text.Json.Utf8JsonWriter writer, DateTimeOffset value, System.Text.Json.JsonSerializerOptions options) =>
        writer.WriteNumberValue(value.ToUnixTimeMilliseconds());
}

public sealed record DeskHello(
    [property: JsonPropertyName("product")] string Product,
    [property: JsonPropertyName("protocolMajor")] byte ProtocolMajor,
    [property: JsonPropertyName("protocolMinor")] byte ProtocolMinor,
    [property: JsonPropertyName("nonce")] uint Nonce
);

public sealed record DeskHelloAcknowledgement(
    [property: JsonPropertyName("product")] string Product,
    [property: JsonPropertyName("protocolMajor")] byte ProtocolMajor,
    [property: JsonPropertyName("protocolMinor")] byte ProtocolMinor,
    [property: JsonPropertyName("nonce")] uint Nonce,
    [property: JsonPropertyName("firmwareVersion")] string? FirmwareVersion
);

public sealed record DeskDeviceTelemetry(
    [property: JsonPropertyName("firmwareVersion")] string FirmwareVersion
);

public enum DeskConnectionPhase { Disabled, Searching, Handshaking, Connected, Incompatible }

public sealed record DeskConnectionState(
    DeskConnectionPhase Phase,
    string? PortName = null,
    string? FirmwareVersion = null
)
{
    public static readonly DeskConnectionState Disabled = new(DeskConnectionPhase.Disabled);
    public static readonly DeskConnectionState Searching = new(DeskConnectionPhase.Searching);
}

public sealed record DeskSnapshot(
    [property: JsonPropertyName("product")] string Product,
    [property: JsonPropertyName("protocolMajor")] byte ProtocolMajor,
    [property: JsonPropertyName("protocolMinor")] byte ProtocolMinor,
    [property: JsonPropertyName("generatedAt")] DateTimeOffset GeneratedAt,
    [property: JsonPropertyName("overallAttention")] int OverallAttention,
    [property: JsonPropertyName("isPaused")] bool IsPaused,
    [property: JsonPropertyName("providers")] List<DeskSnapshotProvider> Providers,
    [property: JsonPropertyName("burnHistory")] List<DeskBurnPoint> BurnHistory,
    [property: JsonPropertyName("rhythm")] List<DeskRhythmPoint> Rhythm,
    [property: JsonPropertyName("currentHour")] int? CurrentHour,
    [property: JsonPropertyName("currentHourElapsedFraction")] double? CurrentHourElapsedFraction,
    [property: JsonPropertyName("models")] List<DeskModelUsage> Models,
    [property: JsonPropertyName("alertThresholds")] List<int> AlertThresholds,
    [property: JsonPropertyName("runnerEnabled")] bool RunnerEnabled
);

/// Shapes reserved for when BURN/RHYTHM/MODELS get real data (see the
/// ponytail note on DeskSnapshotProvider) — kept schema-correct even while
/// always empty, so a future populated list is compiler-checked, not guessed.
public sealed record DeskBurnPoint(
    [property: JsonPropertyName("ageSeconds")] int AgeSeconds,
    [property: JsonPropertyName("usedPercent")] double UsedPercent
);

public sealed record DeskRhythmPoint(
    [property: JsonPropertyName("hour")] int Hour,
    [property: JsonPropertyName("tokens")] long Tokens
);

public sealed record DeskModelUsage(
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("tokens")] long Tokens
);

/// Only NOW-page data is real on Windows today: BURN/RHYTHM/MODELS need the
/// burn-projection, hourly-rhythm and per-model breakdown the Windows port
/// hasn't ported from Mac yet (see project_notchagent_windows_companion
/// memory — pre-existing, documented gap, not new). Those arrays ship
/// empty rather than fabricated; the firmware already renders an empty
/// state for them.
/// ponytail: NOW-only bridge. Upgrade path: port UsageStore's burn/rhythm/
/// model aggregation from the Mac's DeskSnapshotFactory once those features
/// land on Windows, then fill BurnHistory/Rhythm/Models for real.
public sealed record DeskSnapshotProvider(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("health")] string Health,
    [property: JsonPropertyName("refreshState")] string RefreshState,
    [property: JsonPropertyName("remainingPercent")] double? RemainingPercent,
    [property: JsonPropertyName("window")] string? Window,
    [property: JsonPropertyName("resetsAt")] DateTimeOffset? ResetsAt,
    [property: JsonPropertyName("tokens")] long Tokens,
    [property: JsonPropertyName("attention")] int Attention
);
