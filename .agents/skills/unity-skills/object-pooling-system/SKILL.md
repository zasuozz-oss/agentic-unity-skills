---
name: object-pooling-system
description: "Object pooling system for Unity. Use this when the user needs to reduce Instantiate/Destroy overhead for frequently spawned objects like bullets, VFX, enemies, or UI elements. Also trigger for: 'too many Instantiate calls', 'GC from spawning', 'bullet performance', 'reuse objects', 'spawn without allocation', or any question about reusing GameObjects — even if they don't say 'pool'. Do NOT use for asset memory management — use addressables-asset-management instead."
---

# Object Pooling System

## Overview
Reusable object pool to eliminate Instantiate/Destroy overhead. Use Unity's built-in ObjectPool<T> or custom solutions for GameObjects, VFX, UI, and any frequently spawned objects.

## When to Use
- Use for bullets, projectiles (spawned 10+ per second)
- Use for particle effects at impact points
- Use for damage number popups
- Use for spawned enemies in wave systems
- Use for any GameObject with high spawn/despawn frequency

## Pool Types

| Type | Use Case |
|------|----------|
| **Unity ObjectPool<T>** | C# objects (non-MonoBehaviour) |
| **Custom MonoBehaviour Pool** | GameObjects with components |
| **Component Pool** | UI elements, HUD items |

## Best Practices
- ✅ Pre-warm pools at scene start
- ✅ Use `IPoolable` interface for reset/configure lifecycle
- ✅ Set max pool size to prevent unbounded growth
- ✅ Return to pool instead of Destroy
- ✅ Disable (SetActive false) pooled objects
- ❌ **NEVER** pool objects that are rarely spawned (overhead > benefit)
- ❌ **NEVER** grow pool infinitely (set maxSize)
- ❌ **NEVER** forget to reset pooled objects before reuse

## Few-Shot Examples

### Example 1: Generic GameObject Pool
**User**: "Create a reusable pool for any prefab."

**Agent**:
```csharp
public class GameObjectPool : MonoBehaviour
{
    [SerializeField] private GameObject _prefab;
    [SerializeField] private int _initialSize = 10;
    [SerializeField] private int _maxSize = 50;

    private readonly Queue<GameObject> _pool = new();

    private void Awake()
    {
        for (int i = 0; i < _initialSize; i++)
        {
            var obj = CreateNew();
            obj.SetActive(false);
            _pool.Enqueue(obj);
        }
    }

    public GameObject Get(Vector3 position, Quaternion rotation)
    {
        GameObject obj;
        if (_pool.Count > 0)
        {
            obj = _pool.Dequeue();
        }
        else if (_pool.Count + GetActiveCount() < _maxSize)
        {
            obj = CreateNew();
        }
        else
        {
            Debug.LogWarning($"Pool for {_prefab.name} at max capacity ({_maxSize})");
            return null;
        }

        obj.transform.SetPositionAndRotation(position, rotation);
        obj.SetActive(true);

        if (obj.TryGetComponent<IPoolable>(out var poolable))
            poolable.OnSpawn();

        return obj;
    }

    public void Return(GameObject obj)
    {
        if (obj.TryGetComponent<IPoolable>(out var poolable))
            poolable.OnDespawn();

        obj.SetActive(false);
        _pool.Enqueue(obj);
    }

    private GameObject CreateNew()
    {
        var obj = Instantiate(_prefab, transform);
        return obj;
    }

    private int GetActiveCount()
    {
        return transform.childCount - _pool.Count;
    }
}

public interface IPoolable
{
    void OnSpawn();
    void OnDespawn();
}
```

### Example 2: Bullet Pool with Auto-Return
**User**: "Pool bullets that auto-return after timeout."

**Agent**:
```csharp
public class Bullet : MonoBehaviour, IPoolable
{
    [SerializeField] private float _speed = 20f;
    [SerializeField] private float _lifetime = 3f;

    private GameObjectPool _pool;
    private float _timer;

    public void Initialize(GameObjectPool pool)
    {
        _pool = pool;
    }

    public void OnSpawn()
    {
        _timer = _lifetime;
    }

    public void OnDespawn()
    {
        // Reset state for next use
        _timer = 0f;
    }

    private void Update()
    {
        transform.Translate(Vector3.forward * (_speed * Time.deltaTime));

        _timer -= Time.deltaTime;
        if (_timer <= 0f)
        {
            _pool.Return(gameObject);
        }
    }

    private void OnCollisionEnter(Collision collision)
    {
        if (collision.gameObject.TryGetComponent<IDamageable>(out var target))
            target.TakeDamage(10f);

        _pool.Return(gameObject);
    }
}
```

### Example 3: Unity Built-in ObjectPool for C# Objects
**User**: "Pool non-MonoBehaviour data objects."

**Agent**:
```csharp
using UnityEngine.Pool;

// Pool for plain C# objects (not GameObjects)
public class DamageEventPool
{
    private static readonly ObjectPool<DamageEvent> _pool = new(
        createFunc: () => new DamageEvent(),
        actionOnGet: evt => evt.Reset(),
        actionOnRelease: evt => { },
        actionOnDestroy: evt => { },
        defaultCapacity: 20,
        maxSize: 100
    );

    public static DamageEvent Get() => _pool.Get();
    public static void Release(DamageEvent evt) => _pool.Release(evt);
}

public class DamageEvent
{
    public float Amount;
    public Vector3 Position;
    public DamageType Type;
    public GameObject Source;

    public void Reset()
    {
        Amount = 0;
        Position = Vector3.zero;
        Type = DamageType.Physical;
        Source = null;
    }
}

// Usage:
// var evt = DamageEventPool.Get();
// evt.Amount = 50f;
// evt.Position = hitPoint;
// ProcessDamage(evt);
// DamageEventPool.Release(evt); // Return to pool
```

## When NOT to Pool
- Objects spawned fewer than 5 times per minute
- Objects with complex, hard-to-reset state
- Unique objects (player, boss)
- Objects that live the entire scene lifetime

## Related Skills
- `@performance-advisor` - When to use pooling
- `@vfx-graph-shuriken` - VFX pooling
- `@memory-profiler-expert` - Pool size tuning
