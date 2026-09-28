using System.ComponentModel;
using NotchAgent.Windows.Services;

namespace NotchAgent.Windows.Desk;

/// .NET analogue of the Mac app's `NotchAgentDeskCoordinator`: owns the
/// transport, republishes a snapshot whenever `UsageStore` changes, and
/// respects the same opt-in mirroring flag (default off — see
/// `AppSettings.NotchAgentDeskEnabled`, mirrored from the Mac's deliberate
/// privacy stance, not a bug to "fix" toward always-on).
public sealed class DeskCoordinator
{
    private readonly UsageStore _store;
    private readonly DeskSerialTransport _transport = new();
    private bool _isStarted;
    private bool _isMirroringEnabled;

    public DeskConnectionState ConnectionState { get; private set; } = DeskConnectionState.Disabled;

    /// Fired on every connection-phase transition — Connected the first time
    /// mirroring is still off is the app's cue to ask the user, one tap away.
    public event Action<DeskConnectionPhase>? OnConnectionPhaseChange;

    public DeskCoordinator(UsageStore store)
    {
        _store = store;
        _transport.StateChanged += state =>
        {
            if (!_isStarted) return;
            var previousPhase = ConnectionState.Phase;
            ConnectionState = state;
            if (previousPhase != state.Phase) OnConnectionPhaseChange?.Invoke(state.Phase);
        };
    }

    public void Start(bool mirroringEnabled)
    {
        if (_isStarted)
        {
            SetMirroringEnabled(mirroringEnabled);
            return;
        }
        _isStarted = true;
        _isMirroringEnabled = mirroringEnabled;
        ConnectionState = DeskConnectionState.Searching;
        UpdateStoreObservation();
        _transport.Start();
        if (mirroringEnabled) Publish();
        else _transport.Publish(DeskSnapshotFactory.MakePrivacyBlank(DateTimeOffset.UtcNow));
    }

    public void Stop()
    {
        if (!_isStarted) return;
        _isStarted = false;
        _isMirroringEnabled = false;
        ConnectionState = DeskConnectionState.Disabled;
        _store.PropertyChanged -= OnStoreChanged;
        _transport.Stop();
    }

    public void SetMirroringEnabled(bool enabled)
    {
        if (!_isStarted)
        {
            Start(enabled);
            return;
        }
        if (_isMirroringEnabled == enabled) return;
        _isMirroringEnabled = enabled;
        UpdateStoreObservation();
        if (enabled) Publish();
        else _transport.Publish(DeskSnapshotFactory.MakePrivacyBlank(DateTimeOffset.UtcNow));
    }

    private void UpdateStoreObservation()
    {
        _store.PropertyChanged -= OnStoreChanged;
        if (_isMirroringEnabled) _store.PropertyChanged += OnStoreChanged;
    }

    private void OnStoreChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName is nameof(UsageStore.Snapshots) or nameof(UsageStore.RefreshStates)) Publish();
    }

    private void Publish()
    {
        if (!_isMirroringEnabled) return;
        _transport.Publish(DeskSnapshotFactory.Make(_store, DateTimeOffset.UtcNow));
    }
}
