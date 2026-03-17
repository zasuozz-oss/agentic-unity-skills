---
name: design-patterns
description: "SOLID principles and GoF design patterns for Unity. Use this when the user is working with design patterns, refactoring code for maintainability, applying SRP, Factory, Observer, Command, or Strategy patterns, or decoupling tightly-coupled systems. Also trigger for: 'this class does too much', 'how to apply SOLID', 'factory pattern in Unity', 'command pattern for undo', or any question about writing clean, extensible code — even if they don't say 'design pattern'. Do NOT use for choosing between patterns — use pattern-selector instead."
---

# Design Patterns (Unity)

## Overview
Practical SOLID principles and GoF (Gang of Four) patterns adapted for Unity game development. Focus on patterns that solve real Unity problems.

## Architecture Layers
```
Presentation (UI / Visuals)
       ↓
Game Logic (State, Rules)
       ↓
Infrastructure (Save, Audio, Network)
       ↓
Core (Interfaces, Data, Events)
```

## Thinking Process

1. Identify the **specific pain** (tight coupling? hard to extend? hard to test?)
2. Consider the **simplest solution** first (often just an interface)
3. Apply a pattern **only if it reduces complexity**
4. **Don't** pattern-match for the sake of it

## Key Patterns for Unity

| Pattern | Unity Use Case |
|---------|---------------|
| **Strategy** | Swappable AI behaviors, weapon types |
| **Factory** | Object creation with validation |
| **Observer** | Event-driven communication |
| **Command** | Undo/redo, input replay, action queue |
| **State** | Character/game state management |

## Best Practices
- ✅ Start with interfaces, add patterns when needed
- ✅ One responsibility per class (SRP)
- ✅ Depend on abstractions, not concrete types (DIP)
- ✅ Favor composition over inheritance
- ❌ **NEVER** force patterns onto simple problems
- ❌ **NEVER** create AbstractFactoryProviderManagerBase

## Few-Shot Examples

### Example 1: Strategy Pattern — Swappable AI Behaviors
**User**: "My enemies all behave differently but share the same controller."

**Agent**:
```csharp
// Strategy interface
public interface IAttackBehavior
{
    void Execute(Transform attacker, Transform target);
}

// Concrete strategies
public class MeleeAttack : IAttackBehavior
{
    private readonly float _damage;
    private readonly float _range;

    public MeleeAttack(float damage, float range)
    {
        _damage = damage;
        _range = range;
    }

    public void Execute(Transform attacker, Transform target)
    {
        if (Vector3.Distance(attacker.position, target.position) <= _range)
        {
            target.GetComponent<IDamageable>()?.TakeDamage(_damage);
        }
    }
}

public class RangedAttack : IAttackBehavior
{
    private readonly GameObject _projectilePrefab;
    private readonly float _speed;

    public RangedAttack(GameObject projectilePrefab, float speed)
    {
        _projectilePrefab = projectilePrefab;
        _speed = speed;
    }

    public void Execute(Transform attacker, Transform target)
    {
        var proj = Object.Instantiate(_projectilePrefab, attacker.position, Quaternion.identity);
        var dir = (target.position - attacker.position).normalized;
        proj.GetComponent<Rigidbody>().velocity = dir * _speed;
    }
}

// Context — uses any strategy
public class EnemyController : MonoBehaviour
{
    private IAttackBehavior _attackBehavior;

    public void SetAttackBehavior(IAttackBehavior behavior) => _attackBehavior = behavior;

    public void Attack(Transform target) => _attackBehavior.Execute(transform, target);
}
```

### Example 2: SRP Violation Fix
**User**: "My PlayerManager handles health, inventory, and UI."

**Agent**:
```csharp
// ❌ BEFORE: God class violating SRP
public class PlayerManager : MonoBehaviour
{
    public void TakeDamage(float amount) { /* health logic */ }
    public void AddItem(Item item) { /* inventory logic */ }
    public void UpdateHealthBar() { /* UI logic */ }
    public void SaveProgress() { /* save logic */ }
}

// ✅ AFTER: Separated responsibilities
public class PlayerHealth : MonoBehaviour
{
    private float _currentHealth;
    public event Action<float> OnHealthChanged;

    public void TakeDamage(float amount)
    {
        _currentHealth -= amount;
        OnHealthChanged?.Invoke(_currentHealth);
    }
}

public class PlayerInventory
{
    private readonly List<Item> _items = new();
    public event Action<Item> OnItemAdded;

    public void AddItem(Item item)
    {
        _items.Add(item);
        OnItemAdded?.Invoke(item);
    }
}

public class HealthBarUI : MonoBehaviour
{
    [SerializeField] private PlayerHealth _health;

    private void OnEnable() => _health.OnHealthChanged += UpdateBar;
    private void OnDisable() => _health.OnHealthChanged -= UpdateBar;
    private void UpdateBar(float health) { /* update slider */ }
}
```

### Example 3: Command Pattern — Undo System
**User**: "Need undo/redo for a level editor."

**Agent**:
```csharp
public interface ICommand
{
    void Execute();
    void Undo();
}

public class PlaceBlockCommand : ICommand
{
    private readonly Vector3Int _position;
    private readonly BlockType _blockType;
    private readonly LevelGrid _grid;
    private BlockType _previousBlock;

    public PlaceBlockCommand(LevelGrid grid, Vector3Int position, BlockType blockType)
    {
        _grid = grid;
        _position = position;
        _blockType = blockType;
    }

    public void Execute()
    {
        _previousBlock = _grid.GetBlock(_position);
        _grid.SetBlock(_position, _blockType);
    }

    public void Undo()
    {
        _grid.SetBlock(_position, _previousBlock);
    }
}

public class CommandHistory
{
    private readonly Stack<ICommand> _undoStack = new();
    private readonly Stack<ICommand> _redoStack = new();

    public void Execute(ICommand command)
    {
        command.Execute();
        _undoStack.Push(command);
        _redoStack.Clear();
    }

    public void Undo()
    {
        if (_undoStack.Count == 0) return;
        var cmd = _undoStack.Pop();
        cmd.Undo();
        _redoStack.Push(cmd);
    }

    public void Redo()
    {
        if (_redoStack.Count == 0) return;
        var cmd = _redoStack.Pop();
        cmd.Execute();
        _undoStack.Push(cmd);
    }
}
```

## Code Smells to Avoid
- God class (500+ lines)
- Switch on type (use polymorphism)
- Deep inheritance (>3 levels)
- Premature abstraction (interface for only 1 implementation)

## Related Skills
- `@pattern-selector` - Choosing between patterns
- `@architecture-advisor` - Project-level design
- `@script-design-review` - Script quality review
