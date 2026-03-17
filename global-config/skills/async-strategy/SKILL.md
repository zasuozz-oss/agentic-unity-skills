---
name: async-strategy
description: "Unity async scheduling decision advisor. Use this skill BEFORE writing any async code to decide the right approach. Trigger for: 'should I use coroutine or UniTask', 'when to use Update vs events', 'how to schedule recurring work', 'async cleanup not working', or any question about which scheduling model to pick. Do NOT use for implementation details — use asynchronous-programming instead."
---

# Async Strategy Advisor

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

## Few-Shot Examples

### Example 1: Simple Delay
**User**: "I need to wait 2 seconds then spawn an enemy."

**Agent**:
Recommended: Coroutine
Why: Short Unity-bound sequence, no error handling needed, simple lifecycle.
Lifecycle owner: SpawnerController starts and stops in OnDisable.
Why not UniTask: No cancellation complexity, no external async dependencies.

### Example 2: Multiple API Calls
**User**: "I need to fetch player data, then inventory, then apply both before showing UI."

**Agent**:
Recommended: UniTask
Why: Complex async chain with multiple awaits, error handling needed per step.
Lifecycle owner: CancellationTokenSource tied to OnDestroy.
Why not Coroutine: No try/catch in coroutines, chaining is messy.
Hot-path risk: None — UI flow, not per-frame.

### Example 3: Polling Server Status
**User**: "Check server ping every 5 seconds."

**Agent**:
Recommended: InvokeRepeating or a simple Timer
Why: Periodic work, no sequencing, no Unity lifecycle dependency.
Lifecycle owner: CancelInvoke in OnDisable.
Why not Update: Unnecessary per-frame overhead for a 5s interval task.

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
