using System.IO.Ports;

namespace NotchAgent.Windows.Desk;

/// Seam over a single open serial connection — the .NET analogue of the
/// Swift transport's injectable `candidatePaths`/raw-fd design. Lets tests
/// exercise the handshake state machine against a fake Desk instead of
/// needing physical hardware.
public interface IDeskPort : IDisposable
{
    string PortName { get; }
    bool IsOpen { get; }
    int BytesToRead { get; }
    int Read(byte[] buffer, int offset, int count);
    void Write(byte[] buffer, int offset, int count);
}

/// Real implementation, backed by System.IO.Ports.SerialPort.
public sealed class SystemSerialDeskPort : IDeskPort
{
    private readonly SerialPort _port;

    public SystemSerialDeskPort(string portName)
    {
        _port = new SerialPort(portName, 115_200, Parity.None, 8, StopBits.One)
        {
            ReadTimeout = 200,
            WriteTimeout = 500,
        };
        _port.Open();
    }

    public string PortName => _port.PortName;
    public bool IsOpen => _port.IsOpen;
    public int BytesToRead => _port.BytesToRead;
    public int Read(byte[] buffer, int offset, int count) => _port.Read(buffer, offset, count);
    public void Write(byte[] buffer, int offset, int count) => _port.Write(buffer, offset, count);
    public void Dispose() => _port.Dispose();
}
