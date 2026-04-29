---
name: unity-crash-safety
description: "Use when Unity code risks crashes or ANR: null GetComponent results, destroyed-object access after await, DontDestroyOnLoad duplicate singletons, synchronous IO on main thread, static collections leaking Unity objects, or scene transition hazards."
---

# Crash & ANR Safety

## Overview
Prevents the most common crash categories in Unity mobile: null references, lifecycle ordering violations, ANR (Application Not Responding), memory leaks from undisposed objects, and scene transition hazards.

## Severity Reference

| Severity | Examples |
|----------|----------|
| 🔴 CRITICAL | Crash, ANR, GPU memory leak, unhandled thread exception |
| 🟡 HIGH | Memory leak on scene change, data loss on mobile kill |
| 🟢 LOW | Style/convention issue |

---

## §1 — Crash Prevention

- [ ] Always null-check `GetComponent` / `FindObjectOfType` results before using
  - Grep: `grep -rn "GetComponent\|FindObjectOfType" --include="*.cs"`
  - Severity: 🟡 HIGH — verify null check exists on result
- [ ] Never access destroyed objects in callbacks, coroutines, or events — check `object != null`
- [ ] Always check array/list bounds before accessing elements — `IndexOutOfRangeException` crashes on mobile
- [ ] Prevent stack overflow from infinite recursion (Update → function → back to Update, circular events)

---

## §2 — ANR Prevention (Main Thread Blocking)

- [ ] Never call synchronous IO on main thread during gameplay
  - Grep: `grep -rn "File\.ReadAllText\|File\.WriteAllText\|PlayerPrefs\.Save" --include="*.cs"`
  - Severity: 🔴 CRITICAL
- [ ] Never use `while (!www.isDone) {}` busy-wait — use `yield return www` or `await`
  - Grep: `grep -rn "while.*isDone\|while.*!.*isDone" --include="*.cs"`
  - Severity: 🔴 CRITICAL

---

## §3 — Memory Leak & Stability

- [ ] Static collections holding Unity object references must be cleaned on scene unload
  - Grep: `grep -rn "static.*List<\|static.*Dictionary<\|static.*HashSet<" --include="*.cs"`
  - Severity: 🟡 HIGH
- [ ] Always call `Destroy(texture)` on runtime-created `Texture2D` when done
  - Grep: `grep -rn "new Texture2D" --include="*.cs"`
  - Cross-check: verify `Destroy(` for the texture
  - Severity: 🔴 CRITICAL
- [ ] Avoid `SendMessage()` / `BroadcastMessage()` — reflection-based, silently fails
  - Grep: `grep -rn "SendMessage\|BroadcastMessage" --include="*.cs"`
  - Severity: 🟡 HIGH

---

## §4 — Lifecycle & Singleton Safety

- [ ] Singleton `Awake()` must check for duplicate instances and destroy extras
  - Grep: `grep -rn "DontDestroyOnLoad" --include="*.cs"`
  - Cross-check: verify `if (instance != null)` guard exists
  - Severity: 🔴 CRITICAL
- [ ] Singleton cleanup in `OnDestroy`: `if (instance == this) instance = null;`
  - Grep: `grep -rn "static.*instance\|Instance" --include="*.cs"`
  - Cross-check: verify cleanup in OnDestroy
  - Severity: 🟡 HIGH
- [ ] Avoid `Awake()` depending on initialization order of other objects — lazy init or Script Execution Order
- [ ] `OnDisable` must stop all coroutines and cancel timers
- [ ] Save critical data in `OnApplicationPause(true)` — `OnApplicationQuit` may never be called on mobile
  - Grep: `grep -rn "OnApplicationQuit" --include="*.cs"`
  - Cross-check: verify `OnApplicationPause` also saves
  - Severity: 🟡 HIGH
- [ ] Background threads must use `CancellationToken` — never `Thread.Abort()`
  - Grep: `grep -rn "Thread\.Abort\|new Thread" --include="*.cs"`
  - Severity: 🔴 CRITICAL

---

## §5 — Lifecycle Ordering

- [ ] `Awake` only contains self-contained reference caching — no dependency on other objects' state
- [ ] `Start` used for scene-dependent initialization where other objects must be ready
- [ ] No gameplay logic executes before initialization is complete (guard with `IsInit` or equivalent)
- [ ] No `static instance` references persist after scene unload — verify cleanup path
  - Grep: `grep -rn "static.*Instance\|static.*_instance" --include="*.cs"`
  - Severity: 🟡 HIGH

---

## §6 — Null Safety & Guard Patterns

- [ ] `this == null` check after EVERY `await` point in a MonoBehaviour → full pattern & examples see `@unity-async-patterns` §Lifecycle Safety Guards
- [ ] `gameObject.activeInHierarchy` check before `StartCoroutine` after `await`
- [ ] Serialized Inspector fields: no redundant null checks (Fail-Fast — they must be assigned)
- [ ] Remote/optional references: explicit null log with `[ClassName] field is null` for diagnosis
- [ ] Never hide `NullReferenceException` with try-catch swallow — prefer early return with log

---

## §7 — Scene Transition Safety

- [ ] No new MonoBehaviour creation or `Instantiate` in `OnDestroy`
  - Grep: `grep -rn "OnDestroy" --include="*.cs"` then check for Instantiate/AddComponent
  - Severity: 🟡 HIGH
- [ ] Persistent objects (`DontDestroyOnLoad`) properly clean up when scenes change
- [ ] Scene-specific references (UI elements, cameras) re-acquired after scene load
- [ ] Async operations check scene validity after `await` — may have transitioned during wait
- [ ] Loading screen cleanup: `HideLoading` called even if target scene load fails

---

## Verification Rules

### DontDestroyOnLoad guard
- **Grep:** `grep -rn "DontDestroyOnLoad" --include="*.cs"`
- **Verify:**
  1. Has `if (instance != null) { Destroy(gameObject); return; }` guard? → **PASS**
  2. No duplicate guard? → **🔴 CRITICAL**

### Texture2D leak
- **Grep:** `grep -rn "new Texture2D" --include="*.cs"`
- **Verify:**
  1. `Destroy(texture)` called when done in same method? → **PASS**
  2. Texture created AND consumed locally without Destroy? → **🔴 CRITICAL**
  3. Method returns `Sprite` or `Texture2D` (factory pattern)? → verify callers destroy it

### Static collection holding Unity refs
- **Grep:** `grep -rn "static.*List<\|static.*Dictionary<\|static.*HashSet<" --include="*.cs"`
- **Verify:**
  1. Contains Unity objects (GameObject, Component, Texture)? → check cleanup on scene unload
  2. Contains plain data (string, int)? → **PASS**
  3. Unity object refs without cleanup? → **🟡 HIGH**

### this == null after await
- See `@unity-async-patterns` §Lifecycle Safety Guards for grep patterns and verification

---

## Related Skills
- `@unity-async-patterns` — Async lifecycle guards, CancellationToken patterns
- `@unity-event-safety` — Event subscription leaks, resource pairing
- `@unity-dotween-safety` — DOTween lifecycle and memory patterns
- `@unity-addressables` — Addressables memory-safe release
