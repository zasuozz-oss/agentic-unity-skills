---
name: design-patterns
description: "SOLID principles and GoF design patterns for Unity C#. Use this when the user needs Strategy, Factory, Observer, Command patterns, refactoring God Classes, clean architecture, or class design guidance."
---

# Design Patterns for Unity

## Overview
Transform gameplay requirements into modular, testable, and maintainable systems. Covers SOLID principles, GoF patterns adapted for Unity's lifecycle, and clean architecture layers.

## When to Use
- Use when designing class hierarchies or refactoring God Classes
- Use when implementing GoF patterns (Strategy, Factory, Observer, Command)
- Use when applying SOLID principles
- Use when building domain models or clean architecture
- Use when code smells appear (feature envy, primitive obsession, etc.)

## SOLID Principles

| Principle | Summary |
|-----------|---------|
| **S**ingle Responsibility | One class, one reason to change |
| **O**pen/Closed | Open for extension, closed for modification |
| **L**iskov Substitution | Subtypes must be substitutable |
| **I**nterface Segregation | Many specific interfaces > one fat |
| **D**ependency Inversion | Depend on abstractions |

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION                             │
│              (UI, Input, Controllers)                       │
├─────────────────────────────────────────────────────────────┤
│                    APPLICATION                              │
│              (Use Cases, Services)                          │
├─────────────────────────────────────────────────────────────┤
│                      DOMAIN                                 │
│              (Entities, Value Objects)                      │
├─────────────────────────────────────────────────────────────┤
│                   INFRASTRUCTURE                            │
│              (Repositories, External APIs)                  │
└─────────────────────────────────────────────────────────────┘
              Dependencies flow DOWN only
```

## Available Patterns

| Pattern | Use Case | Unity Fit |
|---------|----------|-----------|
| **Strategy** | Interchangeable behaviors (AI, attacks) | SO or interface injection |
| **Factory** | Object creation with pooling | `PooledFactory<T>` |
| **Observer** | Decoupled event notifications | C# events / SO channels |
| **Command** | Undo/redo, input recording | `ICommand` + `CommandInvoker` |
| **Repository** | Abstract data access | Interface + implementations |
| **Value Object** | Immutable data | `readonly struct` |

## Thinking Process (Before Code)
1. **Identify the Axis of Change**: What varies? (Behavior, Creation, Notification)
2. **Pattern Selection**: Justify choice based on problem domain
3. **Unity Compatibility**: MonoBehaviour vs ScriptableObject vs plain C#
4. **SOLID Validation**: SRP and OCP compliance check

## Best Practices
- ✅ Prefer composition over inheritance
- ✅ Use interfaces as reference types, not concrete classes
- ✅ Every Factory for high-frequency objects MUST use Object Pooling
- ✅ Unsubscribe from events in `OnDisable`/`OnDestroy`
- ✅ Use `[SerializeField] private` with `_camelCase` naming
- ✅ Make illegal states unrepresentable
- ❌ **NEVER** inherit more than 2 levels deep
- ❌ **NEVER** use `GameObject.Find`, `SendMessage`, `BroadcastMessage`
- ❌ **NEVER** use large switch/if-else for behavior selection

## Few-Shot Examples

### Example 1: Strategy Pattern for AI
**User**: "I need different enemy AI behaviors."

**Agent**:
```csharp
public interface IEntityBehavior
{
    void Execute(EnemyController enemy);
}

public class PatrolBehavior : IEntityBehavior { /* ... */ }
public class ChaseBehavior : IEntityBehavior { /* ... */ }

public class EnemyController : MonoBehaviour
{
    [SerializeField] private ScriptableObject _behaviorConfig;
    private IEntityBehavior _behavior;
    public void SetBehavior(IEntityBehavior b) => _behavior = b;
}
```

### Example 2: SRP Violation Fix
**User**: "This class does too much."

**Agent**:
```csharp
// BEFORE: Violates SRP
public class Player : MonoBehaviour
{
    void Move() { }
    void Attack() { }
    void SaveGame() { }  // ❌ Not player's job
    void RenderUI() { }  // ❌ Not player's job
}

// AFTER: Single responsibility
public class Player : MonoBehaviour
{
    void Move() { }
    void Attack() { }
}
// SaveManager handles saving, UIManager handles rendering
```

### Example 3: Value Object
**User**: "Create immutable currency."

**Agent**:
```csharp
public readonly struct Currency
{
    public int Gold { get; }
    public int Gems { get; }
    
    public Currency(int gold, int gems) { Gold = gold; Gems = gems; }
    public Currency Add(Currency other) =>
        new Currency(Gold + other.Gold, Gems + other.Gems);
    public static Currency operator +(Currency a, Currency b) => a.Add(b);
}
```

## Code Smells to Avoid
- **God Object**: Class that knows/does everything
- **Feature Envy**: Method uses other class's data too much
- **Primitive Obsession**: Using primitives instead of types
- **Long Parameter List**: > 3-4 parameters

## Architecture Audit Checklist
- [ ] **SRP Compliance**: Each class has single responsibility
- [ ] **Memory Safety**: Events unsubscribed in OnDestroy
- [ ] **Performance**: No heap allocations in Update loops

## Related Skills
- `@di-container-manager` - Dependency injection
- `@interface-driven-development` - Interface design
- `@event-bus-system` - Global decoupled events
- `@scriptableobject-architecture` - Data-driven patterns
