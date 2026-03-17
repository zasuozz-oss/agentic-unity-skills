---
name: script-design-review
description: "Unity script quality reviewer. Use this when the user wants script design feedback, responsibility analysis, coupling review, lifecycle safety checks, or inspector UX improvements. Also trigger for: 'review this script', 'is this class too big', 'code smell', 'should I split this class', 'this script does too much', or any question about script quality and maintainability — even if they don't say 'review'. Do NOT use for performance-specific concerns — use performance-advisor instead."
---

# Script Design Review

Use this skill to review a Unity C# script for quality, responsibility, and maintainability.

## Review Checklist

### 1. Responsibility
- Does the script have one clear reason to change?
- Is the class name accurate to what it actually does?
- Could any method live in a different class?

### 2. Coupling
- Are dependencies injected or hard-wired?
- Does this script use `Find`, `GetComponent` in Update loops?
- How many other scripts does this one know about?

### 3. Lifecycle Safety
- Are event subscriptions symmetric (OnEnable/OnDisable)?
- Are coroutines stopped in OnDisable/OnDestroy?
- Are async operations guarded against destroyed objects?

### 4. Inspector UX
- Are fields organized with `[Header]` and `[Tooltip]`?
- Are tuning values constrained with `[Range]` or `[Min]`?
- Will another developer understand this from Inspector alone?

### 5. Testability
- Can core logic run without Unity APIs?
- Can config be injected instead of hardcoded?
- Is the script thin enough to not need tests itself?

## Few-Shot Examples

### Example 1: God Class Decomposition
**User**: "Review this GameManager — it's 500 lines."

**Agent**:
```csharp
// ❌ BEFORE: God class with 4+ responsibilities
public class GameManager : MonoBehaviour
{
    // Manages score, spawns enemies, plays audio, handles UI, saves game
    public void AddScore(int pts) { }
    public void SpawnEnemy() { }
    public void PlaySFX(AudioClip clip) { }
    public void ShowGameOverUI() { }
    public void SaveProgress() { }
}

// ✅ AFTER: Single responsibility per class
public class ScoreManager : MonoBehaviour
{
    private int _score;
    public event Action<int> OnScoreChanged;
    public void AddScore(int pts)
    {
        _score += pts;
        OnScoreChanged?.Invoke(_score);
    }
}

// EnemySpawner, AudioManager, GameOverUI, SaveManager — each separate
```

### Example 2: Lifecycle Safety Violation
**User**: "This script leaks events."

**Agent**:
```csharp
// ❌ BEFORE: Asymmetric subscription — subscribe in Start, never unsubscribe
public class HUDController : MonoBehaviour
{
    void Start()
    {
        PlayerHealth.OnDamaged += UpdateHealthBar;
    }
    // Missing OnDisable/OnDestroy — memory leak + ghost listener!
}

// ✅ AFTER: Symmetric subscribe/unsubscribe in OnEnable/OnDisable
public class HUDController : MonoBehaviour
{
    private void OnEnable()
    {
        PlayerHealth.OnDamaged += UpdateHealthBar;
    }

    private void OnDisable()
    {
        PlayerHealth.OnDamaged -= UpdateHealthBar;
    }

    private void UpdateHealthBar(float health) { /* ... */ }
}
```

### Example 3: Coupling Review
**User**: "Review this weapon script's dependencies."

**Agent**:
```csharp
// ❌ BEFORE: Tight coupling — knows about 5 concrete classes
public class Weapon : MonoBehaviour
{
    void Fire()
    {
        AudioManager.Instance.PlaySFX(_fireClip);         // Singleton
        ParticleManager.Instance.Spawn("muzzle_flash");   // Singleton + string
        var enemy = FindObjectOfType<Enemy>();             // Runtime search
        enemy.TakeDamage(_damage);
        UIManager.Instance.ShowHitMarker();                // Singleton
    }
}

// ✅ AFTER: Decoupled — events + interface
public class Weapon : MonoBehaviour
{
    public event Action OnFired;

    void Fire()
    {
        if (Physics.Raycast(transform.position, transform.forward, out var hit))
        {
            if (hit.collider.TryGetComponent<IDamageable>(out var target))
                target.TakeDamage(_damage);
        }
        OnFired?.Invoke(); // Listeners handle SFX, VFX, UI externally
    }
}
```

## Output Format

- Responsibility verdict
- Top 3 concerns
- Suggested changes (ranked by impact)
- What's already good (reinforce)

## Related Skills
- `@testability-advisor` - Deeper testability analysis
- `@inspector-design` - Inspector UX specifics
- `@design-patterns` - Pattern recommendations
