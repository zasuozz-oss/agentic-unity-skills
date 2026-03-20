---
name: unity-logic-audit
description: "CODE LOGIC correctness audit checklist. Activate when systematically verifying Unity C# script LOGIC — state management, race conditions, null safety, resource pairing, async lifecycle guards, event symmetry, error handling, pagination flow, and data integrity. NOT for performance (use unity-script-audit) or coding style (use unity-csharp-standards). Trigger keywords: 'logic audit', 'verify logic', 'state bug', 'race condition', 'null reference', 'resource leak', 'event not unsubscribed', 'loading stuck', 'data corruption', 'flag stuck', 'logic review', 'correctness check'."
---

# Unity Logic Audit Checklist

Verify correctness of game logic, state management, and data flow. This checklist focuses on **logic bugs** — not performance or style.

> **Scope distinction:**
> - `unity-logic-audit` = Logic correctness (state, race conditions, null safety, data flow)
> - `unity-script-audit` = Performance audit (GC, caching, hot paths, frame budget)
> - `unity-csharp-standards` = Real-time coding guidance (naming, design, conventions)

---

## 1. Lifecycle Ordering & Initialization

- [ ] `Awake` only contains self-contained reference caching — no dependency on other objects' state
- [ ] `Start` used for scene-dependent initialization where other objects must be ready
- [ ] No gameplay logic executes before initialization is complete (guard with `IsInit` or equivalent flag)
- [ ] Singleton cleanup in `OnDestroy`: `if (instance == this) instance = null;`
- [ ] No `static instance` references persist after scene unload — verify cleanup path

---

## 2. Event Subscription Symmetry

- [ ] Every `OnEnable` subscribe has a matching `OnDisable` unsubscribe
- [ ] Every `AddListener` has a matching `RemoveListener` in the symmetric lifecycle method
- [ ] No event subscriptions in `Awake`/`Start` without corresponding unsubscription in `OnDisable`/`OnDestroy`
- [ ] Static event subscriptions are especially dangerous — verify they always unsubscribe
- [ ] Delegate chains (`+=`) never accumulate duplicates across re-enable cycles

---

## 3. Resource Pairing Principle

Every "acquire" operation MUST have a matching "release" in ALL terminal paths.

- [ ] `ShowLoading()` ↔ `HideLoading()` — verified in success, failure, cancellation, and early return paths
- [ ] `Subscribe` ↔ `Unsubscribe` — symmetric in enable/disable
- [ ] `DOTween.Play()` ↔ `Kill()` — linked or explicitly killed
- [ ] `CancellationTokenSource` created ↔ `Cancel()` + `Dispose()` called
- [ ] File/Stream `Open` ↔ `Close` — wrapped in `using` or `finally`
- [ ] Loading spinners never stuck — check every `return` statement in async methods for `HideLoading()` call

---

## 4. Null Safety & Guard Patterns

- [ ] `this == null` check after EVERY `await` point in a MonoBehaviour
- [ ] `gameObject.activeInHierarchy` check before `StartCoroutine` after `await`
- [ ] Serialized Inspector fields: no redundant null checks (Fail-Fast principle) unless explicitly optional
- [ ] Remote data fields: explicit null logging with `[ClassName] field is null` for diagnosis
- [ ] Optional references: explicit fallback behavior provided (not silent null)
- [ ] No `NullReferenceException` hiding — prefer early return with log over try-catch swallow

---

## 5. State Flow Analysis

- [ ] Enumerate all state variable combinations — identify impossible/untested states
- [ ] Every early return (guard clause) handles required cleanup and flag resets
- [ ] Boolean flags (`_isLoading`, `_isFetching`, `_isInit`) are reset in ALL exit paths (success, failure, cancellation)
- [ ] No "flag stuck" scenarios: verify every path that sets `true` also has a path that sets `false`
- [ ] State transitions are atomic — no partial state updates visible to other components
- [ ] `forceRefresh` parameters bypass "Already Active" guards but respect cooldowns

---

## 6. Race Condition Prevention

- [ ] CancellationTokenSource cancelled before creating new one (`_cts?.Cancel(); _cts?.Dispose();`)
- [ ] Identity/Recycle check after `await` for pooled/recycled objects: `if (this.data != capturedData) return;`
- [ ] No instance fields used to store async results — use local variables in async scope
- [ ] Duplicate request guards: `if (_isFetchingData) return;` before any API call
- [ ] Same-page cooldown: prevent rapid identical requests (e.g., page reload spam)
- [ ] CancellationToken passed to `ToUniTask()` — stale tween results don't apply to wrong context

---

## 7. Async/Await Lifecycle Safety

- [ ] No `async void` except Unity event handlers — use `async UniTask` with proper error handling
- [ ] `CancellationToken` propagated through entire async call chain
- [ ] Cancelled operations handle `OperationCanceledException` gracefully (not re-thrown as errors)
- [ ] Async methods in `OnDestroy` context: no new operations after destruction begins
- [ ] `UniTask.Delay` checks cancellation token after resuming
- [ ] Hybrid Safety Pattern used for recycled objects: CTS + identity validation + null check

---

## 8. Error Handling Completeness

- [ ] `try-catch` blocks include `finally` for cleanup (especially `HideLoading`, flag reset)
- [ ] Error handling never swallows exceptions silently — at minimum log the error
- [ ] Network error classification: distinguish Retryable (429, timeout) vs Fatal (403, 404)
- [ ] Exponential backoff for retryable errors — not immediate retry loops
- [ ] Failed API calls reset UI state (loading spinners, disabled buttons)
- [ ] User-facing error feedback: silent failures are bugs (show toast/retry button)

---

## 9. Pagination & Data Integrity

- [ ] `PageIndex` incremented in exactly ONE place — centralized in base class
- [ ] No double-increment bugs: child classes do NOT manually increment after base class does
- [ ] `hasMorePage` guard allows refresh: `if (!hasMorePage && !isRefresh)` — refresh always proceeds
- [ ] Duplicate data prevention: `IsSameItem` override correctly compares unique IDs
- [ ] Empty data result does NOT block future pagination — PageIndex still advances
- [ ] Local data list count matches OSA/UI data count — no "invisible items" bug
- [ ] `ValidatePageIndexAfterDelete()` only called on user deletion, NOT in automated load flow

---

## 10. Delegation & Method Interaction

- [ ] Flag management delegated to the "leaf" method — callers don't pre-set flags
- [ ] No "Early Gatekeeper Bug": `RefreshPageWithSign` should NOT set `_isFetchingData = true` before calling `LoadNewPage()`
- [ ] Callback methods (`OnRequestDone`, `OnComplete`) check object validity before applying state
- [ ] Parent-child method interaction: no hidden side effects from calling order
- [ ] `OnComplete`/`OnKill` callbacks for DOTween don't rely on critical state changes — tween can be killed early

---

## 11. Scene Transition Safety

- [ ] No new MonoBehaviour creation or `Instantiate` in `OnDestroy`
- [ ] Persistent objects (`DontDestroyOnLoad`) properly clean up when scenes change
- [ ] Scene-specific references (UI elements, cameras) are re-acquired after scene load
- [ ] Async operations check scene validity after `await` — may have transitioned during wait
- [ ] Loading screen cleanup: verify `HideLoading` called even if target scene load fails

---

## 12. Data Validation & Edge Cases

- [ ] API response data validated before use — null/empty checks on critical fields
- [ ] Collection operations check bounds: no `IndexOutOfRange` from empty lists
- [ ] Division by zero guards on dynamic values (e.g., `PageSize > 0 ? PageSize : DefaultSize`)
- [ ] Enum switch statements have `default` case — handle unexpected values
- [ ] Date/time comparisons account for timezone and format differences
- [ ] String comparisons use `StringComparison.Ordinal` or `OrdinalIgnoreCase` — no culture-dependent bugs

---

## Output Format

For each checklist item, report:
- `[x]` Passed — no issues found
- `[!]` Violation — with file path, line number, and description
- `[~]` Not applicable — with brief reason

Group violations by severity:
1. **🔴 Critical** — Will cause crashes, data loss, or stuck states
2. **🟡 High** — Race conditions or logic errors under specific conditions
3. **🟢 Low** — Edge cases or minor improvements

---

## Related Skills
- `@unity-script-audit` — Performance-focused audit (GC, caching, hot-path)
- `@unity-csharp-standards` — Coding conventions and design review
- `@unity-async-patterns` — Deep async/await patterns and lifecycle safety
- `@unity-dotween-safety` — DOTween-specific lifecycle and memory patterns
