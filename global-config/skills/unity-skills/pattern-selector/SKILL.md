---
name: pattern-selector
description: "Unity pattern selector advisor. Use this when the user has a SPECIFIC decision between 2+ patterns (ScriptableObject vs events vs interfaces vs state machines vs object pools). Also trigger for: 'which pattern should I use', 'SO vs events', 'should I use a state machine for this', 'is object pooling worth it here', or any comparison between Unity design patterns. Do NOT use for high-level architecture — use architecture-advisor instead."
---

# Pattern Selector

Use this skill to decide whether a pattern is justified. **Recommend at most 1-3 patterns**, and explain why simpler options are not enough.

## Pattern Guide

| Pattern | Use When | Avoid When |
|---------|----------|------------|
| **ScriptableObject** | Authored config, shared data, event channels | Per-run mutable gameplay state |
| **C# events/delegates** | One-to-many notifications with clear ownership | Flows needing ordering or return values |
| **Global event bus** | Many systems need broad decoupled notifications | Default answer to coupling (hides ownership) |
| **Interfaces** | Multiple implementations or dependency boundaries | Wrapping every class without a real seam |
| **State machine** | Mutually exclusive states with explicit transitions | A few booleans or small command flow suffice |
| **Object pool** | Frequent spawn/despawn (bullets, VFX, UI) | Rare objects with simple lifetime |
| **Service layer** | Cross-scene systems with explicit bootstrap | Turning everything into hidden singletons |
| **Generics** | Removing repeated boilerplate with type safety | Making gameplay code harder to read |

## Few-Shot Examples

### Example 1: SO Events vs Static Event Bus
**User**: "Should I use ScriptableObject events or a static EventBus for my damage system?"

**Agent**:
Recommended: C# events / delegates
Why: Damage has clear ownership (weapon → target), one-to-many is not the primary pattern.

```csharp
// Direct C# event — simplest, clear ownership
public class HealthSystem : MonoBehaviour
{
    public event Action<float, float> OnHealthChanged; // current, max

    private float _currentHealth;
    [SerializeField] private float _maxHealth = 100f;

    public void TakeDamage(float amount)
    {
        _currentHealth = Mathf.Max(0, _currentHealth - amount);
        OnHealthChanged?.Invoke(_currentHealth, _maxHealth);
    }
}
```

Why not SO Event: No need for inspector-wired cross-system broadcast here.
Why not EventBus: Damage is local, not a global notification.

### Example 2: State Machine vs Booleans
**User**: "I have isGrounded, isJumping, isFalling, isDashing — should I use a state machine?"

**Agent**:
Recommended: State machine
Why: 4+ mutually exclusive states with different behaviors = classic FSM case.

```csharp
// Without FSM — fragile boolean soup
if (_isGrounded && !_isJumping && !_isDashing) { /* idle/walk */ }
else if (_isJumping && !_isFalling) { /* ascend */ }
// ... combinatorial nightmare

// With FSM — clean, extensible
public enum PlayerState { Grounded, Jumping, Falling, Dashing }

_stateMachine.AddState(PlayerState.Grounded, new GroundedState(this));
_stateMachine.AddState(PlayerState.Jumping, new JumpState(this));
_stateMachine.AddState(PlayerState.Falling, new FallState(this));
_stateMachine.AddState(PlayerState.Dashing, new DashState(this));
```

Threshold: 3+ mutually exclusive states → use FSM. Under 3 → booleans are fine.

### Example 3: Object Pool vs Simple Instantiate
**User**: "I spawn maybe 5 enemies per level. Should I pool them?"

**Agent**:
Recommended: Simple Instantiate
Why: 5 objects per level is not high-frequency. Pooling adds complexity for no gain.

```csharp
// Low-frequency spawn: Instantiate is fine
var enemy = Instantiate(_enemyPrefab, spawnPoint.position, Quaternion.identity);
// When destroyed:
Destroy(enemy.gameObject);
```

When to switch: If spawn/destroy happens 10+ times per second (bullets, VFX), pool. Otherwise don't.

## Output Format

- Recommended pattern(s) (max 3)
- Why they fit this case
- Why not the simpler alternative
- Minimal implementation boundary
- Known tradeoffs

## Related Skills
- `@architecture-advisor` - Project-level architecture guidance
- `@design-patterns` - GoF pattern implementations
- `@scriptableobject-architecture` - SO-specific patterns
