---
name: unity-startup-loading
description: "Use when working on app startup/loading screens, SDK initialization order, game data download, server time sync, or bugs mentioning stuck loading, slow first load, blocked startup, or crashes on game scene entry on low-end devices."
---

# Unity Startup & Loading Flow

## Overview
Guidelines for structuring the startup sequence of a live mobile game: SDK initialization, game data download, server time sync, and scene-entry task scheduling. Core principle: **no single SDK or API call may block the game from loading.**

## When to Use
- Modifying the loading controller / bootstrap sequence.
- Adding a new SDK init or a new API call during loading.
- Debugging stuck loading, long first load, or low-end device crashes when entering the game scene.
- Instrumenting the login → loaded funnel.

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Init/Data separation** | SDK initialization (Firebase, ads, attribution) runs in parallel with — never ahead of — game data download. |
| **Time-sync fallback** | Server world-time fetch must have a timeout and a local fallback; it is a classic single point of hang. |
| **Bounded parallelism** | Scene-entry task fan-out (`Task.WhenAll`-style) must be capped; unbounded parallel loads crash low-end devices. |
| **Funnel checkpoints** | Analytics events between each loading phase to locate silent user drop-off. |

## Best Practices
- ✅ **Always** wrap loading-phase API calls (world time, remote config, profile) with explicit timeouts and a defined fallback path.
- ✅ Keep SDK init failures non-fatal: the game must reach the menu even if an SDK fails to initialize.
- ✅ Cap concurrent downloads/instantiations on game-scene entry; queue the rest (low-end devices die on spikes, not totals).
- ✅ Fire funnel events at every phase boundary (login success → time sync → data ready → scene loaded) so drop-off is measurable.
- ✅ Keep loading status text order in sync with the actual phases — mismatched text hides where users are stuck.
- ❌ **NEVER** `await` an SDK init before starting the game data download.
- ❌ **NEVER** let a pre-game popup or analytics call block the loading chain.

## Few-Shot Examples

### Example 1: Time sync with timeout + fallback
**User**: "kiểm tra xem API get-worldtime bị treo có chặn game không, sửa để không bao giờ chặn"

**Agent**:
```csharp
public async UniTask<DateTime> GetWorldTimeAsync(CancellationToken ct)
{
    try
    {
        // Hard cap: a hanging time API must never block startup
        var cts = CancellationTokenSource.CreateLinkedTokenSource(ct);
        cts.CancelAfter(TimeSpan.FromSeconds(5));
        var serverTime = await _timeApi.FetchAsync(cts.Token);
        _offset = serverTime - DateTime.UtcNow;
        return serverTime;
    }
    catch (Exception)
    {
        // Fallback: local time + last known offset; flag as unsynced for anti-cheat checks
        IsServerSynced = false;
        return DateTime.UtcNow + _lastKnownOffset;
    }
}
```

## Related Skills
- `@unity-async-patterns` - Cancellation and UniTask usage in loading chains.
- `@unity-telemetry-analytics` - Pre-init event buffering and funnel instrumentation.
