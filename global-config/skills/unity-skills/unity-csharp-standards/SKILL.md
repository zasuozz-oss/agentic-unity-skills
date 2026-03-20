---
name: unity-csharp-standards
description: "MANDATORY for ALL C# work in Unity. Real-time coding guidance covering three pillars: (1) C# naming/casing/formatting conventions, (2) script design review — responsibility, coupling, lifecycle safety, role assignment, and (3) mobile & general performance optimization — GC, hot-path, caching, battery, frame rate. For systematic script AUDIT with checklist, use unity-code-audit instead. Trigger for: 'create script', 'new MonoBehaviour', 'review this script', 'is this class too big', 'code smell', 'naming convention', 'how to optimize', 'game runs slow', 'frame drops', 'GC spikes', or any C# quality/performance question."
---

# C# Quality Skill (Unity 6)

Covers **three pillars** of C# quality for Unity mobile development:

1. **Conventions** — naming, casing, formatting, serialization
2. **Design Review** — responsibility, coupling, lifecycle, testability, role assignment
3. **Performance** — mobile budgets, hot-path rules, allocation reduction, platform specifics

---

## Part 1 — C# Conventions

### General Naming Principles
- All names MUST be professional, explicit, and self-explanatory
- Prioritize clarity over brevity
- Avoid placeholder names (foo, bar, test, tmp)
- Follow existing project naming patterns

### Casing Rules

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

### Fields
- Public fields discouraged unless required by Unity serialization
- Prefer `[SerializeField] private` fields
- Private fields MUST use `_camelCase`
- No Hungarian notation

```csharp
[SerializeField] private Button _applyButton;
private bool _isDead;
public int MaxHealth;
```

### Constants
- Constants MUST use PascalCase
- Optional prefix k_ if project uses it

```csharp
public const int MaxRetries = 3;
```

### Properties
- MUST use PascalCase
- Prefer over public fields
- Read-only: use expression-bodied syntax

```csharp
private int _health;
public int Health => _health;
```

### Booleans
- Names MUST start with: is, has, can, should

```csharp
private bool _isVisible;
public bool HasUnsavedChanges { get; }
```

### Methods
- Names MUST be verbs or verb phrases
- Boolean-returning methods read like questions

```csharp
public void RefreshUI();
public bool IsGameOver();
```

### Async Methods
- Names MUST end with Async
- Avoid async void except for Unity UI event handlers

### Coroutines
- Follow project pattern consistently:
  - Prefix CoXxx OR suffix XxxCoroutine
  - Do NOT mix styles

### Events
- Names describe what happened (past/present participle)
- Prefer Action / Action<T>

```csharp
public event Action SettingsApplied;
```

### Event Raising
- Methods that raise events MUST be prefixed with On

```csharp
public void OnSettingsApplied()
{
    SettingsApplied?.Invoke();
}
```

### Event Handlers
- Start with Handle or contextual OnXxx

```csharp
private void HandleApplyClicked();
```

### Collections
- MUST be plural nouns

```csharp
private List<Item> _inventoryItems;
```

### Unity Lifecycle
- Use EXACT names: Awake, OnEnable, Start, Update, FixedUpdate, LateUpdate, OnDisable, OnDestroy
- Do NOT invent lifecycle-like method names

### Serialization Rules
- Use [SerializeField] instead of public fields
- Use [Tooltip] for Inspector explanations
- Use [Range] for constrained numeric values
- Group related data with [Serializable] structs/classes

### Formatting Rules
- Brace style: Allman
- Braces MUST NOT be omitted (even single-line)
- Indentation: 4 spaces
- One variable declaration per line
- Max line length: 80–120 characters

### Comments
- Explain WHY, not WHAT
- Well-named code should not need comments
- Do NOT leave commented-out code
- XML summary only for public APIs when helpful

### Review Enforcement
- Ambiguous naming MUST be reported as WARNING
- Naming issues MUST NOT be silently fixed
- Style guide compliance > personal preference

---

## Part 2 — Script Design Review

### Review Checklist

#### 1. Responsibility
- Does the script have one clear reason to change?
- Is the class name accurate to what it actually does?
- Could any method live in a different class?

#### 2. Coupling
- Are dependencies injected or hard-wired?
- Does this script use `Find`, `GetComponent` in Update loops?
- How many other scripts does this one know about?

#### 3. Lifecycle Safety
- Are event subscriptions symmetric (OnEnable/OnDisable)?
- Are coroutines stopped in OnDisable/OnDestroy?
- Are async operations guarded against destroyed objects?

#### 4. Inspector UX
- Are fields organized with `[Header]` and `[Tooltip]`?
- Are tuning values constrained with `[Range]` or `[Min]`?
- Will another developer understand this from Inspector alone?

#### 5. Testability
- Can core logic run without Unity APIs?
- Can config be injected instead of hardcoded?
- Is the script thin enough to not need tests itself?

### Role Assignment Guide

Before creating a batch of scripts, assign explicit roles so AI does not generate everything as MonoBehaviour.

| Role | When to Use |
|------|-------------|
| **MonoBehaviour bridge** | Needs Transform, collisions, or Unity lifecycle |
| **ScriptableObject config** | Authored data, shared between instances |
| **Pure C# service** | Stateless logic, testable without Unity |
| **Presenter / Controller** | Bridges domain logic to UI or visuals |
| **State / FSM node** | Discrete state in a state machine |
| **Installer / Bootstrap** | Scene setup, dependency wiring |

### Guardrails
- Do not make every class a MonoBehaviour
- Do not force ScriptableObject onto runtime mutable state
- Prefer the simplest role that satisfies the requirement

### Output Format (Design Review)
- Responsibility verdict
- Top 3 concerns
- Suggested changes (ranked by impact)
- What's already good (reinforce)

---

## Part 3 — Mobile & Performance Optimization

### Mobile Performance Budget

| Metric | Budget |
|--------|:------:|
| Frame Time | < 33ms (30fps) / < 16ms (60fps) |
| Draw Calls | < 100 |
| Triangles | < 200K per frame |
| Texture Memory | < 150MB |
| Audio Memory | < 30MB |
| App Size | < 150MB (store limit) |

### Coding Rules
- ✅ Use `Application.targetFrameRate = 30` for non-action games
- ✅ Use `Screen.SetResolution` for dynamic resolution
- ✅ Use ASTC (Android) / PVRTC (iOS) texture compression
- ✅ Cap physics to 30 FPS (`Time.fixedDeltaTime = 1f/30f`)
- ✅ Use `OnDemandRendering.renderFrameInterval` for idle screens
- ❌ **NEVER** use real-time shadows on mobile (bake them)
- ❌ **NEVER** use `Debug.Log` in release builds
- ❌ **NEVER** use reflection in hot paths

### General Performance Red Flags

#### Update Loop
- ❌ `Camera.main` not cached (uses `FindGameObjectWithTag` internally)
- ❌ `GetComponent<T>()` per frame (cache in Awake/Start)
- ❌ `FindObjectOfType` at runtime
- ❌ LINQ (`.Where`, `.Select`, `.Any`) in hot paths
- ❌ String concatenation (`+`, `$""`) per frame
- ❌ `new List<T>()` / closures / lambdas per frame

#### Caching
- ✅ Cache component references in Awake/Start
- ✅ Use `sqrMagnitude` instead of `Distance`
- ✅ Use `Animator.StringToHash` for parameters
- ✅ Use `const string` for status comparisons

#### Allocation Reduction
- ✅ Use object pooling for frequent spawn/destroy
- ✅ Use `StringBuilder` for string building in loops
- ✅ Replace `foreach` with `for` on non-List collections
- ✅ Cache delegates/lambdas as fields

#### Event-Driven vs Polling
- Replace `Update()` checks with C# Events or `UnityEvent` triggers
- If polling is required, use timer throttling

### Platform-Specific

| Setting | Android | iOS |
|---------|---------|-----|
| Texture | ASTC | ASTC (modern) / PVRTC (legacy) |
| Scripting Backend | IL2CPP | IL2CPP |
| Min API | 24 (Android 7) | iOS 14 |
| Architecture | ARM64 | ARM64 |

---

## Few-Shot Examples

### Example 1: Correct Script Structure (Conventions)
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

### Example 2: God Class Decomposition (Design Review)
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

### Example 3: Lifecycle Safety Violation (Design Review)
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

### Example 4: Adaptive Quality System (Performance)
**User**: "Auto-adjust quality based on device."

**Agent**:
```csharp
public class AdaptiveQuality : MonoBehaviour
{
    [SerializeField] private int _targetFPS = 30;

    private float _sampleTimer;
    private int _frameCount;
    private int _currentQualityLevel;

    private void Start()
    {
        Application.targetFrameRate = _targetFPS;
        _currentQualityLevel = DetectDeviceTier();
        ApplyQuality(_currentQualityLevel);
    }

    private int DetectDeviceTier()
    {
        int ram = SystemInfo.systemMemorySize;
        int cores = SystemInfo.processorCount;

        if (ram >= 6000 && cores >= 8) return 2; // High
        if (ram >= 4000 && cores >= 4) return 1; // Medium
        return 0; // Low
    }

    private void ApplyQuality(int tier)
    {
        switch (tier)
        {
            case 0: // Low
                QualitySettings.SetQualityLevel(0);
                Screen.SetResolution(Screen.width / 2, Screen.height / 2, true);
                QualitySettings.shadows = ShadowQuality.Disable;
                QualitySettings.lodBias = 0.5f;
                break;
            case 1: // Medium
                QualitySettings.SetQualityLevel(1);
                Screen.SetResolution((int)(Screen.width * 0.75f),
                    (int)(Screen.height * 0.75f), true);
                QualitySettings.shadows = ShadowQuality.HardOnly;
                QualitySettings.lodBias = 1f;
                break;
            case 2: // High
                QualitySettings.SetQualityLevel(2);
                QualitySettings.shadows = ShadowQuality.All;
                QualitySettings.lodBias = 1.5f;
                break;
        }
    }

    private void Update()
    {
        _frameCount++;
        _sampleTimer += Time.unscaledDeltaTime;
        if (_sampleTimer < 2f) return;

        float fps = _frameCount / _sampleTimer;
        _frameCount = 0;
        _sampleTimer = 0f;

        if (fps < _targetFPS * 0.8f && _currentQualityLevel > 0)
        {
            _currentQualityLevel--;
            ApplyQuality(_currentQualityLevel);
        }
    }
}
```

### Example 5: Conditional Debug Logging (Performance)
**User**: "Remove Debug.Log from release builds."

**Agent**:
```csharp
public static class GameLog
{
    [System.Diagnostics.Conditional("UNITY_EDITOR")]
    [System.Diagnostics.Conditional("DEVELOPMENT_BUILD")]
    public static void Log(string message)
    {
        Debug.Log(message);
    }

    [System.Diagnostics.Conditional("UNITY_EDITOR")]
    [System.Diagnostics.Conditional("DEVELOPMENT_BUILD")]
    public static void LogWarning(string message)
    {
        Debug.LogWarning(message);
    }

    // Errors always log (even in release)
    public static void LogError(string message)
    {
        Debug.LogError(message);
    }
}

// Usage:
// GameLog.Log("Enemy spawned"); // Compiled out in Release
// GameLog.LogError("Critical failure"); // Always included
```

---

## Related Skills
- `@unity-addressables` - Asset management and memory-safe release
- `@unity-ui-performance` - UI rendering, state safety, responsive design
- `@unity-dotween-safety` - DOTween lifecycle and memory patterns
- `@unity-async-patterns` - Async/await lifecycle and cancellation
- `@unity-code-audit` - Full C# audit checklist with verification rules
