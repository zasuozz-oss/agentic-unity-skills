---
name: canvas-performance
description: "Unity UI performance optimization for UGUI and UI Toolkit. Use this when the user has slow UI, canvas rebuild issues, overdraw problems, scroll view lag, or UI-related frame drops. Also trigger for: 'UI is lagging', 'canvas rebuilds', 'scroll view stutters', 'too many draw calls from UI', 'raycast target optimization', or any question about making UI faster — even if they don't say 'performance'. Do NOT use for UI layout design — use responsive-ui-design or ui-toolkit-modern instead."
---

# Canvas Performance

## Overview
UI performance optimization for Unity's UGUI and UI Toolkit. Covers canvas splitting, raycast optimization, object pooling for lists, and profiling strategies.

## When to Use
- Use when UI causes frame drops
- Use when scroll views stutter
- Use when Profiler shows Canvas.BuildBatch spikes
- Use when draw calls are high from UI
- Use when mobile UI is slow

## UGUI vs UI Toolkit Performance

| Aspect | UGUI | UI Toolkit |
|--------|:----:|:----------:|
| Canvas Rebuild | Manual split | Auto-optimized |
| Draw Call Batching | Per-canvas | Retained mode |
| Dynamic Lists | ScrollRect + Pool | ListView (built-in) |
| Overdraw Control | Manual | USS opacity |

## Best Practices
- ✅ Split canvases by update frequency (HUD static vs damage numbers dynamic)
- ✅ Disable `raycastTarget` on non-interactive elements (Labels, Images)
- ✅ Use object pooling for scroll view items
- ✅ Cache component references
- ❌ **NEVER** animate UI transforms on a canvas with many static children
- ❌ **NEVER** enable raycastTarget on decorative elements
- ❌ **NEVER** instantiate/destroy list items (pool them)

## Few-Shot Examples

### Example 1: Canvas Split by Update Frequency
**User**: "My HUD causes rebuilds every frame."

**Agent**:
```csharp
// Split into 3 canvases by update frequency:
// Canvas_Static — Background, borders (never changes)
// Canvas_HUD — Health bar, score (changes on events)
// Canvas_Dynamic — Damage numbers, particles (changes every frame)

public class HUDManager : MonoBehaviour
{
    [Header("Static Canvas — never rebuilt")]
    [SerializeField] private Canvas _staticCanvas;

    [Header("HUD Canvas — rebuilt on events only")]
    [SerializeField] private Canvas _hudCanvas;

    [Header("Dynamic Canvas — rebuilt frequently")]
    [SerializeField] private Canvas _dynamicCanvas;

    // Damage numbers go on dynamic canvas to avoid rebuilding HUD
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

### Example 3: UI Toolkit ListView (Virtualized)
**User**: "Efficient scrollable list with 1000 items."

**Agent**:
```csharp
public class InventoryListView : MonoBehaviour
{
    [SerializeField] private UIDocument _uiDocument;
    private ListView _listView;
    private List<ItemData> _items;

    private void OnEnable()
    {
        _listView = _uiDocument.rootVisualElement.Q<ListView>("inventory-list");
        _items = InventoryService.GetAllItems();

        _listView.makeItem = () => new Label(); // Create visual element
        _listView.bindItem = (element, index) =>
        {
            var label = (Label)element;
            label.text = $"{_items[index].Name} x{_items[index].Count}";
        };
        _listView.itemsSource = _items;
        _listView.virtualizationMethod = CollectionVirtualizationMethod.DynamicHeight;
    }
}
```

## Profiling Checklist
- [ ] Check Canvas.BuildBatch in CPU Profiler
- [ ] Check Canvas.SendWillRenderCanvases
- [ ] Count draw calls from UI (Frame Debugger)
- [ ] Verify raycastTarget is off on decorative elements
- [ ] Profile scroll views with 100+ items

## Related Skills
- `@ui-toolkit-modern` - UI Toolkit development
- `@responsive-ui-design` - Layout design
- `@memory-profiler-expert` - UI memory issues
