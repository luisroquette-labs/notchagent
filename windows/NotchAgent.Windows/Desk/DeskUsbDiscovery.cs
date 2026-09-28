using System.Management;
using System.Runtime.Versioning;
using NotchAgent.Windows.Services;

namespace NotchAgent.Windows.Desk;

/// VID/PID pre-filter via WMI — the gap 4 upgrade path named in
/// DeskSerialTransport's header comment. Same USB identity the Mac side
/// matches via IOKit (vendor 0x303A / product 0x1001).
///
/// System.Management is Windows-only at runtime; on macOS/Linux dev-mode
/// (this port is built and debugged on macOS — see
/// project_notchagent_windows_companion memory) the WMI query throws and
/// this returns an empty list, which DeskSerialTransport already treats as
/// "no VID/PID match, fall back to probing every port" — so dev-mode keeps
/// working exactly as before this file existed.
public static class DeskUsbDiscovery
{
    private const string VendorId = "303A";
    private const string ProductId = "1001";

    /// COM port names whose USB VID/PID matches the Desk, or empty if WMI
    /// is unavailable (non-Windows) or found no match.
    public static IReadOnlyList<string> FindCandidatePortNames()
    {
        // Guard first, not just try/catch: the WMI APIs below are marked
        // Windows-only by the framework itself, so skip the call entirely
        // on other platforms instead of relying on the exception path.
        if (!OperatingSystem.IsWindows()) return [];
        return FindCandidatePortNamesOnWindows();
    }

    [SupportedOSPlatform("windows")]
    private static IReadOnlyList<string> FindCandidatePortNamesOnWindows()
    {
        try
        {
            using var searcher = new ManagementObjectSearcher("SELECT DeviceID, PNPDeviceID FROM Win32_SerialPort");
            using var results = searcher.Get();
            var matches = new List<string>();
            foreach (ManagementBaseObject item in results)
            {
                var pnpId = item["PNPDeviceID"] as string ?? "";
                var deviceId = item["DeviceID"] as string;
                if (deviceId is null) continue;
                if (pnpId.Contains($"VID_{VendorId}", StringComparison.OrdinalIgnoreCase)
                    && pnpId.Contains($"PID_{ProductId}", StringComparison.OrdinalIgnoreCase))
                {
                    matches.Add(deviceId);
                }
            }
            return matches;
        }
        catch (Exception ex)
        {
            Log.Desk.LogDebug("WMI Desk discovery unavailable, falling back to probing every port: " + ex.Message);
            return [];
        }
    }
}
