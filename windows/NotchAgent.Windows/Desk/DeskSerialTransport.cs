using System.IO.Ports;
using System.Text.Json;
using NotchAgent.Desk.Protocol;
using NotchAgent.Windows.Services;

namespace NotchAgent.Windows.Desk;

/// Port of the Mac app's `NotchAgentDeskSerialTransport` state machine onto
/// `System.IO.Ports.SerialPort`. Same handshake/reconnect timing (5s
/// handshake timeout, 1s hello retry, 15s re-handshake, 30s cooldown per
/// failed port) so a Desk behaves identically regardless of host OS.
///
/// VID/PID pre-filter (DeskUsbDiscovery, WMI) narrows the candidate list to
/// USB vendor 0x303A/product 0x1001 when available — same identity the Mac
/// side matches via IOKit. Falls back to probing every COM port when WMI
/// finds no match (including non-Windows dev-mode, where WMI is a no-op):
/// slower with many serial devices attached, but the handshake itself still
/// verifies the product name, so a wrong device is never misidentified.
public sealed class DeskSerialTransport
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        Converters = { new DeskMillisecondsDateConverter() },
    };

    public event Action<DeskConnectionState>? StateChanged;

    private readonly Func<IReadOnlyList<string>> _candidatePortNames;
    private readonly Func<string, IDeskPort?> _openPort;

    /// Real hardware by default; tests pass fakes for both.
    public DeskSerialTransport(
        Func<IReadOnlyList<string>>? candidatePortNames = null,
        Func<string, IDeskPort?>? openPort = null)
    {
        _candidatePortNames = candidatePortNames ?? DefaultCandidatePortNames;
        _openPort = openPort ?? DefaultOpenPort;
    }

    private static IReadOnlyList<string> DefaultCandidatePortNames()
    {
        var vidPidMatches = DeskUsbDiscovery.FindCandidatePortNames();
        return vidPidMatches.Count > 0 ? vidPidMatches : SerialPort.GetPortNames();
    }

    private static IDeskPort? DefaultOpenPort(string portName)
    {
        try { return new SystemSerialDeskPort(portName); }
        catch { return null; }
    }

    private IDeskPort? _port;
    private DeskFrameStreamDecoder _decoder = new();
    private uint _sequence;
    private uint _handshakeNonce;
    private bool _isRecognized;
    private bool _isIncompatible;
    private string? _acknowledgedFirmwareVersion;
    private DeskSnapshot? _pendingSnapshot;
    private DateTimeOffset _connectedAt;
    private DateTimeOffset _lastHello;
    private DateTimeOffset _lastHandshakeRefresh;
    private readonly Dictionary<string, DateTimeOffset> _cooldowns = new();
    private CancellationTokenSource? _loopCts;

    public void Start()
    {
        if (_loopCts is not null) return;
        _loopCts = new CancellationTokenSource();
        _ = Task.Run(() => RunAsync(_loopCts.Token));
    }

    public void Stop()
    {
        _loopCts?.Cancel();
        _loopCts = null;
        Disconnect();
    }

    public void Publish(DeskSnapshot snapshot)
    {
        _pendingSnapshot = snapshot;
        if (_isRecognized) SendPendingSnapshot();
    }

    private async Task RunAsync(CancellationToken token)
    {
        while (!token.IsCancellationRequested)
        {
            if (_port is null) TryConnectNextCandidate();
            if (_port is { IsOpen: true })
            {
                ReadAvailableBytes();
                var now = DateTimeOffset.UtcNow;
                if (!_isRecognized && !_isIncompatible && (now - _connectedAt) >= TimeSpan.FromSeconds(5))
                {
                    if (_port.PortName is { } path) _cooldowns[path] = now;
                    Disconnect();
                }
                else if (!_isRecognized && !_isIncompatible && (now - _lastHello) >= TimeSpan.FromSeconds(1))
                {
                    SendHello();
                }
                else if (_isRecognized && (now - _lastHandshakeRefresh) >= TimeSpan.FromSeconds(15))
                {
                    // A device reset can preserve the port while erasing its
                    // in-RAM recognized state — re-run the handshake so
                    // snapshots recover without user action.
                    _handshakeNonce = (uint)Random.Shared.Next();
                    _isRecognized = false;
                    _connectedAt = now;
                    SendHello();
                }
            }
            await Task.Delay(_port is { IsOpen: true } ? 100 : 1_000, token).ContinueWith(_ => { });
        }
        Disconnect();
    }

    private void TryConnectNextCandidate()
    {
        var now = DateTimeOffset.UtcNow;
        var candidates = _candidatePortNames()
            .Where(name => !_cooldowns.TryGetValue(name, out var failedAt) || (now - failedAt) >= TimeSpan.FromSeconds(30))
            .OrderBy(name => name);

        foreach (var name in candidates)
        {
            var port = _openPort(name);
            if (port is null) continue;

            _port = port;
            _decoder = new DeskFrameStreamDecoder();
            _isRecognized = false;
            _isIncompatible = false;
            _acknowledgedFirmwareVersion = null;
            _connectedAt = now;
            _lastHandshakeRefresh = now;
            _handshakeNonce = (uint)Random.Shared.Next();
            StateChanged?.Invoke(new DeskConnectionState(DeskConnectionPhase.Handshaking, name));
            SendHello();
            Log.Desk.LogInformation("NotchAgent Desk USB candidate opened: " + name);
            return;
        }
    }

    private void SendHello()
    {
        _lastHello = DateTimeOffset.UtcNow;
        var hello = new DeskHello(DeskProtocolContract.Product, DeskProtocolContract.Major, DeskProtocolContract.Minor, _handshakeNonce);
        Send(DeskFrameType.Hello, JsonSerializer.SerializeToUtf8Bytes(hello, JsonOptions));
    }

    private void ReadAvailableBytes()
    {
        if (_port is not { IsOpen: true }) return;
        try
        {
            var available = _port.BytesToRead;
            if (available <= 0) return;
            var buffer = new byte[available];
            var read = _port.Read(buffer, 0, available);
            foreach (var frame in _decoder.Append(buffer.AsSpan(0, read)))
            {
                Handle(frame);
            }
        }
        catch (TimeoutException)
        {
            // No bytes within ReadTimeout — normal when the device is idle.
        }
        catch (Exception ex)
        {
            Log.Desk.LogError("NotchAgent Desk read failed: " + ex.Message);
            Disconnect();
        }
    }

    private void Handle(DeskFrame frame)
    {
        try
        {
            if (frame.Type == DeskFrameType.DeviceTelemetry && _isRecognized)
            {
                var telemetry = JsonSerializer.Deserialize<DeskDeviceTelemetry>(frame.Payload, JsonOptions);
                if (telemetry is null || telemetry.FirmwareVersion != _acknowledgedFirmwareVersion)
                {
                    Log.Desk.LogError("NotchAgent Desk handshake and telemetry firmware versions disagree");
                    if (_port?.PortName is { } path) _cooldowns[path] = DateTimeOffset.UtcNow;
                    Disconnect();
                    return;
                }
                StateChanged?.Invoke(new DeskConnectionState(DeskConnectionPhase.Connected, _port?.PortName, telemetry.FirmwareVersion));
                return;
            }

            if (frame.Type != DeskFrameType.HelloAcknowledgement) return;
            var ack = JsonSerializer.Deserialize<DeskHelloAcknowledgement>(frame.Payload, JsonOptions);
            if (ack is null || ack.Product != DeskProtocolContract.Product || ack.Nonce != _handshakeNonce) return;

            if (ack.ProtocolMajor != DeskProtocolContract.Major)
            {
                _isIncompatible = true;
                StateChanged?.Invoke(new DeskConnectionState(DeskConnectionPhase.Incompatible, _port?.PortName, ack.FirmwareVersion));
                return;
            }
            if (string.IsNullOrEmpty(ack.FirmwareVersion))
            {
                _isIncompatible = true;
                StateChanged?.Invoke(new DeskConnectionState(DeskConnectionPhase.Incompatible, _port?.PortName));
                return;
            }

            _isRecognized = true;
            _isIncompatible = false;
            _acknowledgedFirmwareVersion = ack.FirmwareVersion;
            _lastHandshakeRefresh = DateTimeOffset.UtcNow;
            if (_port?.PortName is { } recognizedPath) _cooldowns.Remove(recognizedPath);
            Log.Desk.LogInformation("NotchAgent Desk recognized");
            StateChanged?.Invoke(new DeskConnectionState(DeskConnectionPhase.Connected, _port?.PortName, ack.FirmwareVersion));
            SendPendingSnapshot();
        }
        catch (JsonException ex)
        {
            Log.Desk.LogError("NotchAgent Desk malformed frame payload: " + ex.Message);
        }
    }

    private void SendPendingSnapshot()
    {
        if (_pendingSnapshot is not { } snapshot) return;
        var payload = JsonSerializer.SerializeToUtf8Bytes(snapshot, JsonOptions);
        if (payload.Length > DeskProtocolContract.MaximumPayloadBytes)
        {
            Log.Desk.LogError("NotchAgent Desk snapshot exceeds protocol limit");
            return;
        }
        Send(DeskFrameType.Snapshot, payload);
    }

    private void Send(DeskFrameType type, byte[] payload)
    {
        if (_port is not { IsOpen: true }) return;
        _sequence++;
        try
        {
            var encoded = DeskFrameCodec.Encode(new DeskFrame(type, _sequence, payload));
            _port.Write(encoded, 0, encoded.Length);
        }
        catch (Exception ex)
        {
            Log.Desk.LogError("NotchAgent Desk write failed: " + ex.Message);
            Disconnect();
        }
    }

    private void Disconnect()
    {
        try { _port?.Dispose(); } catch { /* already closed */ }
        _port = null;
        _isRecognized = false;
        _isIncompatible = false;
        _acknowledgedFirmwareVersion = null;
        _decoder = new DeskFrameStreamDecoder();
        StateChanged?.Invoke(DeskConnectionState.Searching);
    }
}
