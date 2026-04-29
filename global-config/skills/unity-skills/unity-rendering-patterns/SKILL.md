---
name: unity-rendering-patterns
description: "Use when Unity code touches rendering pipeline: camera culling, GPU instancing, DrawMeshInstanced, Animator.StringToHash, GrabPass prohibition, shader precision, or particle system optimization."
---

# Rendering Patterns, Animation & Shaders

## Overview
Rules for Unity rendering API usage, animation controller patterns, and shader scripting for mobile performance. Most Editor-specific items require manual inspection.

## Markers
`[EDITOR-ONLY]` = cannot verify via grep, requires manual Editor check.

---

## §1 — Rendering API Usage

- [ ] Use `Graphics.DrawMeshInstanced()` for manual GPU instancing when automatic instancing is insufficient
- [ ] Use `StaticBatchingUtility.Combine()` for run-time merging of children under a root object
- [ ] Use `Mesh.CombineMeshes()` for manual mesh combination at run-time
- [ ] All particle systems use procedural mode `[EDITOR-ONLY]`
- [ ] Restrict camera culling mask to strictly required layers `[EDITOR-ONLY]`
- [ ] Adjust camera Far Clipping Plane to exclude distant objects `[EDITOR-ONLY]`
- [ ] Use a single camera on mobile — each camera = 1 full render pass
  - Grep: `grep -rn "Camera\b" --include="*.cs" | grep "new\|AddComponent"`
  - Severity: 🟡 HIGH

---

## §2 — Animation Code

- [ ] Use Animators **exclusively for characters** — prefer DOTween or custom scripts for UI and non-character elements
  - Grep: `grep -rn "Animator\|GetComponent<Animator>" --include="*.cs"`
  - Flag: UI files using Animator
  - Severity: 🟡 HIGH
- [ ] Avoid Animators in UI at all costs — they trigger canvas rebuilds and are CPU-expensive on mobile
  - Grep: `grep -rn "Animator" --include="*.cs"` in UI-related folders
  - Severity: 🟡 HIGH
- [ ] Cache `Animator.StringToHash` for all parameter lookups — never pass raw strings per-frame
  - Grep: `grep -rn "SetFloat\|SetBool\|SetInteger\|SetTrigger" --include="*.cs" | grep -v "StringToHash\|_hash\|Hash"`
  - Severity: 🟢 LOW

```csharp
// ❌ BAD: string lookup every call
_animator.SetBool("IsRunning", true);

// ✅ GOOD: cached hash in Awake
private static readonly int IsRunningHash = Animator.StringToHash("IsRunning");
_animator.SetBool(IsRunningHash, true);
```

---

## §3 — Shader Scripting

- [ ] Avoid conditional branches in shaders — uniform branching preferred `[EDITOR-ONLY]`
- [ ] Use smallest variable precision needed: `half` over `float` on mobile `[EDITOR-ONLY]`
- [ ] Avoid multi-pass shaders — each pass = additional draw call `[EDITOR-ONLY]`
- [ ] Do NOT use `GrabPass` on mobile — extremely expensive, copies framebuffer
  - Grep: `grep -rn "GrabPass" --include="*.shader"`
  - Severity: 🔴 CRITICAL
- [ ] No Standard Shader on mobile — use simpler alternatives (Unlit, Mobile/Diffuse) `[EDITOR-ONLY]`
- [ ] Use deferred rendering only on high-end desktop hardware `[EDITOR-ONLY]`
- [ ] Consider baking lighting on diffuse texture for static elements `[EDITOR-ONLY]`
- [ ] GPU Instancing shader: use `#pragma multi_compile_instancing`, `UNITY_INSTANCING_BUFFER`, `UNITY_DEFINE_INSTANCED_PROP`
- [ ] Avoid sampling from reflection probes in mobile shaders `[EDITOR-ONLY]`
- [ ] Measure shader complexity with Mali Offline Shader Compiler for ARM GPUs

---

## Related Skills
- `@unity-asset-audit` — Shader variants, material optimization, draw calls
- `@unity-csharp-standards` — Hot-path caching, GetComponent, Animator.StringToHash
- `@unity-dotween-safety` — Use DOTween instead of Animator for UI animations
