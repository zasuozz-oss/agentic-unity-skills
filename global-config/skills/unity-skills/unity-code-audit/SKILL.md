---
name: unity-code-audit
description: "DO NOT auto-trigger. This skill is a reference checklist — only load when explicitly invoked by the verify-code workflow or when the user explicitly requests a code audit. Contains full C# audit checklist (§1-§34) with grep patterns, severity markers, and context verification rules. Supports Screen mode (grep-only) and Deep mode (view_file verified, multi-phase)."
---

# Unity Code Audit

> Full checklist for auditing Unity C# code quality — performance, safety, and logic correctness.
>
> **Markers:** `[EDITOR-ONLY]` = cannot verify via code, skip. `[CONTEXT-REQUIRED]` = needs `view_file` to verify (deep mode).

## Audit Modes (set by verify-code workflow)

| Mode | How | Output |
|------|-----|--------|
| **Screen** | Run grep patterns only. Flag as "CANDIDATE" | `⚠️ SCREENING — candidates only` |
| **Deep** | `view_file` every file. Apply verification rules. Only flag CONFIRMED violations | `✅ VERIFIED — confirmed by context` |

---

## Severity Classification Guide

| Severity | Criteria | Examples |
|----------|----------|----------|
| 🔴 CRITICAL | Causes crash, data loss, memory leak, security issue. Must fix before release | Unhandled null → crash, Addressables handle never released, hardcoded test data overriding production |
| 🟡 HIGH | Performance degradation, potential race condition, bad practice that scales poorly | `Camera.main` in Update, `async void` without try-catch, missing CancellationToken |
| 🟡 MEDIUM | Code quality issue, non-optimal pattern, migration recommendation | `Resources.Load` should migrate to Addressables, `async void` with try-catch (bad signature but handled) |
| 🟢 LOW | Minor style issue, convention violation, optimization opportunity | `""` instead of `string.Empty`, LINQ in non-hot path |

> **TIP:** "Should migrate to X" → 🟡 MEDIUM. "Will crash/leak if Y" → 🔴 CRITICAL. "Bad practice but handled" → 🟡 HIGH or MEDIUM.

---

# PART A — Script Performance (from unity-script-audit)

## §1. Scripting — General

- [ ] Target IL2CPP (not Mono) in master/release builds `[EDITOR-ONLY]`
- [ ] Disable script debugging in release builds `[EDITOR-ONLY]`
- [ ] Keep only the target architecture in PlayerSettings (e.g., ARM64 only) `[EDITOR-ONLY]`
- [ ] Avoid placing expensive operations in frequently called methods (`Update`, `LateUpdate`, `FixedUpdate`) or tight loops
  - Grep: `grep -rn "void Update\|void LateUpdate\|void FixedUpdate" --include="*.cs"`
  - Note: requires `view_file` to check method body `[CONTEXT-REQUIRED]`
- [ ] Replace per-object `Update()` with a custom `UpdateManager` / `BatchUpdate` for 10+ entities — also consider DOTS
  - Grep: `grep -rn "void Update()" --include="*.cs" | wc -l` — if >10 in one namespace, flag
- [ ] Use interlaced logic execution to split heavy logic across multiple frames `[CONTEXT-REQUIRED]`
- [ ] Use `CullingGroups` to pause out-of-screen subsystems `[CONTEXT-REQUIRED]`
- [ ] Consider CPU Slicing to reduce per-frame CPU cost `[CONTEXT-REQUIRED]`
- [ ] Don't use `Instantiate` during gameplay — instantiate during loading screens and pool
  - Grep: `grep -rn "Instantiate(" --include="*.cs"`
  - Filter: exclude files with "Pool" or "Loading" in name
- [ ] Use structs instead of classes for short-lived data `[CONTEXT-REQUIRED]`
- [ ] Use `String.Empty` instead of `""`
  - Grep: `grep -rn '= ""' --include="*.cs"`
- [ ] Write C# Jobs + Burst for slow operations (>0.2ms) on multiple elements (>4) `[CONTEXT-REQUIRED]`
- [ ] Implement DOTS for massive amounts of homogeneous elements `[CONTEXT-REQUIRED]`
- [ ] Keep per-frame allocations under 32 bytes `[CONTEXT-REQUIRED]`

---

## §2. Scripting — Caching & Component Access

- [ ] Cache `GetComponent<T>()` results in `Awake()` — never call in `Update()`
  - Grep: `grep -rn "GetComponent" --include="*.cs"`
  - Filter: exclude matches in Awake/Start/OnEnable
  - Severity: 🟡 High
- [ ] Cache `Camera.main` in `Awake()` — never call per-frame
  - Grep: `grep -rn "Camera\.main" --include="*.cs"`
  - Filter: exclude matches in Awake/Start
  - Severity: 🟡 High
- [ ] Cache `FindObjectOfType` / `GameObject.Find` results in `Awake()` — never call per-frame
  - Grep: `grep -rn "FindObjectOfType\|GameObject\.Find" --include="*.cs"`
  - Severity: 🟡 High
- [ ] Avoid garbage-generating methods such as `FindObjectsOfType`
  - Grep: `grep -rn "FindObjectsOfType" --include="*.cs"`
  - Severity: 🟡 High
- [ ] Cache delegates/lambdas as fields — do NOT create closures in `Update` loops `[CONTEXT-REQUIRED]`
- [ ] Use `Animator.StringToHash` for Animator parameter access instead of string lookups
  - Grep: `grep -rn "SetFloat\|SetBool\|SetInteger\|SetTrigger" --include="*.cs" | grep -v "StringToHash\|_hash\|Hash"`
  - Severity: 🟢 Low
- [ ] Use `const string` for tag/status comparisons instead of string literals
  - Grep: `grep -rn 'CompareTag("' --include="*.cs"`
  - Severity: 🟢 Low

---

## §3. Scripting — GC / Memory Allocations

- [ ] Pre-allocate and reuse objects via Object Pooling (`Queue<GameObject>` + `SetActive`) instead of `Instantiate`/`Destroy`
  - Grep: `grep -rn "Destroy(" --include="*.cs" | grep -v "OnDestroy\|DontDestroy"`
  - Severity: 🟡 High
- [ ] Use `StringBuilder` instead of string concatenation in loops
  - Grep: `grep -rn '"\s*+\s*"' --include="*.cs"`
  - Note: high noise — `[CONTEXT-REQUIRED]` for hot path check
- [ ] Use `CompareTag()` instead of `tag == "string"` (avoids string allocation)
  - Grep: `grep -rn '\.tag\s*==' --include="*.cs"`
  - Severity: 🟢 Low
- [ ] Use non-allocating Physics APIs: `RaycastNonAlloc()`, `OverlapSphereNonAlloc()`, `OverlapAreaNonAlloc()`, etc.
  - Grep: `grep -rn "Physics\.Raycast\b\|Physics\.OverlapSphere\b\|Physics\.OverlapArea\b" --include="*.cs"`
  - Filter: exclude NonAlloc variants
  - Severity: 🟡 High
- [ ] Cache `RaycastHit` struct as a field instead of declaring new local variable per-frame `[CONTEXT-REQUIRED]`
- [ ] Pre-allocate buffers — don't allocate new arrays/lists every frame (e.g., `private Collider[] _hitBuffer = new Collider[20]`) `[CONTEXT-REQUIRED]`
- [ ] Avoid LINQ in hot paths (`Where`, `Select`, `ToList`) — use traditional `for`/`foreach` loops
  - Grep: `grep -rn "\.Where(\|\.Select(\|\.ToList(\|\.Any(\|\.First(" --include="*.cs"`
  - Severity: 🟡 High — but only in Update/hot paths
- [ ] Minimize string manipulations in hot paths: concatenation (`+`), `string.Format()`, `ToString()` all create heap allocations — use `StringBuilder` `[CONTEXT-REQUIRED]`
- [ ] Use generic collections (`List<T>`, `Dictionary<TKey,TValue>`, `HashSet<T>`) instead of non-generic (`ArrayList`, `Hashtable`) to avoid boxing
  - Grep: `grep -rn "ArrayList\|Hashtable" --include="*.cs"`
  - Severity: 🟡 High
- [ ] Avoid C# boxing — be cautious when passing value types to methods expecting `object` `[CONTEXT-REQUIRED]`
- [ ] Use `sqrMagnitude` instead of `Vector3.Distance` to avoid square root calculation
  - Grep: `grep -rn "Vector3\.Distance\|Vector2\.Distance" --include="*.cs"`
  - Severity: 🟢 Low
- [ ] Call `Resources.UnloadUnusedAssets()` after finishing with assets loaded from `Resources.Load` to prevent memory leaks
  - Grep: `grep -rn "Resources\.Load" --include="*.cs"`
  - Severity: 🟡 High
- [ ] Use indirect references instead of direct references for heavy content (global/seldomly-used GameObjects should NOT direct-reference heavy assets) `[CONTEXT-REQUIRED]`

---

## §4. Scripting — Coroutines

- [ ] Coroutines are not endless and use small local variables `[CONTEXT-REQUIRED]`
- [ ] Cache `WaitForSeconds` as `static readonly` field — do NOT create new instance every yield
  - Grep: `grep -rn "new WaitForSeconds" --include="*.cs"`
  - Severity: 🟡 High
- [ ] Cache `WaitForEndOfFrame` as `static readonly` field
  - Grep: `grep -rn "new WaitForEndOfFrame" --include="*.cs"`
  - Severity: 🟡 High
- [ ] Cache `WaitForFixedUpdate` as `static readonly` field
  - Grep: `grep -rn "new WaitForFixedUpdate" --include="*.cs"`
  - Severity: 🟡 High
- [ ] `StopAllCoroutines()` in `OnDisable` if coroutine should not continue when object is inactive
  - Grep: `grep -rn "StartCoroutine" --include="*.cs"`
  - Cross-check: verify file has `StopAllCoroutines` or `StopCoroutine` in OnDisable/OnDestroy
  - Severity: 🟡 High

---

## §5. Scripting — Async / Scene Loading

- [ ] Do NOT use synchronous `SceneManager.LoadScene()` — it blocks the main thread
  - Grep: `grep -rn "SceneManager\.LoadScene(" --include="*.cs" | grep -v "LoadSceneAsync"`
  - Severity: 🔴 Critical
- [ ] Use `SceneManager.LoadSceneAsync()` with coroutine for non-blocking scene loading
- [ ] Use an almost-empty animated initial scene for loading screens while the next scene loads asynchronously `[CONTEXT-REQUIRED]`

---

## §6. Scripting — UI Code Patterns

- [ ] Change materials' color property via script instead of using multiple sprites with color variations `[CONTEXT-REQUIRED]`
- [ ] Do not use auto-layout components (`ContentSizeFitter`, `LayoutElement`, `HorizontalLayoutGroup`, `VerticalLayoutGroup`, `GridLayoutGroup`) on dynamic UI — disable them once they've done their work
  - Grep: `grep -rn "ContentSizeFitter\|LayoutElement\|HorizontalLayoutGroup\|VerticalLayoutGroup\|GridLayoutGroup" --include="*.cs"`
  - Severity: 🟡 High
- [ ] Avoid per-frame changes in UI components to reduce canvas rebuild events: `RectTransform`, colors, sprites, text and other properties `[CONTEXT-REQUIRED]`
- [ ] Update UI text only when value actually changes — compare old vs new before assigning `myText.text` `[CONTEXT-REQUIRED]`
- [ ] Disable layout rebuilders (`ContentSizeFitter`, layout groups, `CanvasScaler`, `GraphicRaycaster`) if UI is static `[CONTEXT-REQUIRED]`
- [ ] Ensure UI elements batch effectively — same canvas + same material (atlas/font) for batching `[CONTEXT-REQUIRED]`
- [ ] Flatten complex/deeply nested UI hierarchies — many layout-triggering components are CPU-intensive `[CONTEXT-REQUIRED]`
- [ ] Too many unique materials breaks batching — even slight material variations (different `_Color` on identical materials) increase draw calls `[CONTEXT-REQUIRED]`
- [ ] `MaterialPropertyBlock` usage: Built-in RP only — breaks SRP Batcher and GPU Resident Drawer in URP/HDRP. Use Material Variants or texture atlases instead
  - Grep: `grep -rn "MaterialPropertyBlock" --include="*.cs"`
  - Severity: 🟡 High
- [ ] Consider `TextMeshPro` (non-UI variant) instead of `TextMeshProUGUI` for lighter CPU when Canvas system is not needed `[CONTEXT-REQUIRED]`
- [ ] Consider `SpriteRenderer` instead of `Image` for UI elements — Sprite does NOT render as full rectangle `[CONTEXT-REQUIRED]`

---

## §7. Scripting — Rendering API Usage

- [ ] Use `Graphics.DrawMeshInstanced()` for manual GPU instancing when automatic instancing is insufficient `[CONTEXT-REQUIRED]`
- [ ] Use `StaticBatchingUtility.Combine()` for run-time merging of children under a root object `[CONTEXT-REQUIRED]`
- [ ] Use `Mesh.CombineMeshes()` for manual mesh combination at run-time `[CONTEXT-REQUIRED]`
- [ ] All particle systems are procedural `[EDITOR-ONLY]`
- [ ] Restrict cameras' culling mask to the strictly required layers `[EDITOR-ONLY]`
- [ ] Adjust camera Far Clipping Plane to exclude distant objects `[EDITOR-ONLY]`
- [ ] Use a single camera on mobile — each camera = 1 full render pass
  - Grep: `grep -rn "Camera\b" --include="*.cs" | grep "new\|AddComponent"`
  - Severity: 🟡 High

---

## §8. Scripting — Physics Code

- [ ] Disable auto-sync transforms `[EDITOR-ONLY]`
- [ ] Enable re-use collision callbacks `[EDITOR-ONLY]`
- [ ] Avoid mesh colliders — use compound colliders of simple shapes instead `[EDITOR-ONLY]`
- [ ] Adapt physics budget via `Time.fixedDeltaTime` — smaller value = more frequent updates = more CPU `[CONTEXT-REQUIRED]`
- [ ] Try multibox pruning broadphase `[EDITOR-ONLY]`
- [ ] Add more layers and minimize the layer collision matrix enabled pairs `[EDITOR-ONLY]`
- [ ] Avoid over-reliance on complex real-time physics: many interacting rigidbodies with continuous collision detection is a CPU bottleneck `[CONTEXT-REQUIRED]`

---

## §9. Scripting — NavMesh / AI

- [ ] Bake NavMesh in editor instead of generating dynamically at runtime `[EDITOR-ONLY]`
- [ ] Use `NavMesh Obstacle` component for moving obstacles instead of regenerating NavMesh `[EDITOR-ONLY]`
- [ ] Implement Off-Mesh Links for gaps, jumps, ladders `[EDITOR-ONLY]`
- [ ] Define NavMesh Areas with different traversal costs (Walkable, Jump, Mud, Water) for intelligent pathfinding `[EDITOR-ONLY]`
- [ ] Reduce NavMeshAgent Update Frequency for distant agents `[CONTEXT-REQUIRED]`
- [ ] Increase NavMeshAgent Stopping Distance to avoid unnecessary micro-adjustments `[CONTEXT-REQUIRED]`

---

## §10. Scripting — Animation Code

- [ ] Use animators exclusively for characters — prefer tweening and custom scripts for non-character use
  - Grep: `grep -rn "Animator\|GetComponent<Animator>" --include="*.cs"`
  - Note: flag UI files using Animator `[CONTEXT-REQUIRED]`
- [ ] Avoid animators in UI at all costs
  - Grep: `grep -rn "Animator" --include="*.cs"` in UI-related folders
  - Severity: 🟡 High

---

## §11. Scripting — Memory Management

- [ ] Do NOT use the Resources directory — migrate to Addressables
  - Grep: `grep -rn "Resources\.Load" --include="*.cs"`
  - Severity: 🟡 High
- [ ] Delegate content to CDNs and download at run-time using Addressables `[CONTEXT-REQUIRED]`
- [ ] Use `Resources.UnloadUnusedAssets()` strategically after scene transitions (aware it can cause a hitch) `[CONTEXT-REQUIRED]`
- [ ] Properly unload assets from memory when no longer needed after leaving a level `[CONTEXT-REQUIRED]`
- [ ] Always unsubscribe from events in `OnDestroy` when subscribing in `OnEnable`/`Start`
  - Grep: `grep -rn "\.onClick\.AddListener\|\.onValueChanged\.AddListener\|+=" --include="*.cs"`
  - Cross-check: verify matching RemoveListener/Unsubscribe exists
  - Severity: 🔴 Critical
- [ ] Enable Incremental GC: Project Settings > Player > Other Settings > Optimization > Use Incremental GC `[EDITOR-ONLY]`

---

## §12. Scripting — Shader Scripting

- [ ] Avoid conditional branches in shaders `[CONTEXT-REQUIRED]`
- [ ] Use the smallest variable precision needed (e.g., `half` over `float`) `[CONTEXT-REQUIRED]`
- [ ] Avoid multi-pass shaders `[CONTEXT-REQUIRED]`
- [ ] Don't use `GrabPass` on mobile
  - Grep: `grep -rn "GrabPass" --include="*.shader"`
  - Severity: 🔴 Critical
- [ ] No Standard Shader on mobile — use simpler alternatives `[EDITOR-ONLY]`
- [ ] Use deferred rendering only on high-end desktop hardware `[EDITOR-ONLY]`
- [ ] Consider baking lighting information on diffuse texture for static elements `[CONTEXT-REQUIRED]`
- [ ] Create custom Opaque Sprite Shader: disable blending, write stencil buffer so pixels behind don't render `[CONTEXT-REQUIRED]`
- [ ] Create custom UI Stencil-Tested Shader: UI shader checks stencil to skip fragments already covered by opaque sprites `[CONTEXT-REQUIRED]`
- [ ] GPU Instancing shader: use `#pragma multi_compile_instancing`, `UNITY_INSTANCING_BUFFER`, `UNITY_DEFINE_INSTANCED_PROP` macros `[CONTEXT-REQUIRED]`
- [ ] Avoid sampling from reflection probes `[EDITOR-ONLY]`
- [ ] Measure shader complexity with tools like Mali Offline Shader Compiler `[CONTEXT-REQUIRED]`

---

## §13. Scripting — Profiling & Performance Measurement

- [ ] Increase Unity Profiler frame count to 2000 in settings to detect spikes (Unity 2019.3+) `[EDITOR-ONLY]`
- [ ] Use Unity Profiler Deep Profile to find `GC.Alloc` allocations `[EDITOR-ONLY]`
- [ ] Use Unity Profiler to identify CPU vs GPU bound bottlenecks `[EDITOR-ONLY]`
- [ ] Enable "Record Allocations" in Profiler to identify GC spikes `[EDITOR-ONLY]`
- [ ] Examine CPU Usage, GPU Usage, Memory, Rendering, and Physics modules in Profiler `[EDITOR-ONLY]`
- [ ] Click on spike frames for detailed call stacks showing allocation sources `[EDITOR-ONLY]`
- [ ] Use Memory Profiler package for detailed memory snapshots `[EDITOR-ONLY]`
- [ ] Use Frame Debugger (Window → Analysis → Frame Debugger) to verify draw calls, SRP Batch entries, Hybrid Batch Group `[EDITOR-ONLY]`
- [ ] Automate measuring performance continuously — use the P3 Optimization Framework `[EDITOR-ONLY]`

---

## §14. Scripting — DOTween Safety *(unity-dotween-safety)*

- [ ] Always `.SetLink(gameObject)` on virtual tweens (`DOTween.To`, `DOVirtual.Float`, `DOVirtual.DelayedCall`) to auto-kill on destroy
  - Grep: `grep -rn "DOTween\.To\|DOVirtual\.Float\|DOVirtual\.DelayedCall" --include="*.cs"`
  - Cross-check: verify `.SetLink(` on same line or next
  - Severity: 🔴 Critical
- [ ] Always `.Kill()` tweens in `OnDestroy` or `OnDisable`
  - Grep: `grep -rn "DOTween\|\.DOFade\|\.DOScale\|\.DOMove" --include="*.cs"`
  - Cross-check: verify file has `Kill` or `SetLink` in OnDestroy/OnDisable
  - Severity: 🔴 Critical
- [ ] `DOKill()` before starting a new tween on the same target — prevents overlapping tweens fighting each other
  - Grep: `grep -rn "\.DOFade\|\.DOScale\|\.DOMove\|\.DOColor" --include="*.cs"`
  - Note: flag files with multiple tweens on same target `[CONTEXT-REQUIRED]`
- [ ] Call `DOTween.Kill(target)` BEFORE manually resetting animated properties (prevents flicker from active tween overriding reset) `[CONTEXT-REQUIRED]`
- [ ] Always `.SetTarget(gameObject)` on `DOTween.Sequence()` — sequences do NOT inherit target, `DOTween.Kill(target)` won't find orphaned sequences
  - Grep: `grep -rn "DOTween\.Sequence" --include="*.cs"`
  - Cross-check: verify `.SetTarget(` exists
  - Severity: 🔴 Critical
- [ ] Refactor `DOKill()` in `OnDestroy` → replace with `.SetLink()` at tween creation site — OnDestroy cleanup is fragile and redundant `[CONTEXT-REQUIRED]`
- [ ] Never start new tweens inside `OnDestroy` — DOTween singleton may recreate itself causing a leak
  - Grep: `grep -rn "OnDestroy" --include="*.cs"` then check for DOTween calls in body `[CONTEXT-REQUIRED]`
- [ ] Never leave looping tweens (`.SetLoops(-1)`) without `SetLink` or explicit kill
  - Grep: `grep -rn "SetLoops(-1)\|SetLoops( -1)" --include="*.cs"`
  - Cross-check: verify `.SetLink(` exists
  - Severity: 🔴 Critical
- [ ] Await multi-stage tween sequences with `.ToUniTask()` — never fire-and-forget tweens in async methods `[CONTEXT-REQUIRED]`
- [ ] Do NOT rely on `OnComplete` for critical state changes — tween can be killed before completion `[CONTEXT-REQUIRED]`
- [ ] Use `DOTween.Sequence()` for pure animation chains; use `await tween.ToUniTask()` when logic is needed between steps `[CONTEXT-REQUIRED]`

---

## §15. Scripting — Async/Await Safety *(unity-async-patterns)*

- [ ] NEVER use `async void` — use `async UniTaskVoid` or `async UniTask` for fire-and-forget
  - Grep: `grep -rn "async void" --include="*.cs"`
  - Exception: OK for Unity Button handlers (Inspector assignment) + if try-catch wrapped
  - Severity: 🟡 High
- [ ] Always pass `CancellationToken` to async methods (use `destroyCancellationToken` for MonoBehaviour lifetime)
  - Grep: `grep -rn "async UniTask\|async Task" --include="*.cs" | grep -v "CancellationToken"`
  - Severity: 🟡 High
- [ ] Guard against destroyed objects after every `await`: `if (this == null) return;`
  - Grep: `grep -rn "await " --include="*.cs"`
  - Cross-check: verify `this == null` or `!this` after await `[CONTEXT-REQUIRED]`
- [ ] Guard `StartCoroutine` after await: check both `this == null` AND `gameObject.activeInHierarchy` `[CONTEXT-REQUIRED]`
- [ ] Follow Cancel → Dispose → Recreate pattern for `CancellationTokenSource` management
  - Grep: `grep -rn "CancellationTokenSource" --include="*.cs"`
  - Cross-check: verify Cancel + Dispose before new instance `[CONTEXT-REQUIRED]`
- [ ] Use `try/catch/finally` with `finally` block for guaranteed UI cleanup (ShowLoading/HideLoading pairing) `[CONTEXT-REQUIRED]`
- [ ] Use `UniTask.WhenAll()` for parallel async operations instead of sequential awaits `[CONTEXT-REQUIRED]`
- [ ] Use `.AttachExternalCancellation(ct)` to link external cancellation to async operations `[CONTEXT-REQUIRED]`
- [ ] Add `#if UNITY_EDITOR if (!Application.isPlaying) return; #endif` guard after await in Editor-sensitive code `[CONTEXT-REQUIRED]`
- [ ] Prefer `UniTask` over `Task` — UniTask has zero GC allocation
  - Grep: `grep -rn "async Task\b" --include="*.cs" | grep -v "UniTask"`
  - Severity: 🟡 High

---

## §16. Scripting — Object Pooling

- [ ] Pre-warm pools at scene start (instantiate initial pool size during loading, not gameplay) `[CONTEXT-REQUIRED]`
- [ ] Set max pool size to prevent unbounded memory growth `[CONTEXT-REQUIRED]`
- [ ] Use `IPoolable` interface (`OnSpawn`/`OnDespawn`) to reset pooled objects before reuse `[CONTEXT-REQUIRED]`
- [ ] Return objects to pool via `SetActive(false)` instead of `Destroy()`
  - Grep: `grep -rn "Destroy(" --include="*.cs" | grep -v "OnDestroy\|DontDestroy"`
  - Severity: 🟡 High
- [ ] Do NOT pool objects spawned fewer than 5 times per minute — overhead > benefit `[CONTEXT-REQUIRED]`
- [ ] Use Unity's built-in `ObjectPool<T>` for plain C# objects (non-MonoBehaviour) `[CONTEXT-REQUIRED]`
- [ ] Always reset ALL state in pooled objects before reuse (position, scale, references, timers) `[CONTEXT-REQUIRED]`

---

## §17. Scripting — Canvas Performance Code Patterns *(unity-ui-performance)*

- [ ] Split canvases by update frequency: Static (background), HUD (event-driven), Dynamic (per-frame) `[CONTEXT-REQUIRED]`
- [ ] Bulk-disable `raycastTarget` on non-interactive elements (Labels, decorative Images) `[CONTEXT-REQUIRED]`
- [ ] Never animate UI transforms on a canvas with many static children — isolate animated elements into separate canvas `[CONTEXT-REQUIRED]`
- [ ] Never instantiate/destroy list items in scroll views — use object pooling `[CONTEXT-REQUIRED]`
- [ ] Profile `Canvas.BuildBatch` and `Canvas.SendWillRenderCanvases` spikes in CPU Profiler `[EDITOR-ONLY]`
- [ ] Use `CanvasGroup` for visibility transitions instead of `SetActive(true/false)` on large hierarchies
  - Grep: `grep -rn "SetActive" --include="*.cs"` in UI folders
  - Severity: 🟢 Low
- [ ] All UI text must use `TextMeshProUGUI` — `UnityEngine.UI.Text` is forbidden
  - Grep: `grep -rn "UnityEngine\.UI\.Text\|using UnityEngine.UI" --include="*.cs"`
  - Cross-check: verify no `Text` component usage (only `TextMeshProUGUI`)
  - Severity: 🟡 High

---

## §18. Scripting — Addressables Lifecycle *(unity-addressables)*

- [ ] Every `LoadAssetAsync` MUST have a matching `Addressables.Release(handle)` — missing release = memory leak
  - Grep: `grep -rn "LoadAssetAsync\|InstantiateAsync" --include="*.cs"`
  - Cross-check: verify `Release(` exists in same file
  - Severity: 🔴 Critical
- [ ] Track all active `AsyncOperationHandle` instances for cleanup in `OnDestroy` `[CONTEXT-REQUIRED]`
- [ ] Never release an already-released handle — track release state `[CONTEXT-REQUIRED]`
- [ ] Use `AssetReference` in Inspector for type-safe addressable references `[CONTEXT-REQUIRED]`
- [ ] Do NOT use `Resources.Load` — migrate to Addressables
  - Grep: `grep -rn "Resources\.Load" --include="*.cs"`
  - Severity: 🟡 High
- [ ] Take Memory Profiler snapshots before and after scene transitions to detect unreleased Addressable handles `[EDITOR-ONLY]`
- [ ] Use labels for batch preload operations (`Addressables.LoadAssetsAsync` by label) `[CONTEXT-REQUIRED]`

---

## §19. Scripting — Backend / Network Performance

- [ ] Use component-level request gating (per-component `_isFetching` flag) instead of global blocking flag `[CONTEXT-REQUIRED]`
- [ ] Set `_isFetching = true` SYNCHRONOUSLY before async call to prevent race conditions from `Update()` triggers `[CONTEXT-REQUIRED]`
- [ ] Add 800ms success cooldown after load completion to prevent rapid consecutive fetches during aggressive scrolling `[CONTEXT-REQUIRED]`
- [ ] Add 500ms failed request cooldown to prevent infinite retry loops from `Update()` polling `[CONTEXT-REQUIRED]`
- [ ] Filter duplicate items before notifying UI adapter — skip `NotifyDataChanged()` if no new items (prevents flicker) `[CONTEXT-REQUIRED]`
- [ ] Implement retry with exponential backoff for server errors (500+)
  - Grep: `grep -rn "catch\|retry\|Retry" --include="*.cs"`
  - Note: check error handling pattern `[CONTEXT-REQUIRED]`
- [ ] Use `UniTask` for async API requests instead of coroutines — zero GC, proper error handling
  - Grep: `grep -rn "UnityWebRequest\|WWW\b" --include="*.cs"`
  - Severity: 🟡 High
- [ ] Never block main thread with synchronous web requests
  - Grep: `grep -rn "\.downloadHandler\.text\b" --include="*.cs"` outside of async context
  - Severity: 🔴 Critical

---

## §20. Scripting — Debug & Logging Safety *(unity-csharp-standards)*

- [ ] Never use `Debug.Log` in release builds — wrap with `[Conditional("UNITY_EDITOR")]` or `[Conditional("DEVELOPMENT_BUILD")]`
  - Grep: `grep -rn "Debug\.Log(" --include="*.cs" | grep -v "LogError\|LogWarning\|LogException"`
  - Exception: `Debug.LogError`, `Debug.LogWarning`, `Debug.LogException` are **error detection — keep them**
  - Severity: 🟡 High
- [ ] Use conditional compilation wrapper class (e.g., `GameLog.Log()`) that compiles out in release
  - Grep: `grep -rn "Debug\.Log\b" --include="*.cs"` — count total, suggest wrapper if >20
- [ ] Always prefix logs with `[ClassName]` for traceability `[CONTEXT-REQUIRED]`
- [ ] No log spam in hot paths (`Update`, `LateUpdate`, `FixedUpdate`)
  - Grep: `grep -rn "Debug\.Log" --include="*.cs"` then check if in Update methods `[CONTEXT-REQUIRED]`
  - Severity: 🔴 Critical
- [ ] Guard debug visualizations with `#if UNITY_EDITOR || DEVELOPMENT_BUILD` `[CONTEXT-REQUIRED]`
- [ ] Never use reflection in hot paths on mobile
  - Grep: `grep -rn "GetType()\|typeof(\|MethodInfo\|FieldInfo\|PropertyInfo" --include="*.cs"`
  - Severity: 🟡 High

---

## §21. Scripting — ANR & Crash Safety *(unity_anr_crash_checklist)*

### Crash Prevention
- [ ] Always null-check `GetComponent` / `FindObjectOfType` results before using — uncaught `NullReferenceException` crashes the app `[CONTEXT-REQUIRED]`
- [ ] Never use destroyed objects in callbacks, coroutines, or events — check `object != null` before access `[CONTEXT-REQUIRED]`
- [ ] Always check array/list bounds before accessing elements — `IndexOutOfRangeException` crashes on mobile `[CONTEXT-REQUIRED]`
- [ ] Prevent stack overflow from infinite recursion — `Update` calling functions that call back into themselves, or circular event loops `[CONTEXT-REQUIRED]`

### ANR Prevention (Main Thread Blocking)
- [ ] Never call synchronous IO on main thread during gameplay: `File.ReadAllText`, `File.WriteAllText`, `PlayerPrefs.Save` — use async or background thread
  - Grep: `grep -rn "File\.ReadAllText\|File\.WriteAllText\|PlayerPrefs\.Save" --include="*.cs"`
  - Severity: 🔴 Critical
- [ ] Never use `while (!www.isDone) {}` busy-wait pattern — use `yield return www` or `await`
  - Grep: `grep -rn "while.*isDone\|while.*!.*isDone" --include="*.cs"`
  - Severity: 🔴 Critical

### Memory Leak & Stability
- [ ] Static collections (`static List`, `static Dictionary`) holding Unity object references must be cleaned on scene unload — destroyed objects stay in static collections causing leaks
  - Grep: `grep -rn "static.*List<\|static.*Dictionary<\|static.*HashSet<" --include="*.cs"`
  - Severity: 🟡 High
- [ ] Always call `Destroy(texture)` on runtime-created `Texture2D` when done — undisposed `Texture2D` leaks GPU memory
  - Grep: `grep -rn "new Texture2D" --include="*.cs"`
  - Cross-check: verify `Destroy(` for the texture
  - Severity: 🔴 Critical
- [ ] Avoid `SendMessage()` / `BroadcastMessage()` — use direct references, interfaces, or events (SendMessage uses reflection, is slow, and silently fails)
  - Grep: `grep -rn "SendMessage\|BroadcastMessage" --include="*.cs"`
  - Severity: 🟡 High

### Lifecycle & Singleton Safety
- [ ] Singleton pattern must check for duplicate instances on `Awake()` and destroy extras — `DontDestroyOnLoad` without guard creates duplicates on scene reload
  - Grep: `grep -rn "DontDestroyOnLoad" --include="*.cs"`
  - Cross-check: verify `if (instance != null)` guard exists
  - Severity: 🔴 Critical
- [ ] Avoid `Awake()` depending on initialization order of other objects — use Script Execution Order or lazy initialization pattern `[CONTEXT-REQUIRED]`
- [ ] `OnDisable` must stop all coroutines and cancel timers — `StopAllCoroutines()` in `OnDisable` if script can be disabled at runtime `[CONTEXT-REQUIRED]`
- [ ] Save critical data in `OnApplicationPause(true)` instead of only `OnApplicationQuit()` — on mobile, `OnApplicationQuit` may never be called (OS kill)
  - Grep: `grep -rn "OnApplicationQuit" --include="*.cs"`
  - Cross-check: verify `OnApplicationPause` also saves data
  - Severity: 🟡 High
- [ ] Background threads must use `CancellationToken` and check for cancellation — never use `Thread.Abort()` (causes unpredictable state)
  - Grep: `grep -rn "Thread\.Abort\|new Thread" --include="*.cs"`
  - Severity: 🔴 Critical

---

# PART B — Logic Correctness (from unity-logic-audit)

## §22. Lifecycle Ordering & Initialization

- [ ] `Awake` only contains self-contained reference caching — no dependency on other objects' state `[CONTEXT-REQUIRED]`
- [ ] `Start` used for scene-dependent initialization where other objects must be ready `[CONTEXT-REQUIRED]`
- [ ] No gameplay logic executes before initialization is complete (guard with `IsInit` or equivalent flag) `[CONTEXT-REQUIRED]`
- [ ] Singleton cleanup in `OnDestroy`: `if (instance == this) instance = null;`
  - Grep: `grep -rn "static.*instance\|Instance" --include="*.cs"`
  - Cross-check: verify cleanup in OnDestroy
  - Severity: 🟡 High
- [ ] No `static instance` references persist after scene unload — verify cleanup path
  - Grep: `grep -rn "static.*Instance\|static.*_instance" --include="*.cs"`
  - Severity: 🟡 High

---

## §23. Event Subscription Symmetry

- [ ] Every `OnEnable` subscribe has a matching `OnDisable` unsubscribe
  - Grep: `grep -rn "OnEnable\|OnDisable" --include="*.cs"`
  - Cross-check: count += in OnEnable vs -= in OnDisable
  - Severity: 🔴 Critical
- [ ] Every `AddListener` has a matching `RemoveListener` in the symmetric lifecycle method
  - Grep: `grep -rn "AddListener\|RemoveListener" --include="*.cs"`
  - Cross-check: count AddListener vs RemoveListener per file
  - Severity: 🔴 Critical
- [ ] No event subscriptions in `Awake`/`Start` without corresponding unsubscription in `OnDisable`/`OnDestroy` `[CONTEXT-REQUIRED]`
- [ ] Static event subscriptions are especially dangerous — verify they always unsubscribe
  - Grep: `grep -rn "static.*event\|static.*Action\|static.*Event" --include="*.cs"`
  - Severity: 🔴 Critical
- [ ] Delegate chains (`+=`) never accumulate duplicates across re-enable cycles `[CONTEXT-REQUIRED]`

---

## §24. Resource Pairing Principle

Every "acquire" operation MUST have a matching "release" in ALL terminal paths.

- [ ] `ShowLoading()` ↔ `HideLoading()` — verified in success, failure, cancellation, and early return paths
  - Grep: `grep -rn "ShowLoading\|HideLoading" --include="*.cs"`
  - Cross-check: count Show vs Hide per method `[CONTEXT-REQUIRED]`
- [ ] `Subscribe` ↔ `Unsubscribe` — symmetric in enable/disable
- [ ] `DOTween.Play()` ↔ `Kill()` — linked or explicitly killed
- [ ] `CancellationTokenSource` created ↔ `Cancel()` + `Dispose()` called
  - Grep: `grep -rn "new CancellationTokenSource" --include="*.cs"`
  - Cross-check: verify Cancel + Dispose `[CONTEXT-REQUIRED]`
- [ ] File/Stream `Open` ↔ `Close` — wrapped in `using` or `finally`
  - Grep: `grep -rn "File\.Open\|StreamReader\|StreamWriter" --include="*.cs"`
  - Cross-check: verify `using` or `finally` block
  - Severity: 🟡 High
- [ ] Loading spinners never stuck — check every `return` statement in async methods for `HideLoading()` call `[CONTEXT-REQUIRED]`

---

## §25. Null Safety & Guard Patterns

- [ ] `this == null` check after EVERY `await` point in a MonoBehaviour
  - Grep: `grep -rn "await " --include="*.cs"`
  - Cross-check: next line should have `this == null` or `!this` check `[CONTEXT-REQUIRED]`
- [ ] `gameObject.activeInHierarchy` check before `StartCoroutine` after `await` `[CONTEXT-REQUIRED]`
- [ ] Serialized Inspector fields: no redundant null checks (Fail-Fast principle) unless explicitly optional `[CONTEXT-REQUIRED]`
- [ ] Remote data fields: explicit null logging with `[ClassName] field is null` for diagnosis `[CONTEXT-REQUIRED]`
- [ ] Optional references: explicit fallback behavior provided (not silent null) `[CONTEXT-REQUIRED]`
- [ ] No `NullReferenceException` hiding — prefer early return with log over try-catch swallow `[CONTEXT-REQUIRED]`

---

## §26. State Flow Analysis

- [ ] Enumerate all state variable combinations — identify impossible/untested states `[CONTEXT-REQUIRED]`
- [ ] Every early return (guard clause) handles required cleanup and flag resets `[CONTEXT-REQUIRED]`
- [ ] Boolean flags (`_isLoading`, `_isFetching`, `_isInit`) are reset in ALL exit paths (success, failure, cancellation)
  - Grep: `grep -rn "_isLoading\|_isFetching\|_isInit\|_isProcessing" --include="*.cs"`
  - Note: `[CONTEXT-REQUIRED]` to verify all paths
- [ ] No "flag stuck" scenarios: verify every path that sets `true` also has a path that sets `false` `[CONTEXT-REQUIRED]`
- [ ] State transitions are atomic — no partial state updates visible to other components `[CONTEXT-REQUIRED]`
- [ ] `forceRefresh` parameters bypass "Already Active" guards but respect cooldowns `[CONTEXT-REQUIRED]`

---

## §27. Race Condition Prevention

- [ ] CancellationTokenSource cancelled before creating new one (`_cts?.Cancel(); _cts?.Dispose();`)
  - Grep: `grep -rn "new CancellationTokenSource" --include="*.cs"`
  - Cross-check: verify previous CTS is cancelled
  - Severity: 🟡 High
- [ ] Identity/Recycle check after `await` for pooled/recycled objects: `if (this.data != capturedData) return;` `[CONTEXT-REQUIRED]`
- [ ] No instance fields used to store async results — use local variables in async scope `[CONTEXT-REQUIRED]`
- [ ] Duplicate request guards: `if (_isFetchingData) return;` before any API call `[CONTEXT-REQUIRED]`
- [ ] Same-page cooldown: prevent rapid identical requests (e.g., page reload spam) `[CONTEXT-REQUIRED]`
- [ ] CancellationToken passed to `ToUniTask()` — stale tween results don't apply to wrong context `[CONTEXT-REQUIRED]`

---

## §28. Async/Await Lifecycle Safety

- [ ] No `async void` except Unity event handlers — use `async UniTask` with proper error handling
  - Grep: `grep -rn "async void" --include="*.cs"`
  - Exception: Unity Button handlers, lifecycle methods with try-catch
  - Severity: 🟡 High (duplicate of §15 — cross-ref)
- [ ] `CancellationToken` propagated through entire async call chain `[CONTEXT-REQUIRED]`
- [ ] Cancelled operations handle `OperationCanceledException` gracefully (not re-thrown as errors) `[CONTEXT-REQUIRED]`
- [ ] Async methods in `OnDestroy` context: no new operations after destruction begins `[CONTEXT-REQUIRED]`
- [ ] `UniTask.Delay` checks cancellation token after resuming `[CONTEXT-REQUIRED]`
- [ ] Hybrid Safety Pattern used for recycled objects: CTS + identity validation + null check `[CONTEXT-REQUIRED]`

---

## §29. Error Handling Completeness

- [ ] `try-catch` blocks include `finally` for cleanup (especially `HideLoading`, flag reset)
  - Grep: `grep -rn "try\b" --include="*.cs"`
  - Cross-check: verify `finally` block exists `[CONTEXT-REQUIRED]`
- [ ] Error handling never swallows exceptions silently — at minimum log the error
  - Grep: `grep -rn "catch.*{" --include="*.cs"`
  - Cross-check: verify catch block has Log or throw `[CONTEXT-REQUIRED]`
- [ ] Network error classification: distinguish Retryable (429, timeout) vs Fatal (403, 404) `[CONTEXT-REQUIRED]`
- [ ] Exponential backoff for retryable errors — not immediate retry loops `[CONTEXT-REQUIRED]`
- [ ] Failed API calls reset UI state (loading spinners, disabled buttons) `[CONTEXT-REQUIRED]`
- [ ] User-facing error feedback: silent failures are bugs (show toast/retry button) `[CONTEXT-REQUIRED]`

---

## §30. Pagination & Data Integrity

- [ ] `PageIndex` incremented in exactly ONE place — centralized in base class `[CONTEXT-REQUIRED]`
- [ ] No double-increment bugs: child classes do NOT manually increment after base class does `[CONTEXT-REQUIRED]`
- [ ] `hasMorePage` guard allows refresh: `if (!hasMorePage && !isRefresh)` — refresh always proceeds `[CONTEXT-REQUIRED]`
- [ ] Duplicate data prevention: `IsSameItem` override correctly compares unique IDs `[CONTEXT-REQUIRED]`
- [ ] Empty data result does NOT block future pagination — PageIndex still advances `[CONTEXT-REQUIRED]`
- [ ] Local data list count matches OSA/UI data count — no "invisible items" bug `[CONTEXT-REQUIRED]`
- [ ] `ValidatePageIndexAfterDelete()` only called on user deletion, NOT in automated load flow `[CONTEXT-REQUIRED]`

---

## §31. Delegation & Method Interaction

- [ ] Flag management delegated to the "leaf" method — callers don't pre-set flags `[CONTEXT-REQUIRED]`
- [ ] No "Early Gatekeeper Bug": `RefreshPageWithSign` should NOT set `_isFetchingData = true` before calling `LoadNewPage()` `[CONTEXT-REQUIRED]`
- [ ] Callback methods (`OnRequestDone`, `OnComplete`) check object validity before applying state `[CONTEXT-REQUIRED]`
- [ ] Parent-child method interaction: no hidden side effects from calling order `[CONTEXT-REQUIRED]`
- [ ] `OnComplete`/`OnKill` callbacks for DOTween don't rely on critical state changes — tween can be killed early `[CONTEXT-REQUIRED]`

---

## §32. Scene Transition Safety

- [ ] No new MonoBehaviour creation or `Instantiate` in `OnDestroy`
  - Grep: `grep -rn "OnDestroy" --include="*.cs"` then check for Instantiate/AddComponent `[CONTEXT-REQUIRED]`
- [ ] Persistent objects (`DontDestroyOnLoad`) properly clean up when scenes change `[CONTEXT-REQUIRED]`
- [ ] Scene-specific references (UI elements, cameras) are re-acquired after scene load `[CONTEXT-REQUIRED]`
- [ ] Async operations check scene validity after `await` — may have transitioned during wait `[CONTEXT-REQUIRED]`
- [ ] Loading screen cleanup: verify `HideLoading` called even if target scene load fails `[CONTEXT-REQUIRED]`

---

## §33. Data Validation & Edge Cases

- [ ] API response data validated before use — null/empty checks on critical fields `[CONTEXT-REQUIRED]`
- [ ] Collection operations check bounds: no `IndexOutOfRange` from empty lists `[CONTEXT-REQUIRED]`
- [ ] Division by zero guards on dynamic values (e.g., `PageSize > 0 ? PageSize : DefaultSize`) `[CONTEXT-REQUIRED]`
- [ ] Enum switch statements have `default` case — handle unexpected values
  - Grep: `grep -rn "switch\b" --include="*.cs"`
  - Cross-check: verify `default:` case exists `[CONTEXT-REQUIRED]`
- [ ] Date/time comparisons account for timezone and format differences `[CONTEXT-REQUIRED]`
- [ ] String comparisons use `StringComparison.Ordinal` or `OrdinalIgnoreCase` — no culture-dependent bugs `[CONTEXT-REQUIRED]`

---

## §34. Production Data Safety

- [ ] No hardcoded test IDs, test URLs, or debug overrides in production code paths
  - Grep: `grep -rn "test\|debug\|hardcode\|TODO\|HACK\|FIXME" --include="*.cs"`
  - Note: High noise — `[CONTEXT-REQUIRED]` to distinguish real test data from variable names
  - Severity: 🔴 Critical (can override production behavior silently)
- [ ] Feature flags and test overrides are behind `#if DEVELOPMENT_BUILD` or server-side config, not in runtime code
  - Grep: `grep -rn "#if" --include="*.cs" | grep -v "UNITY_EDITOR\|DEVELOPMENT_BUILD"`
  - Note: `[CONTEXT-REQUIRED]` — check if conditionals guard test-only behavior

---

# PART C — Deep Audit Verification Rules

> [!IMPORTANT]
> **Deep mode ONLY.** These rules define HOW to verify `[CONTEXT-REQUIRED]` items.
> MUST `view_file` before flagging any violation.

### async void safety
- **Grep:** `async void`
- **Verify:**
  1. Unity Button handler (gán trên Inspector)? → **NOT a violation**
  2. Unity lifecycle (`Start`, `Awake`, `OnEnable`)? → **🟡 LOW** if try-catch wrapped, **🔴 CRITICAL** if not
  3. Body has try-catch wrapping? → **🟡 LOW** (bad signature but exception handled)
  4. No try-catch + awaits network/Addressables? → **🔴 CRITICAL**
  5. No try-catch + only UI logic (DOTween, delay)? → **🟡 MEDIUM**

### Debug.Log in production
- **Grep:** `Debug.Log`
- **Verify:**
  1. `Debug.LogError(...)` → **NOT a violation** — error detection, KEEP
  2. `Debug.LogException(...)` → **NOT a violation** — crash reporting, KEEP
  3. `Debug.LogWarning(...)` with error context → **NOT a violation**
  4. `Debug.Log(...)` general info → **🟡 MEDIUM** — wrap with conditional
  5. `Debug.Log(...)` in Update/LateUpdate/FixedUpdate → **🔴 CRITICAL**

### Event subscription symmetry
- **Grep:** `AddListener\|RemoveListener\|+=\|-=`
- **Verify:**
  1. Count `AddListener` vs `RemoveListener` in same file — must be equal
  2. Check subscribe location (OnEnable) has matching unsubscribe (OnDisable)
  3. `Awake`/`Start` subscribe without `OnDestroy` unsubscribe? → **🔴 CRITICAL**
  4. Static event subscribe without unsubscribe? → **🔴 CRITICAL**
  5. Lambda subscribe `+=` without corresponding `-=`? → **🔴 CRITICAL**

### DontDestroyOnLoad guard
- **Grep:** `DontDestroyOnLoad`
- **Verify:**
  1. Has `if (instance != null) { Destroy(gameObject); return; }` guard? → **PASS**
  2. No duplicate guard? → **🔴 CRITICAL**

### DOTween leak prevention
- **Grep:** `DOTween.To\|DOVirtual.\|.DOFade\|.DOScale\|.DOMove`
- **Verify:**
  1. Has `.SetLink(gameObject)`? → **PASS**
  2. Has `DOKill()` or `.Kill()` in OnDestroy/OnDisable? → **🟡 MEDIUM** (fragile but functional)
  3. Neither SetLink nor Kill? → **🔴 CRITICAL** — memory leak

### CancellationTokenSource management
- **Grep:** `new CancellationTokenSource`
- **Verify:**
  1. Previous CTS cancelled before new? `_cts?.Cancel(); _cts?.Dispose();` → **PASS**
  2. No Cancel/Dispose before reassignment? → **🔴 CRITICAL** — CTS leak

### ShowLoading/HideLoading pairing
- **Grep:** `ShowLoading\|HideLoading`
- **Verify:**
  1. Every `ShowLoading` has matching `HideLoading` in try-catch-finally? → **PASS**
  2. Early return after ShowLoading without HideLoading? → **🔴 CRITICAL**
  3. HideLoading only in success path, not in catch/finally? → **🔴 CRITICAL**

### Boolean flag stuck
- **Grep:** `_isLoading\|_isFetching\|_isInit\|_isProcessing`
- **Verify:**
  1. Flag set to `true` — verify ALL paths (success, failure, cancellation) eventually set `false`
  2. Flag in try block without finally reset? → **🔴 CRITICAL**

### this == null after await
- **Grep:** `await ` in MonoBehaviour files
- **Verify:**
  1. After `await`, next lines check `this == null` or `!this`? → **PASS**
  2. Await followed directly by `this.` member access without guard? → **🟡 HIGH**
  3. Addressables/network await without null check? → **🔴 CRITICAL**

### Addressables release leak
- **Grep:** `LoadAssetAsync\|InstantiateAsync`
- **Verify:**
  1. Matching `Release(handle)` or `Addressables.Release()` in same method? → **PASS**
  2. Handle tracked in list for OnDestroy cleanup? → **PASS**
  3. Release via separate public method (manual release pattern — e.g., `ReleaseAsset()`, `ReleaseInstance()`)? → **PASS** — caller responsible for release
  4. Release only in error paths but NOT in success path, AND no manual release method exists? → **🔴 CRITICAL**
  5. No release found anywhere (no same-method, no tracking, no manual method)? → **🔴 CRITICAL** — memory leak

### Texture2D leak
- **Grep:** `new Texture2D`
- **Verify:**
  1. `Destroy(texture)` called when done in same method? → **PASS**
  2. Texture created AND consumed locally (never returned or stored) without Destroy? → **🔴 CRITICAL** — GPU memory leak
  3. Method returns `Sprite` or `Texture2D` (factory/loader pattern)? → **Run cross-file check below**

- **Cross-file check for factory pattern** (step 3):
  1. Use `mcp_gitnexus_context(name: "FactoryMethodName")` → get all callers
  2. For each caller, `view_file` and grep for `Destroy(.*texture)` or `Destroy(.*sprite\.texture)` or cleanup helper (e.g. `ReleaseSprite`)
  3. **At least 1 caller destroys texture** → **PASS** — managed by caller
  4. **No caller destroys texture** AND no centralized release method exists → **🟡 WARNING** — flag for user to verify lifecycle management
  5. Note in finding: "Factory method — no caller-side Destroy found. Verify if lifecycle managed elsewhere"

### Static collection holding Unity refs
- **Grep:** `static.*List<\|static.*Dictionary<\|static.*HashSet<`
- **Verify:**
  1. Contains Unity objects (GameObject, Component, Texture)? → Check cleanup on scene unload
  2. Contains plain data (string, int)? → **PASS**
  3. Unity object refs without cleanup? → **🟡 HIGH** — memory leak on scene change

---

## Related Skills
- `@unity-csharp-standards` — Coding conventions and design review
- `@unity-async-patterns` — Deep async/await patterns and lifecycle safety
- `@unity-dotween-safety` — DOTween-specific lifecycle and memory patterns
- `@unity-addressables` — Addressables async loading, memory-safe release
- `@unity-ui-performance` — UI rendering, state safety, responsive design
