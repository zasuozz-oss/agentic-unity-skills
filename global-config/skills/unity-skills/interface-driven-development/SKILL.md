---
name: interface-driven-development
description: "Interface-driven development for Unity. Use this when the user needs to extract interfaces for loose coupling, design dependency boundaries, implement IDamageable/IInteractable/ISaveable patterns, or prepare code for dependency injection. Also trigger for: 'how to decouple this', 'my scripts depend on concrete classes', 'interface for enemy and player health', 'TryGetComponent pattern', or any question about using interfaces to break dependencies — even if they don't say 'interface'."
---

# Interface-Driven Development

## Overview
Reduces coupling by designing around interfaces rather than concrete types. Essential for large projects, team work, and testability.

## When to Use
- Use when multiple implementations exist (IDamageable on Player AND Enemy)
- Use when systems communicate across module boundaries
- Use when preparing for DI or mock testing
- Use when you need polymorphism without inheritance

## Core Interfaces in Games

| Interface | Implementors | Benefit |
|-----------|-------------|---------|
| `IDamageable` | Player, Enemy, Barrel | Uniform damage system |
| `IInteractable` | Door, Chest, NPC | Generic interaction |
| `ISaveable` | Inventory, Quests, Stats | Uniform save/load |
| `IPoolable` | Bullet, VFX, Enemy | Pool lifecycle hooks |

## Best Practices
- ✅ Interfaces describe **capabilities**, not identity
- ✅ Keep interfaces small (Interface Segregation Principle)
- ✅ Use `TryGetComponent<T>` for safe interface lookups
- ✅ Name interfaces with I + capability (IDamageable, IInteractable)
- ❌ **NEVER** create `IPlayerManager` that mirrors one concrete class
- ❌ **NEVER** put Unity lifecycle methods in interfaces
- ❌ **NEVER** create interfaces for classes with a single implementation (unless for DI/testing)

## Few-Shot Examples

### Example 1: IDamageable — Uniform Damage System
**User**: "My weapon needs to damage players, enemies, and barrels."

**Agent**:
```csharp
public interface IDamageable
{
    void TakeDamage(float amount);
    bool IsAlive { get; }
}

// Player implements IDamageable
public class PlayerHealth : MonoBehaviour, IDamageable
{
    [SerializeField] private float _maxHealth = 100f;
    private float _currentHealth;
    public bool IsAlive => _currentHealth > 0;

    private void Start() => _currentHealth = _maxHealth;

    public void TakeDamage(float amount)
    {
        _currentHealth -= amount;
        if (_currentHealth <= 0) Die();
    }

    private void Die() { /* death logic */ }
}

// Barrel also implements IDamageable
public class ExplodingBarrel : MonoBehaviour, IDamageable
{
    public bool IsAlive => !_hasExploded;
    private bool _hasExploded;

    public void TakeDamage(float amount)
    {
        if (_hasExploded) return;
        _hasExploded = true;
        Explode();
    }

    private void Explode() { /* explosion VFX + area damage */ }
}

// Weapon doesn't care WHAT it hits — just IDamageable
public class Weapon : MonoBehaviour
{
    [SerializeField] private float _damage = 10f;

    public void OnHit(Collider other)
    {
        if (other.TryGetComponent<IDamageable>(out var target) && target.IsAlive)
        {
            target.TakeDamage(_damage);
        }
    }
}
```

### Example 2: IInteractable — Generic Interaction
**User**: "Player should interact with doors, chests, and NPCs with the same button."

**Agent**:
```csharp
public interface IInteractable
{
    string InteractionPrompt { get; }
    bool CanInteract { get; }
    void Interact(PlayerController player);
}

public class Door : MonoBehaviour, IInteractable
{
    public string InteractionPrompt => _isLocked ? "Locked" : "Open Door";
    public bool CanInteract => !_isLocked;
    private bool _isLocked;

    public void Interact(PlayerController player) { /* open/close door */ }
}

public class NPC : MonoBehaviour, IInteractable
{
    public string InteractionPrompt => "Talk";
    public bool CanInteract => true;

    public void Interact(PlayerController player) { /* start dialogue */ }
}

// PlayerInteractor — scans for IInteractable
public class PlayerInteractor : MonoBehaviour
{
    [SerializeField] private float _interactRange = 2f;
    [SerializeField] private LayerMask _interactLayer;

    private IInteractable _currentTarget;

    private void Update()
    {
        ScanForInteractable();
        if (_currentTarget != null && _currentTarget.CanInteract && Input.GetKeyDown(KeyCode.E))
        {
            _currentTarget.Interact(GetComponent<PlayerController>());
        }
    }

    private void ScanForInteractable()
    {
        var hits = Physics.OverlapSphere(transform.position, _interactRange, _interactLayer);
        _currentTarget = null;
        foreach (var hit in hits)
        {
            if (hit.TryGetComponent<IInteractable>(out var interactable) && interactable.CanInteract)
            {
                _currentTarget = interactable;
                break;
            }
        }
    }
}
```

### Example 3: Interface Segregation — Small Interfaces
**User**: "My IEntity interface has 12 methods. Is this right?"

**Agent**:
```csharp
// ❌ BEFORE: Interface Segregation violation
public interface IEntity
{
    void TakeDamage(float amount);
    void Heal(float amount);
    void Move(Vector3 dir);
    void Attack(IEntity target);
    void Die();
    void Save();
    void Load();
    void PlayAnimation(string name);
    // ... 4 more
}

// ✅ AFTER: Split into focused capabilities
public interface IDamageable
{
    void TakeDamage(float amount);
    bool IsAlive { get; }
}

public interface IHealable
{
    void Heal(float amount);
}

public interface IMovable
{
    void Move(Vector3 direction);
}

public interface ISaveable
{
    string SaveId { get; }
    object CaptureState();
    void RestoreState(object state);
}

// Player implements only what it needs
public class Player : MonoBehaviour, IDamageable, IHealable, IMovable, ISaveable
{
    // Each interface is small and focused
    public bool IsAlive => _health > 0;
    public void TakeDamage(float amount) { /* ... */ }
    public void Heal(float amount) { /* ... */ }
    public void Move(Vector3 direction) { /* ... */ }
    public string SaveId => "player";
    public object CaptureState() => new PlayerSaveData();
    public void RestoreState(object state) { /* ... */ }
}
```

## Related Skills
- `@design-patterns` - Pattern implementations with interfaces
- `@script-design-review` - Script quality and testability
- `@design-patterns` - Strategy/Observer with interfaces
