---
name: async-strategy
description: "Async scheduling strategy advisor for Unity. Use this when the user needs to choose between Coroutines, UniTask, Update polling, or event-driven patterns. Also trigger for: 'should I use coroutine or async', 'UniTask vs coroutine', 'which async pattern', 'timer implementation', 'delay without coroutine', or any question about choosing the right async scheduling model — even if they don't say 'async'. Do NOT use for UniTask/async implementation details — use asynchronous-programming instead."
---

# Async Strategy Advisor

## Purpose

Choose the right async scheduling model per use case. Not everything needs the same tool.

## Decision Ladder

| Need | Tool | Why |
|------|------|-----|
| Simple delay (one-off) | Coroutine / UniTask.Delay | Lightweight, lifecycle-managed |
| Sequential async chain | UniTask / async-await | Readable, cancellable |
| Periodic polling | Update + timer | No coroutine overhead |
| React to state changes | C# events / UnityEvent | No polling, zero-cost when idle |
| Frame-aligned updates | Update / LateUpdate | Deterministic, profiler-visible |

## Risk Awareness

| Anti-Pattern | Risk Level |
|-------------|:----------:|
| Coroutine started in Update | ⚠️ Leak |
| UniTask without CancellationToken | ⚠️ Ghost task |
| WaitForSeconds in tight loop | ⚠️ GC |
| async void (not UniTaskVoid) | 🔴 Silent failure |

## Few-Shot Examples

### Example 1: Simple Delay
**User**: "Wait 2 seconds then show a popup."

**Agent**:
```csharp
// Option A: Coroutine (simplest, no extra packages)
private IEnumerator ShowPopupAfterDelay()
{
    yield return new WaitForSeconds(2f);
    _popup.SetActive(true);
}

// Option B: UniTask (if UniTask is already in the project)
private async UniTaskVoid ShowPopupAfterDelay(CancellationToken ct)
{
    await UniTask.Delay(TimeSpan.FromSeconds(2), cancellationToken: ct);
    _popup.SetActive(true);
}

// Which to use: If UniTask is in the project, prefer it for CancellationToken.
// Otherwise, Coroutine is perfectly fine for simple delays.
```

### Example 2: Sequential API Calls
**User**: "Login → Fetch profile → Fetch inventory, in order."

**Agent**:
```csharp
// ❌ Coroutine: nested callbacks, error handling is messy
// ✅ UniTask: clean sequential flow with try/catch
private async UniTask InitializePlayerAsync(CancellationToken ct)
{
    try
    {
        var token = await AuthService.LoginAsync(ct);
        var profile = await ProfileService.FetchAsync(token, ct);
        var inventory = await InventoryService.FetchAsync(profile.Id, ct);

        _playerData.Initialize(profile, inventory);
    }
    catch (OperationCanceledException)
    {
        Debug.Log("Initialization cancelled (scene unloaded)");
    }
    catch (Exception e)
    {
        Debug.LogError($"Init failed: {e.Message}");
        ShowRetryDialog();
    }
}
```

### Example 3: Periodic Polling vs Event
**User**: "Check if enemies are nearby every 0.5s."

**Agent**:
```csharp
// Option A: Update + timer (best for periodic checks)
private float _scanTimer;

private void Update()
{
    _scanTimer += Time.deltaTime;
    if (_scanTimer < 0.5f) return;
    _scanTimer = 0f;

    ScanForEnemies(); // Runs every 0.5s, no coroutine overhead
}

// Option B: Event-driven (best if enemies announce themselves)
// No polling at all — react to events
private void OnEnable() => EnemyRegistry.OnEnemySpawned += CheckThreat;
private void OnDisable() => EnemyRegistry.OnEnemySpawned -= CheckThreat;

// Which to use:
// - Update+timer: when you need to CHECK something periodically
// - Events: when something NOTIFIES you of changes
```

## Guardrails
- ✅ Always pair UniTask with CancellationToken (destroy safety)
- ✅ Stop coroutines in OnDisable/OnDestroy
- ✅ Use `destroyCancellationToken` for MonoBehaviour-bound tasks
- ❌ **NEVER** use `async void` — use `async UniTaskVoid` or `async UniTask`
- ❌ **NEVER** start coroutines from within Update without a guard

## Related Skills
- `@asynchronous-programming` - Full async/UniTask implementation details
- `@performance-advisor` - Hot-path risk assessment
- `@design-patterns` - Observer pattern for event-driven code
