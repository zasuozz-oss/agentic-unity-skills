---
name: unity-script-design-review
description: "Use when reviewing Unity C# script design: single responsibility, God class decomposition, MonoBehaviour vs ScriptableObject vs pure C# role assignment, coupling reduction, or testability improvement."
---

# Script Design Review

## Overview
Structured review of Unity C# scripts for responsibility, coupling, lifecycle safety, Inspector UX, and testability. Also provides role assignment guidance before generating a batch of new scripts.

## When to Use
- Use when a script feels "too big" or has unclear responsibility
- Use before creating a batch of new scripts to assign roles correctly
- Use during code review to evaluate coupling and design decisions
- Use when deciding between MonoBehaviour, ScriptableObject, or Pure C# service
- Use when decomposing a God class into focused components

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

## Role Assignment Guide

Before creating a batch of scripts, assign explicit roles so AI does not generate everything as MonoBehaviour.

| Role | When to Use |
|------|-------------|
| **MonoBehaviour bridge** | Needs Transform, collisions, or Unity lifecycle |
| **ScriptableObject config** | Authored data, shared between instances |
| **Pure C# service** | Stateless logic, testable without Unity |
| **Presenter / Controller** | Bridges domain logic to UI or visuals |
| **State / FSM node** | Discrete state in a state machine |
| **Installer / Bootstrap** | Scene setup, dependency wiring |

## Guardrails
- Do not make every class a MonoBehaviour
- Do not force ScriptableObject onto runtime mutable state
- Prefer the simplest role that satisfies the requirement

## Output Format
- **Responsibility verdict** — does it have one clear reason to change?
- **Top 3 concerns** — ranked by severity
- **Suggested changes** — ranked by impact
- **What's already good** — reinforce correct patterns

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

**Review output:**
```
Responsibility verdict: FAIL — 5 distinct responsibilities in one class

Top 3 concerns:
1. 🔴 Score + Spawning + Audio + UI + Save = 5 reasons to change
2. 🟡 Any change to SaveProgress risks breaking score logic
3. 🟡 Unit testing impossible — all concerns interleaved

Suggested changes (by impact):
1. Extract ScoreManager (events-driven, pure C#)
2. Extract SaveManager (handles persistence only)
3. EnemySpawner, AudioManager, GameOverUI — each own MonoBehaviour

What's already good: Single entry point for game state — keep a thin
GameManager as coordinator that delegates to the above services.
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

### Example 3: Role Assignment Before Generation
**User**: "Create a shop system: product catalog, purchase flow, and inventory."

**Agent**:
```
Role assignment before generation:

ProductCatalog     → ScriptableObject[]  — authored data, read-only
PurchaseService    → Pure C# service     — stateless transaction logic
InventoryModel     → Pure C# service     — runtime mutable state (List<Item>)
ShopPresenter      → MonoBehaviour       — bridges InventoryModel + UI
ShopView           → MonoBehaviour       — pure UI wiring, no business logic
PurchaseValidator  → Pure C# service     — price check, stock check, testable

Generating with these roles — 0 God classes.
```

## Related Skills
- `@unity-csharp-standards` — C# naming, casing, and formatting conventions
- `@unity-async-patterns` — Async lifecycle safety patterns
- `@unity-dotween-safety` — DOTween lifecycle and memory patterns
