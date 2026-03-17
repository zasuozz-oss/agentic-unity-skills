---
name: script-roles
description: "Script role planner. Use this when the user needs to decide which scripts should be MonoBehaviour bridges, ScriptableObject configs, pure C# services, presenters, or installers before batch code generation. Also trigger for: 'what class type should this be', 'should this be a MonoBehaviour', 'should this be a ScriptableObject', 'planning new scripts', or any situation where multiple scripts need role assignment before writing — even if they don't say 'roles'."
---

# Script Roles

Use this skill before creating a batch of gameplay scripts. Turn a rough script list into explicit roles so AI does not generate everything as MonoBehaviour.

## Common Roles

| Role | When to Use |
|------|-------------|
| **MonoBehaviour bridge** | Needs Transform, collisions, or Unity lifecycle |
| **ScriptableObject config** | Authored data, shared between instances |
| **Pure C# service** | Stateless logic, testable without Unity |
| **Presenter / Controller** | Bridges domain logic to UI or visuals |
| **State / FSM node** | Discrete state in a state machine |
| **Installer / Bootstrap** | Scene setup, dependency wiring |

## Few-Shot Examples

### Example 1: Inventory System Role Assignment
**User**: "I need scripts for inventory: storage, item data, UI display, crafting rules."

**Agent**:
```csharp
// 1. ItemDataSO — ScriptableObject config
// Holds authored item definitions. Shared across all instances.
[CreateAssetMenu(menuName = "Game/Items/Item Data")]
public class ItemDataSO : ScriptableObject
{
    [SerializeField] private string _itemName;
    [SerializeField] private Sprite _icon;
    [SerializeField] private int _maxStack = 99;
    public string ItemName => _itemName;
    public Sprite Icon => _icon;
    public int MaxStack => _maxStack;
}

// 2. Inventory — Pure C# service
// Testable without Unity. No MonoBehaviour needed.
public class Inventory
{
    private readonly Dictionary<string, int> _items = new();
    public bool TryAdd(string itemId, int count) { /* ... */ return true; }
    public bool TryRemove(string itemId, int count) { /* ... */ return true; }
}

// 3. CraftingRules — Pure C# service
// Stateless logic, takes Inventory as dependency.
public class CraftingRules
{
    public bool CanCraft(RecipeSO recipe, Inventory inventory) { /* ... */ return true; }
}

// 4. InventoryUI — MonoBehaviour (Presenter)
// Bridges domain Inventory to visual UI.
public class InventoryUI : MonoBehaviour
{
    [SerializeField] private UIDocument _uiDocument;
    private Inventory _inventory; // Injected
}
```

### Example 2: AI System Roles
**User**: "Create enemy AI with patrolling, detection, and attack."

**Agent**:
```csharp
// 1. EnemyAI — MonoBehaviour bridge (needs Transform, NavMeshAgent)
public class EnemyAI : MonoBehaviour
{
    [SerializeField] private EnemyConfigSO _config;
    private StateMachine<EnemyAI> _fsm;
}

// 2. EnemyConfigSO — ScriptableObject config
[CreateAssetMenu(menuName = "Game/AI/Enemy Config")]
public class EnemyConfigSO : ScriptableObject
{
    public float DetectionRange;
    public float AttackRange;
    public float PatrolSpeed;
}

// 3. PatrolState, ChaseState, AttackState — Pure C# (FSM nodes)
public class PatrolState : StateBase<EnemyAI>
{
    public override void Update(EnemyAI ctx) { /* ... */ }
}

// 4. DetectionService — Pure C# service
public class DetectionService
{
    public bool CanSee(Vector3 origin, Vector3 target, float range)
    {
        return Vector3.Distance(origin, target) <= range;
    }
}
```

### Example 3: Save System Roles
**User**: "Plan scripts for a save/load system."

**Agent**:
```csharp
// 1. SaveManager — Installer/Bootstrap (scene-level, manages lifecycle)
public class SaveManager : MonoBehaviour
{
    private ISaveStorage _storage;
    public void Save() { /* ... */ }
    public void Load() { /* ... */ }
}

// 2. ISaveStorage — Interface (seam for testability)
public interface ISaveStorage
{
    void Write(string key, string json);
    string Read(string key);
}

// 3. FileSaveStorage — Pure C# service
public class FileSaveStorage : ISaveStorage
{
    public void Write(string key, string json) { /* File.WriteAllText(...) */ }
    public string Read(string key) { /* File.ReadAllText(...) */ return ""; }
}

// 4. ISaveable — Interface for saveable objects
public interface ISaveable
{
    string SaveId { get; }
    object CaptureState();
    void RestoreState(object state);
}
```

## Output Format

- Script name
- Recommended role
- Main responsibility
- Main dependencies
- Why this role fits better than alternatives

## Guardrails

- Do not make every class a MonoBehaviour
- Do not force ScriptableObject onto runtime state that should stay in memory-only objects
- Prefer the simplest role that satisfies the requirement

## Related Skills
- `@architecture-advisor` - Project-level architecture
- `@design-patterns` - Pattern implementations
- `@testability-advisor` - Testability considerations
