---
name: event-bus-system
description: "Global event bus implementation for decoupled communication. Use this when the user needs a publish/subscribe system, global notifications, cross-system communication without direct references. Also trigger for: 'how to decouple systems', 'pass data between unrelated scripts', 'global messaging', 'publish subscribe pattern', or any question about communication between systems that don't know each other — even if they don't say 'event bus'. Do NOT use for inspector-assignable SO events — use scriptableobject-architecture instead."
---

# Event Bus System

## Overview
A lightweight, type-safe global event system for decoupled communication between Unity systems. Messages are strongly-typed structs, avoiding string-based keys.

## When to Use
- Use for system-to-system communication (Achievement → UI, Audio, Analytics)
- Use when multiple unrelated systems need the same notification
- Use when publisher doesn't know (or shouldn't know) about its listeners
- Use when coupling is a bigger concern than traceability

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     EVENT BUS                                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  PUBLISHERS                    BUS              SUBSCRIBERS  │
│  ┌──────────┐              ┌──────┐           ┌──────────┐  │
│  │ CombatSys│── Raise() ──▶│ Bus  │── Fire ──▶│ AudioMgr │  │
│  │          │              │      │           │ UIMgr    │  │
│  └──────────┘              │      │           │ Analytics│  │
│                            └──────┘           └──────────┘  │
│                                                              │
│  Events are structs — zero GC, type-safe, inspectable       │
└─────────────────────────────────────────────────────────────┘
```

## Event Types

| Type | Use Case |
|------|----------|
| **Fire-and-forget** | Notifications (EnemyDied, LevelComplete) |
| **Request-response** | Queries (GetPlayerPosition) |
| **Buffered** | Late subscribers get last event (ScoreChanged) |

## Best Practices
- ✅ Events are `readonly struct` (zero GC)
- ✅ Subscribe in `OnEnable`, unsubscribe in `OnDisable`
- ✅ Keep events small (data, not behavior)
- ✅ Use namespaces to group related events
- ❌ **NEVER** use for everything — direct references are often better
- ❌ **NEVER** put logic in the event struct
- ❌ **NEVER** forget to unsubscribe (memory leak + ghost listeners)

## Few-Shot Examples

### Example 1: Type-Safe Event Bus
**User**: "Create a global event system."

**Agent**:
```csharp
public static class EventBus<T> where T : struct
{
    private static readonly HashSet<Action<T>> _listeners = new();

    public static void Subscribe(Action<T> listener) => _listeners.Add(listener);
    public static void Unsubscribe(Action<T> listener) => _listeners.Remove(listener);

    public static void Raise(T eventData)
    {
        // Copy to avoid modification during iteration
        foreach (var listener in _listeners.ToArray())
        {
            listener.Invoke(eventData);
        }
    }

    public static void Clear() => _listeners.Clear();
}
```

### Example 2: Event Definition and Usage
**User**: "Notify UI and audio when an enemy dies."

**Agent**:
```csharp
// Event definition — readonly struct, zero GC
public readonly struct EnemyDiedEvent
{
    public readonly Vector3 Position;
    public readonly int ScoreValue;
    public readonly string EnemyType;

    public EnemyDiedEvent(Vector3 position, int scoreValue, string enemyType)
    {
        Position = position;
        ScoreValue = scoreValue;
        EnemyType = enemyType;
    }
}

// Publisher: Enemy.cs — raises the event on death
public class Enemy : MonoBehaviour
{
    [SerializeField] private int _scoreValue = 100;

    public void Die()
    {
        EventBus<EnemyDiedEvent>.Raise(
            new EnemyDiedEvent(transform.position, _scoreValue, "Goblin"));
        gameObject.SetActive(false);
    }
}

// Subscriber: ScoreUI.cs — listens for enemy deaths
public class ScoreUI : MonoBehaviour
{
    private int _totalScore;

    private void OnEnable() => EventBus<EnemyDiedEvent>.Subscribe(OnEnemyDied);
    private void OnDisable() => EventBus<EnemyDiedEvent>.Unsubscribe(OnEnemyDied);

    private void OnEnemyDied(EnemyDiedEvent e)
    {
        _totalScore += e.ScoreValue;
        _scoreText.text = _totalScore.ToString();
    }
}
```

### Example 3: Event Bus with Cleanup
**User**: "How to prevent dangling listeners on scene unload?"

**Agent**:
```csharp
// EventBus cleanup helper — call on scene transitions
public static class EventBusCleanup
{
    public static void ClearAll()
    {
        EventBus<EnemyDiedEvent>.Clear();
        EventBus<PlayerDamagedEvent>.Clear();
        EventBus<LevelCompleteEvent>.Clear();
        // Add all event types here
    }
}

// In SceneLoader:
public class SceneLoader : MonoBehaviour
{
    public async UniTask LoadScene(string sceneName, CancellationToken ct)
    {
        EventBusCleanup.ClearAll(); // Prevent ghost listeners
        await SceneManager.LoadSceneAsync(sceneName);
    }
}
```

## Related Skills
- `@scriptableobject-architecture` - Inspector-assignable SO event channels
- `@design-patterns` - Observer pattern fundamentals
- `@architecture-advisor` - When to use bus vs direct reference
