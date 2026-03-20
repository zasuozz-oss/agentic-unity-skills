---
name: unity-ui-performance
description: "MANDATORY for ALL UI work. Activate EVERY TIME you create, modify, generate, refactor, or review ANY Unity UI code — no exceptions. Covers rendering performance (canvas rebuild, overdraw, raycast, batching), state safety (flicker, race conditions, resource pairing), AND responsive design (safe area, multi-device, Canvas Scaler). Trigger keywords: 'UI lag', 'canvas rebuild', 'raycast target', 'UI flicker', 'animation fighting', 'tab spam', 'panel stuck', 'scroll stutter', 'draw calls', 'loading spinner stuck', 'UI state', 'safe area', 'notch', 'responsive', 'screen size', 'aspect ratio', 'Canvas Scaler', 'multi-device'. If you are about to write UI code and have NOT loaded this skill, STOP and load it first."
---

# UI Optimization

## Overview
Comprehensive UI optimization covering **rendering performance** (canvas splits, draw calls, raycast targets), **state safety** (animation race conditions, resource pairing, flicker prevention), and **responsive design** (safe area, multi-device, Canvas Scaler).

## When to Use
- Use when UI causes frame drops or stutters
- Use when Profiler shows Canvas.BuildBatch spikes
- Use when draw calls are high from UI
- Use when UI gets stuck in wrong state after rapid interaction
- Use when animations fight (flickering, snapping)
- Use when loading spinners never disappear
- Use when tab/panel transitions overlap or break
- Use for multi-platform / multi-device UI adaptation
- Use for safe area handling (notches)

## Performance Best Practices
- ✅ Split canvases by update frequency (static HUD vs dynamic damage numbers)
- ✅ Disable `raycastTarget` on non-interactive elements (Labels, Images)
- ✅ Use object pooling for scroll view items — never instantiate/destroy
- ✅ Cache component references in `Awake()`
- ❌ **NEVER** animate UI transforms on a canvas with many static children
- ❌ **NEVER** enable raycastTarget on decorative elements

## State Safety Principles
- ✅ **Resource Pairing**: Every `ShowLoading()` must have `HideLoading()` on ALL exit paths (use `finally`)
- ✅ **Last-One-Wins**: New animation requests cancel previous ones
- ✅ **Immediate State**: Critical state changes happen immediately, not in OnComplete callbacks
- ✅ **Kill Before Reset**: `DOTween.Kill(target)` before manual property changes
- ❌ **NEVER** rely on `OnComplete` for critical state (tween can be killed)
- ❌ **NEVER** trigger full UI rebuild for empty data updates

## Responsive Design Rules
- ✅ Use percentage and flex units — never hardcode pixel positions
- ✅ Handle `Screen.safeArea` for notches on mobile
- ✅ Test on multiple resolutions and aspect ratios
- ✅ Use min/max constraints for layout stability
- ❌ **NEVER** assume fixed aspect ratio
- ❌ **NEVER** ignore safe areas on mobile

## Few-Shot Examples

### Example 1: Canvas Split by Update Frequency
**User**: "My HUD causes rebuilds every frame."

**Agent**:
```csharp
public class HUDManager : MonoBehaviour
{
    [Header("Static Canvas — never rebuilt")]
    [SerializeField] private Canvas _staticCanvas;

    [Header("HUD Canvas — rebuilt on events only")]
    [SerializeField] private Canvas _hudCanvas;

    [Header("Dynamic Canvas — rebuilt frequently")]
    [SerializeField] private Canvas _dynamicCanvas;

    public void ShowDamageNumber(float damage, Vector3 worldPos)
    {
        var dmgText = _damagePool.Get();
        dmgText.transform.SetParent(_dynamicCanvas.transform, false);
        dmgText.Setup(damage, worldPos);
    }
}
```

### Example 2: Raycast Target Optimizer
**User**: "Bulk-disable raycastTarget on non-interactive elements."

**Agent**:
```csharp
#if UNITY_EDITOR
public class RaycastTargetOptimizer : MonoBehaviour
{
    [ContextMenu("Optimize Raycast Targets")]
    private void OptimizeRaycastTargets()
    {
        int optimized = 0;
        var graphics = GetComponentsInChildren<Graphic>(true);

        foreach (var graphic in graphics)
        {
            bool isInteractive = graphic.GetComponent<Selectable>() != null
                || graphic.GetComponent<IPointerClickHandler>() != null
                || graphic.GetComponent<IDragHandler>() != null;

            if (!isInteractive && graphic.raycastTarget)
            {
                graphic.raycastTarget = false;
                optimized++;
                EditorUtility.SetDirty(graphic);
            }
        }

        Debug.Log($"Disabled raycastTarget on {optimized} non-interactive elements");
    }
}
#endif
```

### Example 3: Resource Pairing (Loading Indicator)
**User**: "Loading spinner never disappears when API fails."

**Agent**:
```csharp
// ❌ BEFORE: HideLoading only on success path
public async UniTask Init()
{
    loadingElement.ShowLoading();
    var data = await LoadData();
    loadingElement.HideLoading();  // Never reached if exception!
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
    catch (OperationCanceledException) { }
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

### Example 4: Tab Switching Spam Protection
**User**: "Rapid tab clicks cause animations to fight."

**Agent**:
```csharp
// ❌ BEFORE: Each click starts new animation without cancelling
public void OnTabClick(int tabIndex)
{
    _slider.DOAnchorPos(tabPositions[tabIndex], 0.2f);
}

// ✅ AFTER: Cancel previous + kill fighting tweens
private Tween _sliderTween;
private CancellationTokenSource _tabCts;

public async UniTaskVoid OnTabClick(int tabIndex)
{
    _tabCts?.Cancel();
    _tabCts?.Dispose();
    _tabCts = new CancellationTokenSource();

    _sliderTween?.Kill();
    SetButtonsInteractable(false);

    _sliderTween = _slider.DOAnchorPos(tabPositions[tabIndex], 0.2f)
        .SetLink(_slider.gameObject);

    try
    {
        await _sliderTween.ToUniTask(cancellationToken: _tabCts.Token);
        SetButtonsInteractable(true);
        OpenPanel(tabIndex);
    }
    catch (OperationCanceledException) { }
}
```

### Example 5: Immediate State vs OnComplete
**User**: "Panel sometimes stays visible after navigation."

**Agent**:
```csharp
// ❌ BEFORE: State change in OnComplete — unreliable if tween killed
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
    _panel.DOScale(0, 0.3f)
        .SetLink(_panel);
}
```

### Example 6: Safe Area Handler (Notch)
**User**: "Handle notch on mobile."

**Agent**:
```csharp
public class CanvasSafeArea : MonoBehaviour
{
    [SerializeField] private RectTransform _safeAreaRect;
    private Rect _lastSafeArea;

    private void Update()
    {
        if (Screen.safeArea != _lastSafeArea)
        {
            ApplySafeArea();
            _lastSafeArea = Screen.safeArea;
        }
    }

    private void ApplySafeArea()
    {
        var safeArea = Screen.safeArea;
        var anchorMin = safeArea.position;
        var anchorMax = safeArea.position + safeArea.size;

        anchorMin.x /= Screen.width;
        anchorMin.y /= Screen.height;
        anchorMax.x /= Screen.width;
        anchorMax.y /= Screen.height;

        _safeAreaRect.anchorMin = anchorMin;
        _safeAreaRect.anchorMax = anchorMax;
    }
}
```

## Profiling Checklist
- [ ] Check Canvas.BuildBatch in CPU Profiler
- [ ] Check Canvas.SendWillRenderCanvases
- [ ] Count draw calls from UI (Frame Debugger)
- [ ] Verify raycastTarget off on decorative elements
- [ ] Profile scroll views with 100+ items

## State Safety Review
- [ ] Every `ShowLoading()` has `HideLoading()` in `finally`
- [ ] Every `SetInteractable(false)` has `SetInteractable(true)` on all paths
- [ ] All tween targets get `DOKill()` before manual property reset
- [ ] OnComplete contains only non-critical visual polish
- [ ] Rapid-fire interactions have cancellation logic

## Platform Considerations

| Platform | Focus |
|----------|-------|
| **Mobile** | Touch, safe area, portrait/landscape |
| **Tablet** | Both orientations, larger touch targets |
| **Desktop** | Mouse hover, keyboard navigation |
| **Console** | Gamepad focus, overscan |

## Related Skills
- `@unity-dotween-safety` - DOTween lifecycle and memory patterns
- `@unity-async-patterns` - Async/await lifecycle and cancellation
- `@unity-addressables` - Asset management and memory-safe release
