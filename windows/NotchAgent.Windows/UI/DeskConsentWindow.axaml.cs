using Avalonia.Controls;
using Avalonia.Interactivity;

namespace NotchAgent.Windows.UI;

/// One-tap opt-in ask for Desk usage mirroring — the Windows equivalent of
/// the Mac app's system-notification action button. Not a WinRT toast:
/// action-button toasts need AppUserModelID + COM activation registration
/// that can't be verified without a physical Windows machine (same
/// documented limitation as the rest of this port). A plain Avalonia window
/// is something dev-mode can actually exercise end to end.
public partial class DeskConsentWindow : Window
{
    private readonly Action _onEnable;

    public DeskConsentWindow(Action onEnable)
    {
        InitializeComponent();
        _onEnable = onEnable;
    }

    private void OnEnable(object? sender, RoutedEventArgs e)
    {
        _onEnable();
        Close();
    }

    private void OnNotNow(object? sender, RoutedEventArgs e) => Close();
}
