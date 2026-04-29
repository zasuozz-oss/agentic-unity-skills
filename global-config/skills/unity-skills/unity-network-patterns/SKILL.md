---
name: unity-network-patterns
description: "Use when Unity code calls backend APIs: request gating with _isFetching, pagination PageIndex management, success/failure cooldowns, duplicate item filtering, exponential backoff, or hardcoded test data in production."
---

# Network, Pagination & Data Safety

## Overview
Covers request gating, cooldowns, paginated data integrity, delegation anti-patterns, API response validation, and production data safety for Unity mobile backends.

## Severity Reference

| Severity | Examples |
|----------|----------|
| 🔴 CRITICAL | Hardcoded test data in production, infinite retry loop, main thread blocked by sync request |
| 🟡 HIGH | Duplicate requests, pagination double-increment, silent network failure |

---

## §1 — Backend / Network Performance

- [ ] Use component-level request gating (`_isFetching` flag per component) — not a global blocking flag
- [ ] Set `_isFetching = true` **synchronously** before the async call — prevents race from `Update()` triggers
  - Severity: 🟡 HIGH
- [ ] Add 800ms success cooldown after load completion — prevents rapid consecutive fetches during aggressive scrolling
- [ ] Add 500ms failed request cooldown — prevents infinite retry loop from `Update()` polling
- [ ] Filter duplicate items before notifying UI adapter — skip `NotifyDataChanged()` if no new items (prevents flicker)
- [ ] Implement retry with exponential backoff for server errors (5xx)
- [ ] Use `UniTask` for async API requests instead of coroutines — zero GC, proper error handling
  - Grep: `grep -rn "UnityWebRequest\|WWW\b" --include="*.cs"`
  - Severity: 🟡 HIGH
- [ ] Never block main thread with synchronous web requests
  - Grep: `grep -rn "\.downloadHandler\.text\b" --include="*.cs"` — check if outside async context
  - Severity: 🔴 CRITICAL

> `_isFetching` flag pattern (try-finally reset on all paths) → see `@unity-state-safety` §1 State Flow Analysis.

```csharp
// ✅ Network-specific: gating + cooldowns + duplicate filter
public async UniTaskVoid LoadData(CancellationToken ct)
{
    if (_isFetching) return;
    _isFetching = true;                    // Set synchronously — before any await
    try
    {
        var response = await ApiClient.GetAsync(url, ct);
        if (response?.items == null) return;

        var newItems = response.items.Where(i => !_existingIds.Contains(i.id)).ToList();
        if (newItems.Count == 0) return;   // Skip rebuild — no new data

        _data.AddRange(newItems);
        adapter.NotifyDataChanged();

        await UniTask.Delay(800, cancellationToken: ct); // Success cooldown
    }
    catch (OperationCanceledException) { }
    catch (Exception e) { Debug.LogError($"[LoadData] {e.Message}"); }
    finally { _isFetching = false; }       // Reset on ALL paths
}
```

---

## §2 — Pagination & Data Integrity

- [ ] `PageIndex` incremented in exactly **ONE place** — centralized in base class
- [ ] No double-increment: child classes must NOT manually increment after base class does
- [ ] `hasMorePage` guard allows refresh: `if (!hasMorePage && !isRefresh)` — refresh always proceeds
- [ ] Duplicate data prevention: `IsSameItem` override correctly compares unique IDs
- [ ] Empty data result does NOT block future pagination — PageIndex still advances
- [ ] Local data list count matches OSA/UI adapter count — no "invisible items" bug
- [ ] `ValidatePageIndexAfterDelete()` called only on user-initiated deletion, NOT in automated load flow

---

## §3 — Delegation & Method Interaction

> Full delegation rules → see `@unity-state-safety` §4 Delegation & Method Interaction

- [ ] No "Early Gatekeeper Bug" in pagination: caller must NOT set `_isFetchingData = true` before calling `LoadNewPage()` — LoadNewPage already does it

---

## §4 — Data Validation & Edge Cases

- [ ] API response validated before use — null/empty checks on critical fields
  - Grep: `grep -rn "response\.\|data\." --include="*.cs"` — check null guard before property access
- [ ] Collection operations check bounds — no `IndexOutOfRange` from empty lists
- [ ] Division by zero guards on dynamic values: `PageSize > 0 ? PageSize : DefaultSize`
- [ ] Enum switch statements have `default` case — handle unexpected values
  - Grep: `grep -rn "switch\b" --include="*.cs"`
  - Cross-check: verify `default:` case exists
- [ ] Date/time comparisons account for timezone and format differences
- [ ] String comparisons use `StringComparison.Ordinal` or `OrdinalIgnoreCase` — no culture-dependent bugs

---

## §5 — Production Data Safety

- [ ] No hardcoded test IDs, test URLs, or debug overrides in production code paths
  - Grep: `grep -rn "test\|debug\|hardcode\|TODO\|HACK\|FIXME" --include="*.cs"`
  - Note: high noise — view_file to distinguish real test data from variable names
  - Severity: 🔴 CRITICAL
- [ ] Feature flags and test overrides behind `#if DEVELOPMENT_BUILD` or server-side config
  - Grep: `grep -rn "#if" --include="*.cs" | grep -v "UNITY_EDITOR\|DEVELOPMENT_BUILD"`
  - Cross-check: verify conditionals guard test-only behavior

---

## Related Skills
- `@unity-state-safety` — State flag safety, race condition prevention
- `@unity-async-patterns` — UniTask, CancellationToken, async lifecycle
- `@unity-crash-safety` — Null safety, data validation, scene safety
- `@unity-event-safety` — Error path cleanup, try-finally patterns
