---
name: project-scout
description: "Unity project reconnaissance advisor. Use this when inspecting an existing project's architecture, packages, conventions, and constraints before proposing changes. Also trigger for: 'analyze this project', 'what patterns does this project use', 'should I refactor', 'understand codebase first', or any situation where the user wants changes to an EXISTING project — even if they don't say 'scout'. Do NOT use for greenfield projects — use architecture-advisor instead."
---

# Project Scout

Use this before recommending architecture changes in an existing project.

## Inspect First

Collect only the information needed to avoid clashing with the current project:

- Unity version and render pipeline
- Installed packages and notable dependencies
- `asmdef` layout, if any
- Folder structure under `Assets/`
- Whether the project already uses:
  - ScriptableObject config
  - Service/singleton patterns
  - Event-driven flows
  - Custom inspectors/property drawers
  - Tests
- Existing naming and code organization style

## Suggested Inspection Sources

- `Packages/manifest.json` — dependencies
- `Assets/**/*.asmdef` — module boundaries
- `ProjectSettings/` — Unity version, quality settings
- Script search for patterns (`Find`, `GetComponent`, `Singleton`)

## Few-Shot Examples

### Example 1: Quick Project Assessment
**User**: "I want to add an event system. What does this project already use?"

**Agent**:
```csharp
// Step 1: Check for existing event patterns
// Search for: Action, UnityEvent, EventBus, GameEvent, IObserver
// Found in PlayerHealth.cs:
public class PlayerHealth : MonoBehaviour
{
    public event Action<float> OnHealthChanged;  // C# events already in use
    public UnityEvent OnDeath;                    // UnityEvents also used
}

// Assessment: Project already uses C# events + UnityEvents.
// Recommendation: Continue with C# events for code-to-code,
// add SO event channels only for inspector-wired cross-system needs.
```

### Example 2: Singleton Pattern Detection
**User**: "Check how managers are structured in the project."

**Agent**:
```csharp
// Search found: static Instance pattern in 4 managers
public class AudioManager : MonoBehaviour
{
    public static AudioManager Instance { get; private set; }
    void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
        DontDestroyOnLoad(gameObject);
    }
}

// Assessment: Lazy singleton pattern used across AudioManager,
// SaveManager, UIManager, AnalyticsManager.
// Risk: No initialization order guarantee.
// Recommendation: Keep existing pattern, add null-checks at call sites,
// consider bootstrap scene if race conditions appear.
```

### Example 3: Package Inventory
**User**: "What packages does this project use?"

**Agent**:
```json
// From Packages/manifest.json — key dependencies:
{
    "com.unity.addressables": "1.21.14",
    "com.unity.localization": "1.4.5",
    "com.unity.textmeshpro": "3.0.6",
    "com.cysharp.unitask": "2.5.0",
    "com.unity.inputsystem": "1.7.0"
}
// Assessment: Modern stack — UniTask for async, Addressables for assets,
// New Input System. Any new code should use UniTask (not coroutines)
// and AssetReference (not Resources.Load).
```

## Output Format

- Technical baseline
- Existing architectural signals
- Existing conventions worth preserving
- Existing risks or inconsistencies
- Constraints for future suggestions
- Unknowns that still need confirmation

## Guardrails

- Do not propose clean-slate architecture if the project has a consistent pattern
- Do not recommend new dependencies until the current stack is clear
- Respect existing conventions even if you'd do it differently

## Related Skills
- `@architecture-advisor` - Architecture guidance (after scouting)
- `@asmdef-advisor` - Assembly definition guidance
