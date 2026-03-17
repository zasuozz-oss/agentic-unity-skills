---
name: architecture-advisor
description: "Unity project architecture advisor. Use this when the user asks about project architecture, folder structure, singleton vs DI, monolith vs modular. Also trigger for: 'how should I structure my project', 'is this over-engineered', 'when to use singletons', 'project is getting messy', or any high-level design question about how systems fit together — even if they don't say 'architecture'. Do NOT use for specific pattern selection (SO vs events) — use pattern-selector instead."
---

# Architecture Advisor

## Purpose

Decide the **right-sized** architecture for a Unity project. Stop over-engineering indie games and under-engineering production titles.

## Decision Framework (ask first)

1. **Scope** — Solo jam, small indie, mid-size, AA+?
2. **Team size** — 1 dev, 2-5, 5-15, 15+?
3. **Lifespan** — Game-jam throwaway, 1-year, long-lived service?
4. **Performance target** — Mobile 30 fps, PC 120 fps, VR 90 fps?

## Architecture Tiers

| Tier | When | Key Pattern |
|------|------|-------------|
| **Minimal** | Solo / jam / prototype | MonoBehaviour + SO config |
| **Structured** | Small indie (2-5 devs) | Service Locator + Events |
| **Layered** | Mid team (5-15) | DI + Interface boundaries |
| **Full** | AA+ / live service | DOTS / micro-services / ECS |

## Few-Shot Examples

### Example 1: Right-Sizing for Indie
**User**: "I'm a solo dev making an RPG — should I use Zenject?"

**Agent**:
```csharp
// For solo dev: Structured tier — Service Locator + Events is enough.
// Zenject adds ~50KB metadata overhead and complex learning curve.

// Simple Service Locator — sufficient for solo/small team
public static class Services
{
    private static readonly Dictionary<Type, object> _services = new();

    public static void Register<T>(T service) => _services[typeof(T)] = service;
    public static T Get<T>() => (T)_services[typeof(T)];
    public static void Clear() => _services.Clear();
}

// Usage in Bootstrap scene
public class GameBootstrap : MonoBehaviour
{
    void Awake()
    {
        Services.Register<IAudioService>(new AudioService());
        Services.Register<ISaveService>(new SaveService());
    }

    void OnDestroy() => Services.Clear();
}
```

### Example 2: When to Add Layers
**User**: "Our 8-person team has spaghetti code — how to fix?"

**Agent**:
```csharp
// 8-person team = Layered tier. Add interface boundaries.
// Split into 3 layers: Domain, Infrastructure, Presentation

// Domain layer (pure C#, no Unity references)
public interface IInventory
{
    bool TryAdd(ItemId item, int count);
    IReadOnlyList<InventorySlot> Slots { get; }
}

// Infrastructure (Unity-specific implementations)
public class InventorySystem : MonoBehaviour, IInventory
{
    public bool TryAdd(ItemId item, int count) { /* ... */ return true; }
    public IReadOnlyList<InventorySlot> Slots => _slots;
}

// Presentation (UI, knows only interfaces)
public class InventoryUI : MonoBehaviour
{
    private IInventory _inventory; // Injected via constructor or [Inject]
    void Refresh() { foreach (var slot in _inventory.Slots) { /* render */ } }
}
```

### Example 3: Folder Structure Recommendation
**User**: "What folder structure should I use?"

**Agent**:
```csharp
// Feature-based structure (scales better than type-based):
// Assets/
// ├── _Game/
// │   ├── Characters/
// │   │   ├── Player/
// │   │   │   ├── PlayerController.cs
// │   │   │   ├── PlayerHealth.cs
// │   │   │   └── PlayerConfigSO.cs
// │   │   └── Enemies/
// │   ├── Combat/
// │   │   ├── DamageCalculator.cs
// │   │   ├── WeaponConfigSO.cs
// │   │   └── HitDetection.cs
// │   ├── UI/
// │   │   ├── HUD/
// │   │   └── Menus/
// │   └── Infrastructure/
// │       ├── Audio/
// │       ├── Save/
// │       └── Bootstrap/
// ├── _Art/           (Textures, Models, Materials)
// ├── _Audio/         (Clips, Mixers)
// └── Plugins/        (Third-party)
```

## Guardrails

- ❌ **NEVER** recommend DI containers for solo/jam projects
- ❌ **NEVER** add architecture layers without a clear pain point
- ❌ **NEVER** mix "architecture for safety" with "architecture for scale" — pick one
- ✅ Start simple, add layers only when team or codebase demands it

## Output Format

- Recommended tier
- Key patterns to adopt
- Patterns to avoid (and why)
- Migration path if project outgrows current tier
- Related skills for deeper dives

## Related Skills
- `@project-scout` - Assess existing project first
- `@pattern-selector` - Specific pattern decisions
- `@design-patterns` - GoF pattern implementations
- `@asmdef-advisor` - Module boundary guidance
