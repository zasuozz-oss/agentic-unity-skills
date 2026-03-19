---
name: ui-state-safety
description: "Unity UI state consistency and animation safety specialist. Use this when the user has UI flickering, animation fighting, tab switching bugs, stale UI states, or race conditions in panel transitions. Also trigger for: 'UI flickers', 'animation fighting', 'tab spam breaks UI', 'panel stuck in loading', 'tween overrides my reset', 'OnComplete never fires', 'button stays disabled', or any question about UI state reliability — even if they don't say 'state safety'. Do NOT use for UI layout or rendering — use responsive-ui-design or canvas-performance instead."
---

# UI State Safety

## Overview
Patterns to prevent UI state corruption, animation race conditions, and visual glitches caused by user interaction timing (rapid tab switching, overlapping async operations, cancelled animations).

## When to Use
- Use when UI gets stuck in wrong state after rapid interaction
- Use when animations fight (flickering, snapping)
- Use when loading spinners never disappear
- Use when tab switching causes visual bugs
- Use when panel transitions overlap

## Core Principles
- ✅ **Resource Pairing**: Every `ShowLoading()` must have a `HideLoading()` on ALL exit paths
- ✅ **Last-One-Wins**: New animation requests cancel previous ones
- ✅ **Immediate State**: Critical state changes happen immediately, not in callbacks
- ✅ **Kill Before Reset**: `DOTween.Kill(target)` before manual property changes
- ❌ **NEVER** rely on `OnComplete` for critical state (tween can be killed)
- ❌ **NEVER** reset guard flags without cooldown in failure paths
- ❌ **NEVER** trigger full UI rebuild for empty data updates

## Few-Shot Examples

### Example 1: Resource Pairing (Loading Indicator)
**User**: "Loading spinner never disappears when API fails."

**Agent**:
```csharp
// ❌ BEFORE: HideLoading only on success path
public async UniTask Init()
{
    loadingElement.ShowLoading();
    try
    {
        var data = await LoadData();
        loadingElement.HideLoading();  // Never reached if exception!
    }
    catch (Exception e)
    {
        Debug.LogError(e);
        // BUG: Loading spinner stuck forever
    }
}

// ✅ AFTER: finally guarantees cleanup on ALL paths
public async UniTask Init(CancellationToken ct)
{
    loadingElement.ShowLoading();
    try
    {
        var data = await LoadData().AttachExternalCancellation(ct);
        ProcessData(data);
    }
    catch (OperationCanceledException)
    {
        // Silent — task was cancelled by design
    }
    catch (Exception e)
    {
        Debug.LogError($"[Init] Failed: {e.Message}");
    }
    finally
    {
        loadingElement.HideLoading();  // GUARANTEED on all paths
    }
}
```

### Example 2: Tab Switching Spam Protection
**User**: "Rapid tab clicks cause animations to fight."

**Agent**:
```csharp
// ❌ BEFORE: Each click starts new animation without cancelling previous
public void OnTabClick(int tabIndex)
{
    _slider.DOAnchorPos(tabPositions[tabIndex], 0.2f);
    _tabs[tabIndex].DOColor(highlightColor, 0.2f);
}

// ✅ AFTER: Cancel previous + kill fighting tweens
private Tween _sliderTween;
private CancellationTokenSource _tabCts;

public async UniTaskVoid OnTabClick(int tabIndex)
{
    // 1. Cancel previous async logic
    _tabCts?.Cancel();
    _tabCts?.Dispose();
    _tabCts = new CancellationTokenSource();

    // 2. Kill fighting tweens
    _sliderTween?.Kill();

    // 3. Disable buttons during transition
    SetButtonsInteractable(false);

    // 4. Start new animation
    _sliderTween = _slider.DOAnchorPos(tabPositions[tabIndex], 0.2f);

    try
    {
        await _tabs[tabIndex].DOColor(highlightColor, 0.2f)
            .WithCancellation(_tabCts.Token);

        // Only runs if NOT cancelled by newer click
        SetButtonsInteractable(true);
        OpenPanel(tabIndex);
    }
    catch (OperationCanceledException)
    {
        // Replaced by newer click — do nothing
    }
}
```

### Example 3: Immediate State vs OnComplete
**User**: "Panel sometimes stays visible after navigation."

**Agent**:
```csharp
// ❌ BEFORE: State change in callback — unreliable if tween killed
void ClosePanel()
{
    _panel.DOScale(0, 0.3f).OnComplete(() =>
    {
        _panel.SetActive(false);  // Never runs if tween killed!
    });
}

// ✅ AFTER: Immediate state change + animation is cosmetic only
void ClosePanel()
{
    _panel.SetActive(false);       // IMMEDIATE — always executes
    _panel.DOScale(0, 0.3f);      // Cosmetic — OK if killed
}
```

### Example 4: Incremental Update (Flicker Prevention)
**User**: "List items re-animate when loading next page."

**Agent**:
```csharp
// ❌ BEFORE: Always notify UI even with no new items
public async UniTask LoadNextPage()
{
    var rawData = await FetchPage(nextIndex);
    _items.AddRange(rawData);
    _adapter.NotifyDataChanged();  // Re-triggers all animations!
}

// ✅ AFTER: Filter duplicates, skip if nothing new
public async UniTask LoadNextPage()
{
    var rawData = await FetchPage(nextIndex);

    var newItems = rawData
        .Where(item => !_items.Any(x => x.id == item.id))
        .ToList();

    if (newItems.Count == 0) return;  // No flicker

    _items.AddRange(newItems);
    _adapter.NotifyItemsAdded(newItems.Count);  // Only new items
}
```

## Review Checklist

### Resource Pairing Audit
For every method, verify:
- [ ] Every `ShowLoading()` has `HideLoading()` in `finally`
- [ ] Every `SetInteractable(false)` has `SetInteractable(true)` on all paths
- [ ] Every `isFetching = true` has `isFetching = false` on all paths (including early returns)

### Terminal Path Enumeration
- [ ] List all `return` statements in async methods
- [ ] Verify each early return cleans up UI state
- [ ] Check `catch` blocks for missing cleanup

### Animation Safety
- [ ] All tween targets get `DOTween.Kill(target)` before manual property reset
- [ ] OnComplete callbacks contain only non-critical visual polish
- [ ] Rapid-fire UI interactions (tabs, buttons) have cancellation logic

## Related Skills
- `@dotween-safety` - DOTween lifecycle and memory patterns
- `@canvas-performance` - Canvas rendering optimization
- `@asynchronous-programming` - Async lifecycle guards
