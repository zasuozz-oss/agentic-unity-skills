---
name: unity-state-safety
description: "Use when Unity code has boolean flags (_isLoading, _isFetching) that risk getting stuck, async race conditions, double-submit prevention, try-finally flag reset, or state transitions with multiple exit paths."
---

# State Safety & Race Condition Prevention

## Overview
Prevents stuck flags, race conditions, and silent failures in Unity C# code. Enforces that boolean state flags are always reset on all exit paths, async requests are properly gated, and errors never leave the UI in a broken state.

## Severity Reference

| Severity | Examples |
|----------|----------|
| 🔴 CRITICAL | Flag permanently stuck true → feature broken until app restart |
| 🟡 HIGH | Race condition → data corruption, duplicate requests, wrong UI state |

---

## §1 — State Flow Analysis

- [ ] Enumerate all state variable combinations — identify impossible/untested states
- [ ] Boolean flags (`_isLoading`, `_isFetching`, `_isInit`) reset in ALL exit paths (success, failure, cancellation)
  - Grep: `grep -rn "_isLoading\|_isFetching\|_isInit\|_isProcessing" --include="*.cs"`
  - Note: requires view_file to verify all paths
  - Severity: 🔴 CRITICAL
- [ ] Every early return (guard clause) handles required cleanup and flag resets
- [ ] No "flag stuck" scenario: every path that sets `true` has a path that sets `false`
- [ ] State transitions are atomic — no partial state updates visible to other components
- [ ] `forceRefresh` parameters bypass "Already Active" guards but respect cooldowns

```csharp
// ❌ BAD: flag stuck if exception thrown
_isFetching = true;
var data = await LoadData(ct);
_isFetching = false; // Never reached on exception!

// ✅ GOOD: finally resets flag on ALL paths
_isFetching = true;
try
{
    var data = await LoadData(ct);
    ProcessData(data);
}
catch (OperationCanceledException) { }
catch (Exception e) { Debug.LogError($"Failed: {e.Message}"); }
finally
{
    _isFetching = false; // GUARANTEED on all paths
}
```

---

## §2 — Race Condition Prevention

- [ ] `CancellationTokenSource` cancelled before creating new one — full pattern → see `@unity-async-patterns` §CTS Management
  - Grep: `grep -rn "new CancellationTokenSource" --include="*.cs"`
  - Cross-check: verify previous CTS is cancelled
  - Severity: 🟡 HIGH
- [ ] Identity/Recycle check after `await` for pooled/recycled objects — full pattern → see `@unity-async-patterns` §Hybrid Safety
- [ ] No instance fields used to store async results — use local variables in async scope
- [ ] Duplicate request guard: `if (_isFetchingData) return;` before any API call
- [ ] Same-page cooldown: prevent rapid identical requests (page reload spam)
- [ ] `CancellationToken` passed to `ToUniTask()` — stale results don't apply to wrong context

---

## §3 — Error Handling Completeness

- [ ] `try-catch` blocks include `finally` for cleanup (HideLoading, flag reset)
  - Grep: `grep -rn "try\b" --include="*.cs"`
  - Cross-check: verify `finally` block exists
- [ ] Error handling never swallows exceptions silently — at minimum log the error
  - Grep: `grep -rn "catch.*{" --include="*.cs"`
  - Cross-check: verify catch block has Log or rethrow
  - Severity: 🟡 HIGH
- [ ] Network error classification: distinguish Retryable (429, timeout) vs Fatal (403, 404)
- [ ] Exponential backoff for retryable errors — not immediate retry loops
- [ ] Failed API calls reset UI state (loading spinners, disabled buttons)
- [ ] User-facing error feedback: silent failures are bugs (show toast/retry button)

---

## §4 — Delegation & Method Interaction

- [ ] Flag management delegated to the "leaf" method — callers don't pre-set flags
- [ ] No "Early Gatekeeper Bug": a method that calls another should NOT set `_isFetchingData = true` before calling it, as the callee also sets it, causing a permanent lock-out
- [ ] Callback methods (`OnRequestDone`, `OnComplete`) check object validity before applying state
- [ ] No hidden side effects from calling order between parent/child methods
- [ ] `OnComplete`/`OnKill` callbacks for DOTween don't rely on critical state — tween can be killed early

---

## Verification Rules

### Boolean flag stuck
- **Grep:** `grep -rn "_isLoading\|_isFetching\|_isInit\|_isProcessing" --include="*.cs"`
- **Verify:**
  1. Flag set to `true` — check ALL paths (success, failure, cancellation) eventually set `false`
  2. Flag reset in `finally` block? → **PASS**
  3. Flag in try block without finally reset? → **🔴 CRITICAL**
  4. `async void` method sets flag without try-finally? → **🔴 CRITICAL**

### Silent exception swallow
- **Grep:** `grep -rn "catch\s*(" --include="*.cs"`
- **Verify:**
  1. Catch block has `Debug.LogError` or `throw`? → **PASS**
  2. Empty catch `catch { }` or catch with only comment? → **🟡 HIGH**
  3. Catch swallows exception AND leaves UI in loading state? → **🔴 CRITICAL**

### CancellationTokenSource race
- **Grep:** `grep -rn "new CancellationTokenSource" --include="*.cs"`
- **Verify:**
  1. Previous CTS cancelled + disposed before new? → **PASS**
  2. Only `_cts = new CancellationTokenSource()` without prior Cancel/Dispose? → **🔴 CRITICAL**

---

## Related Skills
- `@unity-event-safety` — ShowLoading/HideLoading pairing, event leaks
- `@unity-async-patterns` — CancellationToken patterns, async lifecycle
- `@unity-crash-safety` — Null safety, lifecycle ordering
- `@unity-network-patterns` — Request gating, pagination, API error handling
