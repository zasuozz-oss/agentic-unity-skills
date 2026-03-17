---
name: my-csharp-conventions
description: "C# naming conventions and code style for Unity projects. Use this when the user writes new C# scripts, needs naming guidance, reviews code style, or whenever creating or modifying C# files. Also trigger for: 'naming convention', 'how to name variables', 'code style', 'formatting rules', 'field naming', 'PascalCase vs camelCase', or any question about C# naming or style — even if they don't say 'conventions'. ALWAYS reference this skill when writing new C# code to ensure consistency."
---

# C# Conventions Skill (Unity 6)

## General Naming Principles
- All names MUST be professional, explicit, and self-explanatory
- Prioritize clarity over brevity
- Avoid placeholder names (foo, bar, test, tmp)
- Follow existing project naming patterns

---

## Casing Rules

| Element | Convention |
|---------|------------|
| Namespace | PascalCase |
| Class / Struct / Enum | PascalCase |
| Interface | IPascalCase |
| Method | PascalCase (verb phrase) |
| Property | PascalCase |
| Public Field | PascalCase |
| Private / Protected Field | _camelCase (or m_camelCase) |
| Local Variable / Parameter | camelCase |
| Enum Values | PascalCase |
| UI Toolkit (USS/UXML) | kebab-case (BEM) |

---

## Fields
- Public fields discouraged unless required by Unity serialization
- Prefer `[SerializeField] private` fields
- Private fields MUST use `_camelCase`
- No Hungarian notation

```csharp
[SerializeField] private Button _applyButton;
private bool _isDead;
public int MaxHealth;
```

---

## Constants
- Constants MUST use PascalCase
- Optional prefix k_ if project uses it

```csharp
public const int MaxRetries = 3;
```

---

## Properties
- MUST use PascalCase
- Prefer over public fields
- Read-only: use expression-bodied syntax

```csharp
private int _health;
public int Health => _health;
```

---

## Booleans
- Names MUST start with: is, has, can, should

```csharp
private bool _isVisible;
public bool HasUnsavedChanges { get; }
```

---

## Methods
- Names MUST be verbs or verb phrases
- Boolean-returning methods read like questions

```csharp
public void RefreshUI();
public bool IsGameOver();
```

---

## Async Methods
- Names MUST end with Async
- Avoid async void except for Unity UI event handlers

---

## Coroutines
- Follow project pattern consistently:
  - Prefix CoXxx OR suffix XxxCoroutine
  - Do NOT mix styles

---

## Events
- Names describe what happened (past/present participle)
- Prefer Action / Action<T>

```csharp
public event Action SettingsApplied;
```

---

## Event Raising
- Methods that raise events MUST be prefixed with On

```csharp
public void OnSettingsApplied()
{
    SettingsApplied?.Invoke();
}
```

---

## Event Handlers
- Start with Handle or contextual OnXxx

```csharp
private void HandleApplyClicked();
```

---

## Collections
- MUST be plural nouns

```csharp
private List<Item> _inventoryItems;
```

---

## Unity Lifecycle
- Use EXACT names: Awake, OnEnable, Start, Update, FixedUpdate, LateUpdate, OnDisable, OnDestroy
- Do NOT invent lifecycle-like method names

---

## Serialization Rules
- Use [SerializeField] instead of public fields
- Use [Tooltip] for Inspector explanations
- Use [Range] for constrained numeric values
- Group related data with [Serializable] structs/classes

---

## Formatting Rules
- Brace style: Allman
- Braces MUST NOT be omitted (even single-line)
- Indentation: 4 spaces
- One variable declaration per line
- Max line length: 80–120 characters

---

## Comments
- Explain WHY, not WHAT
- Well-named code should not need comments
- Do NOT leave commented-out code
- XML summary only for public APIs when helpful

---

## Few-Shot Examples

### Example 1: Correct Script Structure
**User**: "Create a health manager."

**Agent**:
```csharp
public class HealthManager : MonoBehaviour
{
    [Header("Configuration")]
    [SerializeField, Min(1)] private float _maxHealth = 100f;

    [Header("Runtime")]
    [SerializeField, Range(0f, 100f)] private float _currentHealth;

    private bool _isDead;

    public float CurrentHealth => _currentHealth;
    public float MaxHealth => _maxHealth;
    public bool IsDead => _isDead;

    public event Action<float, float> OnHealthChanged; // current, max

    public void TakeDamage(float amount)
    {
        if (_isDead) return;

        _currentHealth = Mathf.Max(0f, _currentHealth - amount);
        OnHealthChanged?.Invoke(_currentHealth, _maxHealth);

        if (_currentHealth <= 0f)
        {
            _isDead = true;
            HandleDeath();
        }
    }

    private void HandleDeath()
    {
        // Death logic here
    }
}
```

### Example 2: Naming Violations → Fix
**User**: "Review my naming."

**Agent**:
```csharp
// ❌ BAD
public class mgr : MonoBehaviour
{
    public float hp;
    bool dead;
    List<GameObject> objs;
    void DoStuff() { }
}

// ✅ GOOD
public class PlayerHealthManager : MonoBehaviour
{
    [SerializeField] private float _maxHealth;
    private bool _isDead;
    private List<GameObject> _activeEnemies;

    public void ApplyDamage(float amount) { }
}
```

### Example 3: Event Naming Pattern
**User**: "Create event for level complete."

**Agent**:
```csharp
public class LevelManager : MonoBehaviour
{
    // Event name = past participle (what happened)
    public event Action<int> LevelCompleted;

    // Raising method = On + event name
    private void OnLevelCompleted(int levelIndex)
    {
        LevelCompleted?.Invoke(levelIndex);
    }

    // Handler = Handle + context
    private void HandleLevelCompleted(int levelIndex)
    {
        Debug.Log($"Level {levelIndex} completed!");
    }
}
```

---

## Review Enforcement
- Ambiguous naming MUST be reported as WARNING
- Naming issues MUST NOT be silently fixed
- Style guide compliance > personal preference
