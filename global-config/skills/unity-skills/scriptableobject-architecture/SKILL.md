---
name: scriptableobject-architecture
description: "Data-driven design using ScriptableObjects. Use this when the user needs SO-based event channels, runtime sets, game configuration data, shared variables, data-driven architecture, or modular design with ScriptableObjects. Also trigger for: 'where to store game config', 'inspector data for enemies', 'shared data between prefabs', 'SO event system', or any question about using ScriptableObjects as data containers or event channels — even if they don't say 'ScriptableObject'."
---

# ScriptableObject Architecture

## Overview
Decouple gameplay data and signals from MonoBehaviour logic using ScriptableObjects as the "Single Source of Truth" for design constants and event broadcasting.

## When to Use
- Use when creating inspector-configurable game data (stats, costs, timings)
- Use when implementing SO-based event channels (alternative to static EventBus)
- Use when tracking active objects without GameObject.Find (Runtime Sets)
- Use when sharing data between scenes or objects
- Use when designers need to tweak values without code changes

## Architecture

### Data-Driven Configuration
```
┌─────────────────────────────────────────────────────────────┐
│                    ScriptableObject Asset                   │
│                     (WeaponConfigSO)                        │
├─────────────────────────────────────────────────────────────┤
│  [SerializeField] private float _damage = 10f;              │
│  [SerializeField] private float _fireRate = 0.5f;           │
│  [SerializeField] private GameObject _projectilePrefab;     │
│                                                             │
│  public float Damage => _damage;                            │
│  public float FireRate => _fireRate;                        │
└─────────────────────────────────────────────────────────────┘
                              ↓
      Shared by multiple weapons without duplication
```

### Event Channels
```
┌──────────────┐           ┌──────────────────┐
│   Trigger    │  Raise()  │   GameEventSO    │
│ (Door opens) │ ─────────→│ (OnDoorOpened)   │
└──────────────┘           └────────┬─────────┘
                                    │
              ┌─────────────────────┼─────────────────────┐
              ↓                     ↓                     ↓
      ┌───────────────┐    ┌───────────────┐    ┌───────────────┐
      │  AudioManager │    │  UI Manager   │    │  Quest System │
      │  (Listener)   │    │  (Listener)   │    │  (Listener)   │
      └───────────────┘    └───────────────┘    └───────────────┘
```

## Components

| Component | Purpose |
|-----------|---------|
| `GameEventSO` | SO-based event for inspector-assignable broadcasts |
| `GameEventListener` | MonoBehaviour that listens to GameEventSO |
| `RuntimeSetSO<T>` | Dynamic collection of active objects |
| `ConfigSO` | Base for configuration data containers |

## Best Practices
- ✅ Use `[SerializeField] private` with public getters
- ✅ Include validation attributes (`[Range]`, `[Min]`)
- ✅ Use `[CreateAssetMenu]` with hierarchical paths
- ✅ Reset runtime data in `OnDisable` for editor play mode
- ✅ Keep SO as data containers, NOT execution logic
- ❌ **NEVER** put Update loops in ScriptableObjects
- ❌ **NEVER** store direct MonoBehaviour references in persistent SOs
- ❌ **NEVER** use heavy assets (textures) directly (use AssetReference)

## Few-Shot Examples

### Example 1: Weapon Configuration
**User**: "Create configurable weapon stats for the RPG."

**Agent**:
```csharp
[CreateAssetMenu(menuName = "Game/Combat/WeaponConfig")]
public class WeaponConfigSO : ScriptableObject
{
    [Header("Damage")]
    [SerializeField, Min(1)] private float _baseDamage = 10f;
    [SerializeField] private DamageType _damageType;

    [Header("Timing")]
    [SerializeField, Range(0.1f, 2f)] private float _attackSpeed = 1f;

    public float BaseDamage => _baseDamage;
    public DamageType DamageType => _damageType;
    public float AttackSpeed => _attackSpeed;
}
```

### Example 2: SO Event Channel (Inspector-Wired)
**User**: "Door should play sound and update UI without coupling."

**Agent**:
```csharp
// GameEventSO — the event channel asset
[CreateAssetMenu(menuName = "Game/Events/Game Event")]
public class GameEventSO : ScriptableObject
{
    private readonly List<GameEventListener> _listeners = new();

    public void Raise()
    {
        // Iterate backwards for safe removal during iteration
        for (int i = _listeners.Count - 1; i >= 0; i--)
            _listeners[i].OnEventRaised();
    }

    public void Register(GameEventListener listener) => _listeners.Add(listener);
    public void Unregister(GameEventListener listener) => _listeners.Remove(listener);
}

// GameEventListener — MonoBehaviour that subscribes in Inspector
public class GameEventListener : MonoBehaviour
{
    [SerializeField] private GameEventSO _event;
    [SerializeField] private UnityEvent _response;

    private void OnEnable() => _event.Register(this);
    private void OnDisable() => _event.Unregister(this);

    public void OnEventRaised() => _response.Invoke();
}

// Usage: Door.cs calls _onDoorOpenedEvent.Raise()
// AudioManager and UI each have GameEventListener pointing to same SO
```

### Example 3: Runtime Set
**User**: "Track all active enemies for wave completion check."

**Agent**:
```csharp
[CreateAssetMenu(menuName = "Game/Runtime/RuntimeSet")]
public class RuntimeSetSO<T> : ScriptableObject
{
    private readonly List<T> _items = new();
    public IReadOnlyList<T> Items => _items;
    public int Count => _items.Count;

    public void Add(T item)
    {
        if (!_items.Contains(item)) _items.Add(item);
    }

    public void Remove(T item) => _items.Remove(item);

    private void OnDisable() => _items.Clear(); // Reset for editor play mode
}

// Concrete type for enemies
[CreateAssetMenu(menuName = "Game/Runtime/EnemySet")]
public class EnemyRuntimeSetSO : RuntimeSetSO<Enemy> { }

// Enemy.cs — self-registering
public class Enemy : MonoBehaviour
{
    [SerializeField] private EnemyRuntimeSetSO _enemySet;

    private void OnEnable() => _enemySet.Add(this);
    private void OnDisable() => _enemySet.Remove(this);
}

// WaveManager.cs — queries the set
public class WaveManager : MonoBehaviour
{
    [SerializeField] private EnemyRuntimeSetSO _enemySet;
    public bool IsWaveComplete => _enemySet.Count == 0;
}
```

## Related Skills
- `@event-bus-system` - Static alternative to SO events
- `@design-patterns` - Patterns using SO data
- `@di-container-manager` - Injecting SO dependencies

## Template Files
- `templates/GameEventSO.cs.txt` - Event channel
- `templates/GameEventListener.cs.txt` - Event listener
- `templates/RuntimeSetSO.cs.txt` - Active object tracking
