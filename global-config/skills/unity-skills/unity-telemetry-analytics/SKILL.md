---
name: unity-telemetry-analytics
description: "Use when integrating analytics events, Firebase Crashlytics, Telemetry data, event dispatching via AnalyticsEventDispatcher/PendingEventBuffer, and managing offline events."
---

# Unity Telemetry and Analytics Integration

## Overview
Guidelines for managing analytics event dispatching and telemetry tracking. This ensures all metrics and tracking events are successfully buffered offline, dispatched without locking the main thread, and properly synchronized when Firebase initialization completes.

## When to Use
- Implementing custom game telemetry trackers.
- Adding new Firebase analytics events or parameters.
- Debugging issues with `AnalyticsEventDispatcher` or offline `PendingEventBuffer`.
- Handling events that occur before Firebase has fully initialized.

## Key Concepts

| Concept | Description |
|---------|-------------|
| **AnalyticsEventDispatcher** | High-level dispatcher that channels events to analytics services (Firebase, AppsFlyer, etc.). |
| **PendingEventBuffer** | Queue that stores events offline or before initialization, to be flushed later. |
| **Telemetry Event** | A structured data payload with name, timestamp, and metadata. |
| **Initialize Delay** | Handling the gap when events are fired before Firebase completes initialization. |

## Best Practices
- ✅ **Always** buffer events in `PendingEventBuffer` if Firebase is not yet initialized.
- ✅ Use asynchronous patterns (`UniTask` or Task-based) for network dispatching to prevent main thread blocking.
- ✅ Implement proper CancellationToken propagation to cancel telemetry uploads on scene change.
- ✅ Standardize event parameter formats (use snake_case for event parameters and names).
- ❌ **NEVER** drop events directly if a network request fails; retry with exponential backoff or buffer them.
- ❌ **NEVER** perform blocking synchronous HTTP operations on the main thread for telemetry.
- ✅ After merges/reverts, verify the WIRING, not just the classes: the dispatcher/buffer can silently become dead code while the legacy log entry point keeps its old drop-if-not-initialized logic. Check that the central log method actually routes through the dispatcher.
- ✅ Verify events on device with Firebase DebugView, not the normal dashboard (normal pipeline lags hours): `adb shell setprop debug.firebase.analytics.app <package.name>` to enable, `adb shell setprop debug.firebase.analytics.app .none.` to disable.
- ✅ Instrument funnel checkpoints around loading-phase API calls (e.g. between login-success and world-time fetch) — these gaps are where silent user drop-off hides.

## Few-Shot Examples

### Example 1: Buffer and Dispatch Pattern
**User**: "Tích hợp và sửa logic của AnalyticsEventDispatcher để tự động đệm sự kiện khi Firebase chưa sẵn sàng."

**Agent**:
```csharp
public class AnalyticsEventDispatcher
{
    private readonly PendingEventBuffer _pendingBuffer = new();
    private bool _isFirebaseInitialized;

    public void Initialize()
    {
        FirebaseApp.CheckAndFixDependenciesAsync().ContinueWithOnMainThread(task => {
            var dependencyStatus = task.Result;
            if (dependencyStatus == DependencyStatus.Available)
            {
                _isFirebaseInitialized = true;
                FlushPendingEvents();
            }
            else
            {
                Debug.LogError($"Could not resolve all Firebase dependencies: {dependencyStatus}");
            }
        });
    }

    public void TrackEvent(string eventName, Dictionary<string, object> parameters)
    {
        var telemetryEvent = new TelemetryEvent(eventName, parameters, DateTime.UtcNow);

        if (!_isFirebaseInitialized)
        {
            Debug.Log($"[Telemetry] Firebase not ready. Buffering event: {eventName}");
            _pendingBuffer.Add(telemetryEvent);
            return;
        }

        SendToFirebase(telemetryEvent);
    }

    private void FlushPendingEvents()
    {
        var events = _pendingBuffer.GetAllPending();
        foreach (var ev in events)
        {
            SendToFirebase(ev);
        }
        _pendingBuffer.Clear();
    }

    private void SendToFirebase(TelemetryEvent ev)
    {
        // Actual Firebase implementation
        FirebaseAnalytics.LogEvent(ev.Name, ConvertToFirebaseParams(ev.Parameters));
    }
}
```

## Related Skills
- `@unity-async-patterns` - For handling cancellation and UniTask in dispatcher.
- `@unity-qa-generator` - For writing contract verification tests for analytic dispatchers.
