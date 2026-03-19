---
name: memory-profiler-expert
description: "Unity Memory Profiler and memory optimization specialist. Use this when the user needs to investigate memory leaks, reduce memory footprint, analyze heap allocations, optimize texture memory, or debug out-of-memory crashes. Also trigger for: 'memory leak', 'out of memory', 'GC spikes', 'heap too large', 'texture memory', 'asset not unloaded', or any question about memory usage — even if they don't say 'memory profiler'. Do NOT use for general CPU performance — use performance-advisor instead."
---

# Memory Profiler Expert

## Overview
Deep memory analysis and optimization in Unity. Use the Memory Profiler package for snapshots, identify leaks, reduce heap allocations, and optimize asset memory footprint.

## When to Use
- Use when investigating memory leaks
- Use when OOM (Out of Memory) crashes occur
- Use when GC spikes cause frame drops
- Use when texture/asset memory is too high
- Use when memory grows over time without release

## Common Memory Issues

| Issue | Symptom | Tool |
|-------|---------|------|
| **Leak** | Memory grows over time | Memory Profiler snapshot comparison |
| **GC Spike** | Periodic frame drops | CPU Profiler → GC.Alloc |
| **Unloaded Asset** | Memory stays after scene unload | Memory Profiler → asset tree |
| **Texture Bloat** | High GPU memory | Memory Profiler → texture list |
| **Managed Heap** | Large C# allocations | Profiler → Managed Allocations |

## Best Practices
- ✅ Take snapshots before and after scene transitions
- ✅ Compare snapshots to find growing allocations
- ✅ Check for unreleased Addressable handles
- ✅ Use structs instead of classes for short-lived data
- ✅ Pool frequently allocated objects
- ❌ **NEVER** create closures in Update loops
- ❌ **NEVER** use LINQ in hot paths (allocates)
- ❌ **NEVER** concatenate strings in Update (use StringBuilder)

## Few-Shot Examples

### Example 1: Memory Leak Detection Pattern
**User**: "Memory grows every time I load a scene."

**Agent**:
```csharp
// Common leak: event subscriptions not cleaned up
// ❌ BEFORE: Subscribe in Start, never unsubscribe
public class LeakyListener : MonoBehaviour
{
    void Start()
    {
        GameEvents.OnEnemyKilled += HandleKill;
        // This listener is NEVER removed → holds reference → leak!
    }
}

// ✅ AFTER: Symmetric subscribe/unsubscribe
public class SafeListener : MonoBehaviour
{
    private void OnEnable() => GameEvents.OnEnemyKilled += HandleKill;
    private void OnDisable() => GameEvents.OnEnemyKilled -= HandleKill;

    private void HandleKill(Enemy e) { /* ... */ }
}

// Leak detection helper
public static class LeakDetector
{
    private static readonly Dictionary<string, WeakReference> _tracked = new();

    public static void Track(string id, object obj)
    {
        _tracked[id] = new WeakReference(obj);
    }

    public static void ReportLeaks()
    {
        GC.Collect();
        foreach (var (id, weakRef) in _tracked)
        {
            if (weakRef.IsAlive)
                Debug.LogWarning($"[LEAK] Object '{id}' still alive after GC");
        }
    }
}
```

### Example 2: Zero-Allocation Patterns
**User**: "Reduce GC spikes in gameplay."

**Agent**:
```csharp
public class ZeroAllocPatterns : MonoBehaviour
{
    // ❌ BAD: Allocates every frame
    void Update_Bad()
    {
        var enemies = FindObjectsOfType<Enemy>();           // Array alloc
        var sorted = enemies.OrderBy(e => e.Distance);      // LINQ alloc
        Debug.Log($"Count: {enemies.Length}");               // String alloc
    }

    // ✅ GOOD: Pre-allocated, zero GC
    private readonly List<Enemy> _enemyCache = new(64);
    private readonly StringBuilder _logBuilder = new(128);
    private readonly Collider[] _overlapResults = new Collider[32];

    void Update_Good()
    {
        // Pre-allocated overlap (no array alloc)
        int count = Physics.OverlapSphereNonAlloc(
            transform.position, 50f, _overlapResults);

        // Reuse list
        _enemyCache.Clear();
        for (int i = 0; i < count; i++)
        {
            if (_overlapResults[i].TryGetComponent<Enemy>(out var enemy))
                _enemyCache.Add(enemy);
        }

        // StringBuilder instead of string interpolation
        _logBuilder.Clear();
        _logBuilder.Append("Count: ").Append(_enemyCache.Count);
        // Use _logBuilder only if actually logging
    }
}
```

### Example 3: Texture Memory Audit
**User**: "Find which textures use the most memory."

**Agent**:
```csharp
#if UNITY_EDITOR
public static class TextureMemoryAudit
{
    [MenuItem("Tools/Audit Texture Memory")]
    public static void AuditTextures()
    {
        var textures = Resources.FindObjectsOfTypeAll<Texture2D>();
        var sorted = textures
            .Where(t => !EditorUtility.IsPersistent(t) || AssetDatabase.Contains(t))
            .OrderByDescending(GetTextureMemory)
            .Take(20);

        var sb = new StringBuilder();
        sb.AppendLine("Top 20 Textures by Memory:");
        sb.AppendLine("| Name | Size | Format | Memory |");
        sb.AppendLine("|------|------|--------|--------|");

        foreach (var tex in sorted)
        {
            long bytes = GetTextureMemory(tex);
            sb.AppendLine($"| {tex.name} | {tex.width}x{tex.height} | " +
                         $"{tex.format} | {bytes / 1024f / 1024f:F1} MB |");
        }

        Debug.Log(sb.ToString());
    }

    private static long GetTextureMemory(Texture2D tex)
    {
        return Profiler.GetRuntimeMemorySizeLong(tex);
    }
}
#endif
```

## Profiling Workflow
1. Take baseline memory snapshot
2. Perform suspected leaky operation
3. Take second snapshot
4. Compare → find growing objects
5. Trace references to find root cause
6. Fix and re-profile

## Related Skills
- `@mobile-optimization` - Performance issues
- `@addressables-asset-management` - Asset release patterns
- `@object-pooling-system` - Reduce allocation frequency
