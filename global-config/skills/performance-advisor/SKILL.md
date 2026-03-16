---
name: performance-advisor
description: "Unity performance red-flag advisor. Use this when the user wants performance review, Update optimization, allocation analysis, pooling decisions, or hot-path risk assessment."
---

# Performance Advisor

> Adapted from [Besty0728/Unity-Skills](https://github.com/Besty0728/Unity-Skills) (MIT License)

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
