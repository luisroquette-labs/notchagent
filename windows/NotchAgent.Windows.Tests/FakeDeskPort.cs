using NotchAgent.Windows.Desk;

namespace NotchAgent.Windows.Tests;

/// In-memory stand-in for a real serial connection — lets tests drive
/// DeskSerialTransport's handshake state machine against a scripted fake
/// Desk instead of physical hardware. Same seam the Mac app's actor-based
/// transport gets from its injectable `candidatePaths`/`stateHandler`.
internal sealed class FakeDeskPort : IDeskPort
{
    private readonly object _lock = new();
    private readonly Queue<byte> _readable = new();

    public string PortName { get; }
    public bool IsOpen { get; private set; } = true;
    public List<byte> Written { get; } = [];

    /// Called synchronously with each full frame the transport writes —
    /// tests use this to decode the outgoing frame and Enqueue a scripted
    /// response.
    public Action<byte[]>? OnWrite { get; set; }

    public FakeDeskPort(string portName) => PortName = portName;

    public int BytesToRead { get { lock (_lock) return _readable.Count; } }

    public int Read(byte[] buffer, int offset, int count)
    {
        lock (_lock)
        {
            if (_readable.Count == 0) throw new TimeoutException("No bytes queued.");
            var n = Math.Min(count, _readable.Count);
            for (var i = 0; i < n; i++) buffer[offset + i] = _readable.Dequeue();
            return n;
        }
    }

    public void Write(byte[] buffer, int offset, int count)
    {
        var bytes = buffer.AsSpan(offset, count).ToArray();
        Written.AddRange(bytes);
        OnWrite?.Invoke(bytes);
    }

    public void Enqueue(byte[] bytes)
    {
        lock (_lock)
        {
            foreach (var b in bytes) _readable.Enqueue(b);
        }
    }

    public void Dispose() => IsOpen = false;
}
