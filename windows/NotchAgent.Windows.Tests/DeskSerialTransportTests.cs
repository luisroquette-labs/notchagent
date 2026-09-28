using System.Collections.Concurrent;
using System.Text.Json;
using NotchAgent.Desk.Protocol;
using NotchAgent.Windows.Desk;
using Xunit;

namespace NotchAgent.Windows.Tests;

public sealed class DeskSerialTransportTests
{
    [Fact]
    public async Task HandshakeCompletesAgainstAFakeDeskAndFiresConnected()
    {
        FakeDeskPort? port = null;
        var states = new ConcurrentQueue<DeskConnectionState>();

        var transport = new DeskSerialTransport(
            candidatePortNames: () => port is null ? ["COM-FAKE"] : [],
            openPort: name =>
            {
                port = new FakeDeskPort(name);
                port.OnWrite = bytes => RespondToHello(port, bytes);
                return port;
            });
        transport.StateChanged += s => states.Enqueue(s);

        transport.Start();
        try
        {
            await WaitFor(() => states.Any(s => s.Phase == DeskConnectionPhase.Connected), TimeSpan.FromSeconds(5));
        }
        finally
        {
            transport.Stop();
        }

        Assert.Contains(states, s => s.Phase == DeskConnectionPhase.Handshaking);
        Assert.Contains(states, s => s.Phase == DeskConnectionPhase.Connected && s.FirmwareVersion == "0.8.0");
    }

    [Fact]
    public async Task ProtocolMajorMismatchIsReportedAsIncompatible()
    {
        FakeDeskPort? port = null;
        var states = new ConcurrentQueue<DeskConnectionState>();

        var transport = new DeskSerialTransport(
            candidatePortNames: () => port is null ? ["COM-FAKE"] : [],
            openPort: name =>
            {
                port = new FakeDeskPort(name);
                port.OnWrite = bytes => RespondToHello(port, bytes, protocolMajor: 9);
                return port;
            });
        transport.StateChanged += s => states.Enqueue(s);

        transport.Start();
        try
        {
            await WaitFor(() => states.Any(s => s.Phase == DeskConnectionPhase.Incompatible), TimeSpan.FromSeconds(5));
        }
        finally
        {
            transport.Stop();
        }

        Assert.Contains(states, s => s.Phase == DeskConnectionPhase.Incompatible);
        Assert.DoesNotContain(states, s => s.Phase == DeskConnectionPhase.Connected);
    }

    private static void RespondToHello(FakeDeskPort port, byte[] writtenBytes, byte protocolMajor = DeskProtocolContract.Major)
    {
        foreach (var frame in new DeskFrameStreamDecoder().Append(writtenBytes))
        {
            if (frame.Type != DeskFrameType.Hello) continue;
            var hello = JsonSerializer.Deserialize<DeskHello>(frame.Payload)!;
            var ack = new DeskHelloAcknowledgement(
                DeskProtocolContract.Product, protocolMajor, DeskProtocolContract.Minor, hello.Nonce, "0.8.0");
            var encoded = DeskFrameCodec.Encode(new DeskFrame(
                DeskFrameType.HelloAcknowledgement, 1, JsonSerializer.SerializeToUtf8Bytes(ack)));
            port.Enqueue(encoded);
        }
    }

    private static async Task WaitFor(Func<bool> condition, TimeSpan timeout)
    {
        var deadline = DateTime.UtcNow + timeout;
        while (DateTime.UtcNow < deadline)
        {
            if (condition()) return;
            await Task.Delay(20);
        }
        Assert.Fail("Condition was not met within the timeout.");
    }
}
