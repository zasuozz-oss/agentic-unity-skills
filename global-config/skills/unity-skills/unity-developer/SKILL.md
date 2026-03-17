---
name: unity-developer
description: "General Unity development expertise and project overview. Use this as a foundational skill for any Unity development question that doesn't fit a more specific skill. Also trigger for: 'how to do X in Unity', 'Unity best practices', 'project setup', 'component structure', 'MonoBehaviour basics', or any general Unity development question. This is the catch-all skill — only use when no more specific skill applies."
---

# Unity Developer

## Overview
Comprehensive Unity development expertise covering project architecture, component design, scripting fundamentals, and cross-platform best practices. This is the foundational "catch-all" skill.

## Scope
Use this skill:
- For general Unity questions not covered by specialized skills
- For project setup and initial architecture
- For fundamentals (component lifecycle, serialization, prefabs)
- For multi-system integration guidance

## Unity API Key Points

### MonoBehaviour Lifecycle
```
Constructor → Awake → OnEnable → Start → Update → FixedUpdate → LateUpdate → OnDisable → OnDestroy
```

### Common Patterns

| Pattern | Use |
|---------|-----|
| `[SerializeField] private` | Inspector-assignable fields |
| `GetComponent<T>` (cached) | Access sibling components |
| `TryGetComponent<T>` | Safe component lookup |
| `CompareTag` | Compare tags (not `==`) |
| `destroyCancellationToken` | Auto-cancel async on destroy |

## Project Best Practices
- ✅ Use Assembly Definitions for large projects
- ✅ Organize by feature, not by type
- ✅ Use `[RequireComponent]` for dependencies
- ✅ Cache component references in `Awake`
- ✅ Prefer composition over inheritance
- ❌ **NEVER** use `Find` or `FindObjectOfType` in Update
- ❌ **NEVER** use public fields (use [SerializeField] private)
- ❌ **NEVER** put game logic in UI scripts

## Few-Shot Examples

### Example 1: Proper MonoBehaviour Structure
**User**: "Create a basic enemy script."

**Agent**:
```csharp
[RequireComponent(typeof(Rigidbody))]
public class Enemy : MonoBehaviour
{
    [Header("Configuration")]
    [SerializeField] private float _moveSpeed = 3f;
    [SerializeField] private float _maxHealth = 50f;

    [Header("References")]
    [SerializeField] private ParticleSystem _deathVFX;

    private Rigidbody _rb;
    private float _currentHealth;
    private bool _isDead;

    private void Awake()
    {
        _rb = GetComponent<Rigidbody>();
        _currentHealth = _maxHealth;
    }

    private void FixedUpdate()
    {
        if (_isDead) return;
        MoveTowardsTarget();
    }

    public void TakeDamage(float amount)
    {
        if (_isDead) return;

        _currentHealth -= amount;
        if (_currentHealth <= 0f)
        {
            Die();
        }
    }

    private void Die()
    {
        _isDead = true;
        if (_deathVFX != null)
        {
            _deathVFX.transform.SetParent(null);
            _deathVFX.Play();
        }
        Destroy(gameObject);
    }

    private void MoveTowardsTarget()
    {
        // Movement logic
    }
}
```

### Example 2: Component Communication
**User**: "How should scripts talk to each other?"

**Agent**:
```csharp
// ✅ GOOD: Interface-based communication
public interface IDamageable
{
    void TakeDamage(float amount);
}

// Weapon doesn't know about Enemy or Player — just IDamageable
public class Weapon : MonoBehaviour
{
    [SerializeField] private float _damage = 10f;

    private void OnTriggerEnter(Collider other)
    {
        if (other.TryGetComponent<IDamageable>(out var target))
        {
            target.TakeDamage(_damage);
        }
    }
}

// ❌ BAD: Direct concrete references
// public class Weapon : MonoBehaviour
// {
//     void OnTriggerEnter(Collider other)
//     {
//         var enemy = other.GetComponent<Enemy>(); // Tight coupling!
//     }
// }
```

### Example 3: Cached Component References
**User**: "Show correct component caching."

**Agent**:
```csharp
public class PlayerController : MonoBehaviour
{
    // ❌ BAD: GetComponent every frame
    private void Update_Bad()
    {
        GetComponent<Rigidbody>().velocity = Vector3.zero; // GC + slow
    }

    // ✅ GOOD: Cache in Awake
    private Rigidbody _rb;
    private Animator _animator;

    private void Awake()
    {
        _rb = GetComponent<Rigidbody>();
        _animator = GetComponent<Animator>();
    }

    private void FixedUpdate()
    {
        _rb.velocity = CalculateVelocity(); // No GC, fast
    }
}
```

## Folder Structure (Recommended)
```
Assets/
├── _Project/
│   ├── Scripts/
│   │   ├── Player/
│   │   ├── Enemy/
│   │   ├── UI/
│   │   └── Core/
│   ├── Prefabs/
│   ├── Materials/
│   ├── Textures/
│   └── Audio/
├── Plugins/
└── Editor/
```

## Related Skills
- `@architecture-advisor` - Project architecture guidance
- `@my-csharp-conventions` - Naming and style
- `@design-patterns` - Patterns for Unity
- `@performance-advisor` - Performance optimization
