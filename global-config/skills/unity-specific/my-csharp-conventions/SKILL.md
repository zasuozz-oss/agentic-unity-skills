---
description: C# naming conventions and code style for Unity 6 projects
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
private List<Item> inventoryItems;
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

## Review Enforcement
- Ambiguous naming MUST be reported as WARNING
- Naming issues MUST NOT be silently fixed
- Style guide compliance > personal preference
