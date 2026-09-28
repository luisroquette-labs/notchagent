// Vendored copy — source of truth is luisroquette/notchagent-desk,
// sdk/dotnet/NotchAgent.Desk.Protocol/DeskFrameCodec.cs (protocol 1.3,
// PROTOCOL_VERSION file). Vendored instead of cross-repo ProjectReference so
// this repo builds standalone in CI and on any clone — a relative path into
// a sibling repo (../../../notchagent-desk) only worked on a machine that
// happens to have both checked out side by side.
// ponytail: single-copy sync risk instead of a real NuGet feed. Upgrade
// path: publish NotchAgent.Desk.Protocol as a versioned package once the
// Desk repo has a release pipeline, then swap this file for a
// PackageReference. ContractVersionMatchesCurrentProtocol below is the
// tripwire if this copy ever drifts from the live protocol version.
using System.Buffers.Binary;

namespace NotchAgent.Desk.Protocol;

public static class DeskProtocolContract
{
    public const string Product = "NotchAgent Desk";
    public const byte Major = 1;
    public const byte Minor = 3;
    public const int MaximumPayloadBytes = 16 * 1024;
}

public enum DeskFrameType : byte
{
    Hello = 1,
    HelloAcknowledgement = 2,
    Snapshot = 3,
    Heartbeat = 4,
    DeviceTelemetry = 5,
}

public sealed record DeskFrame(DeskFrameType Type, uint Sequence, byte[] Payload);

public sealed class DeskProtocolException(string message) : Exception(message);

public static class DeskFrameCodec
{
    private static readonly byte[] Magic = [0x4E, 0x41, 0x44, 0x4B];
    private const int HeaderSize = 14;

    public static byte[] Encode(DeskFrame frame)
    {
        ArgumentNullException.ThrowIfNull(frame);
        if (frame.Payload.Length > DeskProtocolContract.MaximumPayloadBytes)
            throw new DeskProtocolException("Payload exceeds the 16 KiB protocol limit.");

        var raw = new byte[HeaderSize + frame.Payload.Length + sizeof(uint)];
        Magic.CopyTo(raw, 0);
        raw[4] = DeskProtocolContract.Major;
        raw[5] = (byte)frame.Type;
        BinaryPrimitives.WriteUInt32LittleEndian(raw.AsSpan(6, 4), frame.Sequence);
        BinaryPrimitives.WriteUInt32LittleEndian(raw.AsSpan(10, 4), checked((uint)frame.Payload.Length));
        frame.Payload.CopyTo(raw, HeaderSize);
        BinaryPrimitives.WriteUInt32LittleEndian(raw.AsSpan(raw.Length - 4, 4), Crc32(raw.AsSpan(0, raw.Length - 4)));

        var encoded = CobsEncode(raw);
        Array.Resize(ref encoded, encoded.Length + 1);
        return encoded;
    }

    public static DeskFrame DecodePacket(ReadOnlySpan<byte> packet)
    {
        var raw = CobsDecode(packet);
        if (raw.Length < HeaderSize + 4 || !raw.AsSpan(0, 4).SequenceEqual(Magic))
            throw new DeskProtocolException("Invalid frame header.");
        if (raw[4] != DeskProtocolContract.Major)
            throw new DeskProtocolException("Incompatible protocol major.");
        if (!Enum.IsDefined(typeof(DeskFrameType), raw[5]))
            throw new DeskProtocolException("Unknown frame type.");

        var payloadLength = BinaryPrimitives.ReadUInt32LittleEndian(raw.AsSpan(10, 4));
        if (payloadLength > DeskProtocolContract.MaximumPayloadBytes)
            throw new DeskProtocolException("Payload exceeds the protocol limit.");
        if (raw.Length != HeaderSize + payloadLength + sizeof(uint))
            throw new DeskProtocolException("Invalid frame length.");

        var expected = BinaryPrimitives.ReadUInt32LittleEndian(raw.AsSpan(raw.Length - 4, 4));
        if (expected != Crc32(raw.AsSpan(0, raw.Length - 4)))
            throw new DeskProtocolException("Invalid CRC-32 checksum.");

        var payload = raw.AsSpan(HeaderSize, checked((int)payloadLength)).ToArray();
        return new DeskFrame(
            (DeskFrameType)raw[5],
            BinaryPrimitives.ReadUInt32LittleEndian(raw.AsSpan(6, 4)),
            payload
        );
    }

    public static byte[] CobsEncode(ReadOnlySpan<byte> input)
    {
        var output = new List<byte>(input.Length + input.Length / 254 + 1) { 0 };
        var codeIndex = 0;
        byte code = 1;
        foreach (var value in input)
        {
            if (value == 0)
            {
                output[codeIndex] = code;
                codeIndex = output.Count;
                output.Add(0);
                code = 1;
            }
            else
            {
                output.Add(value);
                code++;
                if (code == 0xFF)
                {
                    output[codeIndex] = code;
                    codeIndex = output.Count;
                    output.Add(0);
                    code = 1;
                }
            }
        }
        output[codeIndex] = code;
        return [.. output];
    }

    public static byte[] CobsDecode(ReadOnlySpan<byte> input)
    {
        if (input.IsEmpty) throw new DeskProtocolException("Empty COBS packet.");
        var output = new List<byte>(input.Length);
        var index = 0;
        while (index < input.Length)
        {
            var code = input[index];
            if (code == 0 || index + code > input.Length + 1)
                throw new DeskProtocolException("Invalid COBS packet.");
            index++;
            var end = index + code - 1;
            if (end > input.Length) throw new DeskProtocolException("Invalid COBS packet.");
            while (index < end) output.Add(input[index++]);
            if (code != 0xFF && index < input.Length) output.Add(0);
        }
        return [.. output];
    }

    private static uint Crc32(ReadOnlySpan<byte> bytes)
    {
        var crc = 0xFFFF_FFFFu;
        foreach (var value in bytes)
        {
            crc ^= value;
            for (var bit = 0; bit < 8; bit++)
                crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xEDB8_8320u : crc >> 1;
        }
        return crc ^ 0xFFFF_FFFFu;
    }
}

public sealed class DeskFrameStreamDecoder
{
    private readonly List<byte> _buffer = [];

    public IReadOnlyList<DeskFrame> Append(ReadOnlySpan<byte> bytes)
    {
        _buffer.AddRange(bytes.ToArray());
        if (_buffer.Count > (DeskProtocolContract.MaximumPayloadBytes + 64) * 2)
        {
            _buffer.Clear();
            throw new DeskProtocolException("Frame stream exceeded its bounded buffer.");
        }

        var frames = new List<DeskFrame>();
        while (_buffer.IndexOf(0) is var delimiter && delimiter >= 0)
        {
            var packet = _buffer.GetRange(0, delimiter).ToArray();
            _buffer.RemoveRange(0, delimiter + 1);
            if (packet.Length > 0) frames.Add(DeskFrameCodec.DecodePacket(packet));
        }
        return frames;
    }
}
