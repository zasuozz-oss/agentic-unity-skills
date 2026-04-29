---
name: unity-physics-ai
description: "Use when writing Unity Physics or NavMesh code: RaycastNonAlloc, OverlapSphereNonAlloc, Layer Collision Matrix, fixedDeltaTime tuning, NavMeshAgent stagger pattern, or NavMeshObstacle setup."
---

# Physics & NavMesh AI

## Overview
Performance and correctness rules for Unity physics simulation and NavMesh pathfinding. Most configuration items are Editor-only — focus on the scriptable patterns.

## Markers
`[EDITOR-ONLY]` = cannot verify via grep, requires manual Editor check.

---

## §1 — Physics Code

- [ ] Disable auto-sync transforms in Physics Settings `[EDITOR-ONLY]`
- [ ] Enable "Reuse Collision Callbacks" in Physics Settings `[EDITOR-ONLY]`
- [ ] Avoid mesh colliders — use compound colliders of simple primitives instead `[EDITOR-ONLY]`
- [ ] Adapt physics update frequency via `Time.fixedDeltaTime` — smaller value = more CPU cost
  - Note: 30fps physics (`1f/30f`) is sufficient for most mobile games
- [ ] Try Multibox Pruning broadphase for scenes with many Rigidbodies `[EDITOR-ONLY]`
- [ ] Add physics layers and minimize enabled pairs in Layer Collision Matrix `[EDITOR-ONLY]`
- [ ] Avoid over-reliance on complex real-time physics — many Rigidbodies + continuous collision = CPU bottleneck
- [ ] Use non-allocating Physics APIs in hot paths
  - Grep: `grep -rn "Physics\.Raycast\b\|Physics\.OverlapSphere\b\|Physics\.OverlapArea\b" --include="*.cs"`
  - Filter: exclude NonAlloc variants
  - Severity: 🟡 HIGH — allocates every frame

```csharp
// ❌ BAD: allocates every frame
var hits = Physics.RaycastAll(ray);

// ✅ GOOD: reuse pre-allocated buffer
private readonly RaycastHit[] _hitBuffer = new RaycastHit[10];

int count = Physics.RaycastNonAlloc(ray, _hitBuffer);
for (int i = 0; i < count; i++) { /* process _hitBuffer[i] */ }
```

---

## §2 — NavMesh / AI

- [ ] Bake NavMesh in Editor — never generate dynamically at runtime `[EDITOR-ONLY]`
- [ ] Use `NavMeshObstacle` component for moving obstacles — avoids full NavMesh regeneration `[EDITOR-ONLY]`
- [ ] Implement Off-Mesh Links for gaps, jumps, ladders `[EDITOR-ONLY]`
- [ ] Define NavMesh Areas with different traversal costs (Walkable, Jump, Mud, Water) `[EDITOR-ONLY]`
- [ ] Reduce `NavMeshAgent` update frequency for distant agents — stagger updates across frames
- [ ] Increase `NavMeshAgent.stoppingDistance` to avoid unnecessary micro-adjustments near destination

```csharp
// ✅ Stagger distant agent updates across frames
private void Update()
{
    if (Time.frameCount % _updateInterval != _agentId % _updateInterval) return;
    _agent.SetDestination(target.position);
}
```

---

## Related Skills
- `@unity-csharp-standards` — Hot-path rules, GC reduction, caching
- `@unity-crash-safety` — Null checks on physics query results
