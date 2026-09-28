using NotchAgent.Desk.Protocol;
using Xunit;

namespace NotchAgent.Windows.Tests;

public sealed class DeskProtocolContractTests
{
    // Tripwire for the vendored copy of DeskFrameCodec.cs (see its header
    // comment): if the live protocol version moves and this file isn't
    // updated to match, this is what catches it — the same class of bug the
    // NotchAgent-Desk repo's own SDK had (Minor stuck at 1 while the wire
    // protocol moved to 1.3, undetected because nothing asserted it there
    // either until that fix).
    [Fact]
    public void VendoredContractMatchesTheLiveProtocolVersion()
    {
        Assert.Equal(1, DeskProtocolContract.Major);
        Assert.Equal(3, DeskProtocolContract.Minor);
    }
}
