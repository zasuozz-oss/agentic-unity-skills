---
name: async-strategy
description: "Unity async and lifecycle strategy advisor. Use this when the user needs to choose between Update, events, coroutines, UniTask, timers, or needs lifecycle cleanup and cancellation guidance."
---

# Async Strategy Advisor

> Adapted from [Besty0728/Unity-Skills](https://github.com/Besty0728/Unity-Skills) (MIT License)

Use this skill when deciding how runtime work should be scheduled or cleaned up.

## Decision Ladder

1. **Does the task need per-frame work at all?**
   - If not → prefer events, callbacks, or explicit method calls
2. **Short Unity-bound sequence?**
   - → Prefer coroutine
3. **Complex async flow with error handling?**
   - → Consider UniTask **only when** project already uses it or user explicitly wants it
4. **True continuous simulation or polling?**
   - → Use Update

**Do not recommend UniTask just because it looks more advanced than coroutine.**

## Scheduling Model Comparison

| Model | Best For | Lifecycle |
|-------|----------|-----------|
| **Events/Callbacks** | One-shot reactions | Subscribe/unsubscribe |
| **Coroutine** | Sequenced Unity work | StopCoroutine in OnDisable |
| **UniTask** | Complex async with cancellation | CancellationToken |
| **Update** | Continuous simulation, input | Always running |
| **InvokeRepeating/Timer** | Simple periodic work | CancelInvoke |

## Lifecycle Rules

- Always define **who starts**, **who cancels**, and **when cleanup happens**
- In MonoBehaviour: prefer `OnEnable`/`OnDisable`/`OnDestroy` for subscribe symmetry
- Use `IDisposable` for pure C# lifetimes, not as cargo-cult Unity replacement
- Cache references used in hot paths

## Output Format

- Recommended scheduling model
- Why it fits
- Lifecycle / cancellation owner
- Hot-path risks
- Why the heavier alternative is unnecessary

## Related Skills
- `@asynchronous-programming` - Deep async implementation patterns
- `@performance-advisor` - Hot-path analysis
