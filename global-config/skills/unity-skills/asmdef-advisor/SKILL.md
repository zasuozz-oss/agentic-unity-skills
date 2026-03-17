---
name: asmdef-advisor
description: "Unity Assembly Definition advisor. Use this when the user needs assembly definition guidance, compile time optimization, circular dependency resolution, or module boundary planning. Also trigger for: 'compile time is slow', 'circular dependency', 'asmdef setup', 'assembly references', 'Editor vs Runtime assembly', or any question about organizing code into assemblies — even if they don't say 'asmdef'. Do NOT use for project-level architecture — use architecture-advisor instead."
---

# Assembly Definition Advisor

## Purpose

Guide assembly definition usage to manage compile times and dependency direction in Unity projects.

## When asmdef is Justified

| Signal | Recommendation |
|--------|---------------|
| Compile time > 10s on code change | Split heavy folders |
| Plugin code touched rarely | Isolate behind asmdef |
| Circular dependency detected | Extract shared interface assembly |
| Editor-only code in runtime build | Separate with Editor asmdef |

## Default Recommendation

```
Assets/
├── Game.asmdef                   (gameplay, references Game.Core)
├── Game.Core.asmdef              (interfaces, data, no MonoBehaviour)
├── Game.Editor.asmdef            (custom editors, Editor platform only)
├── Plugins/ThirdParty.asmdef     (DOTween, UniTask, etc.)
└── Tests/
    ├── Tests.EditMode.asmdef
    └── Tests.PlayMode.asmdef
```

## Best Practices
- ✅ Dependencies flow ONE direction: Game → Game.Core (never reverse)
- ✅ Editor assemblies reference Runtime assemblies (not vice versa)
- ✅ Use `Define Constraints` for test assemblies (UNITY_INCLUDE_TESTS)
- ✅ Keep shared interfaces/data in a Core assembly
- ❌ **NEVER** create an asmdef for every folder (overhead > benefit)
- ❌ **NEVER** allow circular references (A → B → A)
- ❌ **NEVER** put Editor code in Runtime assemblies

## Few-Shot Examples

### Example 1: Breaking a Circular Dependency
**User**: "My combat assembly references my inventory assembly, and inventory references combat."

**Agent**:
```csharp
// ❌ BEFORE: Circular — Combat.asmdef ↔ Inventory.asmdef
// Combat needs IInventoryQuery, Inventory needs IDamageSource

// ✅ AFTER: Extract shared interfaces into Game.Core.asmdef
// Game.Core.asmdef (no dependencies)
namespace Game.Core
{
    public interface IDamageSource
    {
        float GetDamage();
    }

    public interface IInventoryQuery
    {
        bool HasItem(string itemId);
        int GetItemCount(string itemId);
    }
}

// Combat.asmdef → references Game.Core only
// Inventory.asmdef → references Game.Core only
// No circular reference!
```

### Example 2: Editor Assembly Separation
**User**: "My build fails because it includes Editor-only code."

**Agent**:
```csharp
// ❌ BEFORE: #if UNITY_EDITOR scattered everywhere
public class EnemySpawner : MonoBehaviour
{
    #if UNITY_EDITOR
    void OnDrawGizmos() { /* draw spawn radius */ }
    // What if someone adds UnityEditor API without the #if?
    #endif
}

// ✅ AFTER: Separate Editor assembly
// Game.Editor.asmdef (Platform: Editor only, References: Game.asmdef)
namespace Game.Editor
{
    [CustomEditor(typeof(EnemySpawner))]
    public class EnemySpawnerEditor : UnityEditor.Editor
    {
        void OnSceneGUI()
        {
            var spawner = (EnemySpawner)target;
            Handles.color = Color.red;
            Handles.DrawWireDisc(spawner.transform.position,
                Vector3.up, spawner.SpawnRadius);
        }
    }
}
```

### Example 3: Test Assembly Setup
**User**: "How to setup test assemblies?"

**Agent**:
```csharp
// Tests.EditMode.asmdef configuration:
// Platform: Editor
// References: Game.asmdef, Game.Core.asmdef
// Define Constraints: UNITY_INCLUDE_TESTS
// Override References: UnityEngine.TestRunner, NUnit.Framework

[TestFixture]
public class DamageCalculatorTests
{
    [Test]
    public void Calculate_WithCrit_ReturnsDoubled()
    {
        float result = DamageCalculator.Calculate(10f, 2f, isCrit: true);
        Assert.AreEqual(20f, result);
    }
}

// Tests.PlayMode.asmdef configuration:
// Platform: Any (needs to run in Player)
// References: Same + UnityEngine.TestRunner
// Define Constraints: UNITY_INCLUDE_TESTS
```

## Related Skills
- `@architecture-advisor` - Project-level architecture
- `@project-scout` - Inspect existing structure
- `@automated-unit-testing` - Test assembly configuration
