---
name: performance-advisor
description: "Unity performance red-flag advisor. Use this when the user wants performance review, Update optimization, allocation analysis, pooling decisions, or hot-path risk assessment. Also trigger for: 'my game stutters', 'frame drops', 'GC spikes', 'slow Update loop', 'too many draw calls', 'how to optimize this script', or any question about runtime performance — even if they don't say 'performance'. Do NOT use for deep memory profiling — use memory-profiler-expert instead."
---

# Performance Advisor

Use this skill for high-signal review of likely Unity performance issues. Focus on red flags, not speculative micro-optimizations.

## Check For

- Too many unrelated `Update` / `LateUpdate` / `FixedUpdate` loops
- Repeated `Find`, `GetComponent`, `Camera.main`, or tag lookups in hot paths
- Frequent `Instantiate` / `Destroy` suitable for pooling
- Avoidable per-frame allocations:
  - LINQ in Update
  - String formatting / concatenation
  - Closures and delegates
  - Boxing (value types to object)
- Reflection in runtime hot paths
- Expensive editor-only helpers leaking into runtime
- Physics, animation, or UI updates at wrong cadence

## Few-Shot Examples

### Example 1: Hot-Path Allocation Detection
**User**: "Review this Update method for performance."

**Agent**:
```csharp
// ❌ BEFORE: Multiple allocations per frame
void Update()
{
    var enemies = FindObjectsOfType<Enemy>();           // Alloc + O(n) search
    var closest = enemies.OrderBy(e =>                   // LINQ alloc
        Vector3.Distance(transform.position, e.transform.position))
        .FirstOrDefault();
    Debug.Log($"Closest: {closest?.name}");             // String alloc
}

// ✅ AFTER: Zero allocations in hot path
private readonly List<Enemy> _cachedEnemies = new();
private float _scanTimer;

void Update()
{
    _scanTimer += Time.deltaTime;
    if (_scanTimer < 0.5f) return; // Scan every 0.5s, not every frame
    _scanTimer = 0f;

    // Use cached list, no LINQ
    Enemy closest = null;
    float minDist = float.MaxValue;
    foreach (var enemy in _cachedEnemies)
    {
        float dist = (transform.position - enemy.transform.position).sqrMagnitude;
        if (dist < minDist) { minDist = dist; closest = enemy; }
    }
}
```

### Example 2: Camera.main Cache
**User**: "Is Camera.main expensive?"

**Agent**:
```csharp
// ❌ BAD: Camera.main uses FindGameObjectWithTag internally — slow per frame
void Update()
{
    var cam = Camera.main; // Hidden FindGameObjectWithTag every frame
    transform.LookAt(cam.transform);
}

// ✅ GOOD: Cache once
private Camera _mainCamera;

void Awake()
{
    _mainCamera = Camera.main;
}

void Update()
{
    transform.LookAt(_mainCamera.transform);
}
```

### Example 3: String Comparison Optimization
**User**: "I compare animator states by name in Update."

**Agent**:
```csharp
// ❌ BAD: String comparison with GetCurrentAnimatorStateInfo
void Update()
{
    if (_animator.GetCurrentAnimatorStateInfo(0).IsName("Attack")) // String hash every frame
    {
        // ...
    }
}

// ✅ GOOD: Pre-hash the name
private static readonly int AttackHash = Animator.StringToHash("Attack");

void Update()
{
    if (_animator.GetCurrentAnimatorStateInfo(0).shortNameHash == AttackHash)
    {
        // ...
    }
}
```

## Output Format

- **Confirmed red flags**: Definite issues with evidence
- **Likely red flags**: Probable issues worth investigating
- **Changes worth doing now**: High-impact, low-effort fixes
- **Changes NOT worth doing now**: Premature optimizations
- **Expected gain category**: clarity / frame time / GC / scalability

## Guardrails

- Do not recommend large refactors without a meaningful hotspot
- Do not replace simple code with unreadable "optimized" code unless the hot path is real
- Profile first, optimize second

## Related Skills
- `@memory-profiler-expert` - Deep memory analysis
- `@object-pooling-system` - Pooling implementation
- `@mobile-optimization` - Mobile-specific optimization
- `@lod-occlusion-culling` - Rendering optimization
