---
name: unity-script-audit
description: "CODE-LEVEL performance audit checklist. Activate when systematically auditing Unity C# scripts — covers caching, GC allocations, coroutines, async/await safety, object pooling, DOTween, physics, UI code patterns, Addressables lifecycle, backend integration, debug logging, and ANR/crash prevention. For real-time code quality guidance DURING development, use unity-csharp-standards instead. For ASSET-level audit, use unity-asset-audit. Trigger keywords: 'script audit', 'code performance review', 'verify scripts', 'script checklist', 'code optimization audit', 'ANR prevention', 'GC audit'."
---

# Scripts Verify Checklist — Unity Performance

> Comprehensive checklist of all criteria related to **code / scripting / logic** that affect performance.
>
> **Usage**: Mark ✅ on items that have been verified and pass requirements.

---

## 1. Scripting — General

- [ ] Target IL2CPP (not Mono) in master/release builds
- [ ] Disable script debugging in release builds
- [ ] Keep only the target architecture in PlayerSettings (e.g., ARM64 only)
- [ ] Avoid placing expensive operations in frequently called methods (`Update`, `LateUpdate`, `FixedUpdate`) or tight loops
- [ ] Replace per-object `Update()` with a custom `UpdateManager` / `BatchUpdate` for 10+ entities — also consider DOTS
- [ ] Use interlaced logic execution to split heavy logic across multiple frames
- [ ] Use `CullingGroups` to pause out-of-screen subsystems
- [ ] Consider CPU Slicing to reduce per-frame CPU cost
- [ ] Don't use `Instantiate` during gameplay — instantiate during loading screens and pool
- [ ] Use structs instead of classes for short-lived data
- [ ] Use `String.Empty` instead of `""`
- [ ] Write C# Jobs + Burst for slow operations (>0.2ms) on multiple elements (>4)
- [ ] Implement DOTS for massive amounts of homogeneous elements
- [ ] Keep per-frame allocations under 32 bytes

---

## 2. Scripting — Caching & Component Access

- [ ] Cache `GetComponent<T>()` results in `Awake()` — never call in `Update()`
- [ ] Cache `Camera.main` in `Awake()` — never call per-frame
- [ ] Cache `FindObjectOfType` / `GameObject.Find` results in `Awake()` — never call per-frame
- [ ] Avoid garbage-generating methods such as `FindObjectsOfType`
- [ ] Cache delegates/lambdas as fields — do NOT create closures in `Update` loops
- [ ] Use `Animator.StringToHash` for Animator parameter access instead of string lookups
- [ ] Use `const string` for tag/status comparisons instead of string literals

---

## 3. Scripting — GC / Memory Allocations

- [ ] Pre-allocate and reuse objects via Object Pooling (`Queue<GameObject>` + `SetActive`) instead of `Instantiate`/`Destroy`
- [ ] Use `StringBuilder` instead of string concatenation in loops
- [ ] Use `CompareTag()` instead of `tag == "string"` (avoids string allocation)
- [ ] Use non-allocating Physics APIs: `RaycastNonAlloc()`, `OverlapSphereNonAlloc()`, `OverlapAreaNonAlloc()`, etc.
- [ ] Cache `RaycastHit` struct as a field instead of declaring new local variable per-frame
- [ ] Pre-allocate buffers — don't allocate new arrays/lists every frame (e.g., `private Collider[] _hitBuffer = new Collider[20]`)
- [ ] Avoid LINQ in hot paths (`Where`, `Select`, `ToList`) — use traditional `for`/`foreach` loops
- [ ] Minimize string manipulations in hot paths: concatenation (`+`), `string.Format()`, `ToString()` all create heap allocations — use `StringBuilder`
- [ ] Use generic collections (`List<T>`, `Dictionary<TKey,TValue>`, `HashSet<T>`) instead of non-generic (`ArrayList`, `Hashtable`) to avoid boxing
- [ ] Avoid C# boxing — be cautious when passing value types to methods expecting `object`
- [ ] Use `sqrMagnitude` instead of `Vector3.Distance` to avoid square root calculation
- [ ] Call `Resources.UnloadUnusedAssets()` after finishing with assets loaded from `Resources.Load` to prevent memory leaks
- [ ] Use indirect references instead of direct references for heavy content (global/seldomly-used GameObjects should NOT direct-reference heavy assets)

---

## 4. Scripting — Coroutines

- [ ] Coroutines are not endless and use small local variables
- [ ] Cache `WaitForSeconds` as `static readonly` field — do NOT create new instance every yield
- [ ] Cache `WaitForEndOfFrame` as `static readonly` field
- [ ] Cache `WaitForFixedUpdate` as `static readonly` field
- [ ] `StopAllCoroutines()` in `OnDisable` if coroutine should not continue when object is inactive

---

## 5. Scripting — Async / Scene Loading

- [ ] Do NOT use synchronous `SceneManager.LoadScene()` — it blocks the main thread
- [ ] Use `SceneManager.LoadSceneAsync()` with coroutine for non-blocking scene loading
- [ ] Use an almost-empty animated initial scene for loading screens while the next scene loads asynchronously

---

## 6. Scripting — UI Code Patterns

- [ ] Change materials' color property via script instead of using multiple sprites with color variations
- [ ] Do not use auto-layout components (`ContentSizeFitter`, `LayoutElement`, `HorizontalLayoutGroup`, `VerticalLayoutGroup`, `GridLayoutGroup`) on dynamic UI — disable them once they've done their work
- [ ] Avoid per-frame changes in UI components to reduce canvas rebuild events: `RectTransform`, colors, sprites, text and other properties
- [ ] Update UI text only when value actually changes — compare old vs new before assigning `myText.text`
- [ ] Disable layout rebuilders (`ContentSizeFitter`, layout groups, `CanvasScaler`, `GraphicRaycaster`) if UI is static
- [ ] Ensure UI elements batch effectively — same canvas + same material (atlas/font) for batching
- [ ] Flatten complex/deeply nested UI hierarchies — many layout-triggering components are CPU-intensive
- [ ] Too many unique materials breaks batching — even slight material variations (different `_Color` on identical materials) increase draw calls
- [ ] `MaterialPropertyBlock` usage: Built-in RP only — breaks SRP Batcher and GPU Resident Drawer in URP/HDRP. Use Material Variants or texture atlases instead
- [ ] Consider `TextMeshPro` (non-UI variant) instead of `TextMeshProUGUI` for lighter CPU when Canvas system is not needed
- [ ] Consider `SpriteRenderer` instead of `Image` for UI elements — Sprite does NOT render as full rectangle

---

## 7. Scripting — Rendering API Usage

- [ ] Use `Graphics.DrawMeshInstanced()` for manual GPU instancing when automatic instancing is insufficient
- [ ] Use `StaticBatchingUtility.Combine()` for run-time merging of children under a root object
- [ ] Use `Mesh.CombineMeshes()` for manual mesh combination at run-time
- [ ] All particle systems are procedural
- [ ] Restrict cameras' culling mask to the strictly required layers
- [ ] Adjust camera Far Clipping Plane to exclude distant objects
- [ ] Use a single camera on mobile — each camera = 1 full render pass

---

## 8. Scripting — Physics Code

- [ ] Disable auto-sync transforms
- [ ] Enable re-use collision callbacks
- [ ] Avoid mesh colliders — use compound colliders of simple shapes instead
- [ ] Adapt physics budget via `Time.fixedDeltaTime` — smaller value = more frequent updates = more CPU
- [ ] Try multibox pruning broadphase
- [ ] Add more layers and minimize the layer collision matrix enabled pairs
- [ ] Avoid over-reliance on complex real-time physics: many interacting rigidbodies with continuous collision detection is a CPU bottleneck

---

## 9. Scripting — NavMesh / AI

- [ ] Bake NavMesh in editor instead of generating dynamically at runtime
- [ ] Use `NavMesh Obstacle` component for moving obstacles instead of regenerating NavMesh
- [ ] Implement Off-Mesh Links for gaps, jumps, ladders
- [ ] Define NavMesh Areas with different traversal costs (Walkable, Jump, Mud, Water) for intelligent pathfinding
- [ ] Reduce NavMeshAgent Update Frequency for distant agents
- [ ] Increase NavMeshAgent Stopping Distance to avoid unnecessary micro-adjustments

---

## 10. Scripting — Animation Code

- [ ] Use animators exclusively for characters — prefer tweening and custom scripts for non-character use
- [ ] Avoid animators in UI at all costs

---

## 11. Scripting — Memory Management

- [ ] Do NOT use the Resources directory — migrate to Addressables
- [ ] Delegate content to CDNs and download at run-time using Addressables
- [ ] Use `Resources.UnloadUnusedAssets()` strategically after scene transitions (aware it can cause a hitch)
- [ ] Properly unload assets from memory when no longer needed after leaving a level
- [ ] Always unsubscribe from events in `OnDestroy` when subscribing in `OnEnable`/`Start`
- [ ] Enable Incremental GC: Project Settings > Player > Other Settings > Optimization > Use Incremental GC

---

## 12. Scripting — Shader Scripting

- [ ] Avoid conditional branches in shaders
- [ ] Use the smallest variable precision needed (e.g., `half` over `float`)
- [ ] Avoid multi-pass shaders
- [ ] Don't use `GrabPass` on mobile
- [ ] No Standard Shader on mobile — use simpler alternatives
- [ ] Use deferred rendering only on high-end desktop hardware
- [ ] Consider baking lighting information on diffuse texture for static elements
- [ ] Create custom Opaque Sprite Shader: disable blending, write stencil buffer so pixels behind don't render
- [ ] Create custom UI Stencil-Tested Shader: UI shader checks stencil to skip fragments already covered by opaque sprites
- [ ] GPU Instancing shader: use `#pragma multi_compile_instancing`, `UNITY_INSTANCING_BUFFER`, `UNITY_DEFINE_INSTANCED_PROP` macros
- [ ] Avoid sampling from reflection probes
- [ ] Measure shader complexity with tools like Mali Offline Shader Compiler

---

## 13. Scripting — Profiling & Performance Measurement

- [ ] Increase Unity Profiler frame count to 2000 in settings to detect spikes (Unity 2019.3+)
- [ ] Use Unity Profiler Deep Profile to find `GC.Alloc` allocations
- [ ] Use Unity Profiler to identify CPU vs GPU bound bottlenecks
- [ ] Enable "Record Allocations" in Profiler to identify GC spikes
- [ ] Examine CPU Usage, GPU Usage, Memory, Rendering, and Physics modules in Profiler
- [ ] Click on spike frames for detailed call stacks showing allocation sources
- [ ] Use Memory Profiler package for detailed memory snapshots
- [ ] Use Frame Debugger (Window → Analysis → Frame Debugger) to verify draw calls, SRP Batch entries, Hybrid Batch Group
- [ ] Automate measuring performance continuously — use the P3 Optimization Framework

---

## 14. Scripting — DOTween Safety *(unity-dotween-safety)*

- [ ] Always `.SetLink(gameObject)` on virtual tweens (`DOTween.To`, `DOVirtual.Float`, `DOVirtual.DelayedCall`) to auto-kill on destroy
- [ ] Always `.Kill()` tweens in `OnDestroy` or `OnDisable`
- [ ] `DOKill()` before starting a new tween on the same target — prevents overlapping tweens fighting each other
- [ ] Call `DOTween.Kill(target)` BEFORE manually resetting animated properties (prevents flicker from active tween overriding reset)
- [ ] Always `.SetTarget(gameObject)` on `DOTween.Sequence()` — sequences do NOT inherit target, `DOTween.Kill(target)` won't find orphaned sequences
- [ ] Refactor `DOKill()` in `OnDestroy` → replace with `.SetLink()` at tween creation site — OnDestroy cleanup is fragile and redundant
- [ ] Never start new tweens inside `OnDestroy` — DOTween singleton may recreate itself causing a leak
- [ ] Never leave looping tweens (`.SetLoops(-1)`) without `SetLink` or explicit kill
- [ ] Await multi-stage tween sequences with `.ToUniTask()` — never fire-and-forget tweens in async methods
- [ ] Do NOT rely on `OnComplete` for critical state changes — tween can be killed before completion
- [ ] Use `DOTween.Sequence()` for pure animation chains; use `await tween.ToUniTask()` when logic is needed between steps

---

## 15. Scripting — Async/Await Safety *(unity-async-patterns)*

- [ ] NEVER use `async void` — use `async UniTaskVoid` or `async UniTask` for fire-and-forget
- [ ] Always pass `CancellationToken` to async methods (use `destroyCancellationToken` for MonoBehaviour lifetime)
- [ ] Guard against destroyed objects after every `await`: `if (this == null) return;`
- [ ] Guard `StartCoroutine` after await: check both `this == null` AND `gameObject.activeInHierarchy`
- [ ] Follow Cancel → Dispose → Recreate pattern for `CancellationTokenSource` management
- [ ] Use `try/catch/finally` with `finally` block for guaranteed UI cleanup (ShowLoading/HideLoading pairing)
- [ ] Use `UniTask.WhenAll()` for parallel async operations instead of sequential awaits
- [ ] Use `.AttachExternalCancellation(ct)` to link external cancellation to async operations
- [ ] Add `#if UNITY_EDITOR if (!Application.isPlaying) return; #endif` guard after await in Editor-sensitive code
- [ ] Prefer `UniTask` over `Task` — UniTask has zero GC allocation

---

## 16. Scripting — Object Pooling

- [ ] Pre-warm pools at scene start (instantiate initial pool size during loading, not gameplay)
- [ ] Set max pool size to prevent unbounded memory growth
- [ ] Use `IPoolable` interface (`OnSpawn`/`OnDespawn`) to reset pooled objects before reuse
- [ ] Return objects to pool via `SetActive(false)` instead of `Destroy()`
- [ ] Do NOT pool objects spawned fewer than 5 times per minute — overhead > benefit
- [ ] Use Unity's built-in `ObjectPool<T>` for plain C# objects (non-MonoBehaviour)
- [ ] Always reset ALL state in pooled objects before reuse (position, scale, references, timers)

---

## 17. Scripting — Canvas Performance Code Patterns *(unity-ui-performance)*

- [ ] Split canvases by update frequency: Static (background), HUD (event-driven), Dynamic (per-frame)
- [ ] Bulk-disable `raycastTarget` on non-interactive elements (Labels, decorative Images)
- [ ] Never animate UI transforms on a canvas with many static children — isolate animated elements into separate canvas
- [ ] Never instantiate/destroy list items in scroll views — use object pooling
- [ ] Profile `Canvas.BuildBatch` and `Canvas.SendWillRenderCanvases` spikes in CPU Profiler
- [ ] Use `CanvasGroup` for visibility transitions instead of `SetActive(true/false)` on large hierarchies
- [ ] All UI text must use `TextMeshProUGUI` — `UnityEngine.UI.Text` is forbidden

---

## 18. Scripting — Addressables Lifecycle *(unity-addressables)*

- [ ] Every `LoadAssetAsync` MUST have a matching `Addressables.Release(handle)` — missing release = memory leak
- [ ] Track all active `AsyncOperationHandle` instances for cleanup in `OnDestroy`
- [ ] Never release an already-released handle — track release state
- [ ] Use `AssetReference` in Inspector for type-safe addressable references
- [ ] Do NOT use `Resources.Load` — migrate to Addressables
- [ ] Take Memory Profiler snapshots before and after scene transitions to detect unreleased Addressable handles
- [ ] Use labels for batch preload operations (`Addressables.LoadAssetsAsync` by label)

---

## 19. Scripting — Backend / Network Performance

- [ ] Use component-level request gating (per-component `_isFetching` flag) instead of global blocking flag
- [ ] Set `_isFetching = true` SYNCHRONOUSLY before async call to prevent race conditions from `Update()` triggers
- [ ] Add 800ms success cooldown after load completion to prevent rapid consecutive fetches during aggressive scrolling
- [ ] Add 500ms failed request cooldown to prevent infinite retry loops from `Update()` polling
- [ ] Filter duplicate items before notifying UI adapter — skip `NotifyDataChanged()` if no new items (prevents flicker)
- [ ] Implement retry with exponential backoff for server errors (500+)
- [ ] Use `UniTask` for async API requests instead of coroutines — zero GC, proper error handling
- [ ] Never block main thread with synchronous web requests

---

## 20. Scripting — Debug & Logging Safety *(unity-csharp-standards)*

- [ ] Never use `Debug.Log` in release builds — wrap with `[Conditional("UNITY_EDITOR")]` or `[Conditional("DEVELOPMENT_BUILD")]`
- [ ] Use conditional compilation wrapper class (e.g., `GameLog.Log()`) that compiles out in release
- [ ] Always prefix logs with `[ClassName]` for traceability
- [ ] No log spam in hot paths (`Update`, `LateUpdate`, `FixedUpdate`)
- [ ] Guard debug visualizations with `#if UNITY_EDITOR || DEVELOPMENT_BUILD`
- [ ] Never use reflection in hot paths on mobile

---

## 21. Scripting — ANR & Crash Safety *(unity_anr_crash_checklist)*

### Crash Prevention
- [ ] Always null-check `GetComponent` / `FindObjectOfType` results before using — uncaught `NullReferenceException` crashes the app
- [ ] Never use destroyed objects in callbacks, coroutines, or events — check `object != null` before access
- [ ] Always check array/list bounds before accessing elements — `IndexOutOfRangeException` crashes on mobile
- [ ] Prevent stack overflow from infinite recursion — `Update` calling functions that call back into themselves, or circular event loops

### ANR Prevention (Main Thread Blocking)
- [ ] Never call synchronous IO on main thread during gameplay: `File.ReadAllText`, `File.WriteAllText`, `PlayerPrefs.Save` — use async or background thread
- [ ] Never use `while (!www.isDone) {}` busy-wait pattern — use `yield return www` or `await`

### Memory Leak & Stability
- [ ] Static collections (`static List`, `static Dictionary`) holding Unity object references must be cleaned on scene unload — destroyed objects stay in static collections causing leaks
- [ ] Always call `Destroy(texture)` on runtime-created `Texture2D` when done — undisposed `Texture2D` leaks GPU memory
- [ ] Avoid `SendMessage()` / `BroadcastMessage()` — use direct references, interfaces, or events (SendMessage uses reflection, is slow, and silently fails)

### Lifecycle & Singleton Safety
- [ ] Singleton pattern must check for duplicate instances on `Awake()` and destroy extras — `DontDestroyOnLoad` without guard creates duplicates on scene reload
- [ ] Avoid `Awake()` depending on initialization order of other objects — use Script Execution Order or lazy initialization pattern
- [ ] `OnDisable` must stop all coroutines and cancel timers — `StopAllCoroutines()` in `OnDisable` if script can be disabled at runtime
- [ ] Save critical data in `OnApplicationPause(true)` instead of only `OnApplicationQuit()` — on mobile, `OnApplicationQuit` may never be called (OS kill)
- [ ] Background threads must use `CancellationToken` and check for cancellation — never use `Thread.Abort()` (causes unpredictable state)
