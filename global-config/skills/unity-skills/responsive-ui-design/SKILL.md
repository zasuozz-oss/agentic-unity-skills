---
name: responsive-ui-design
description: "Responsive UI design for multi-device support. Use this for Canvas Scaler configuration, anchor-based layouts, safe area handling, screen size adaptation, UGUI responsive patterns, or UI Toolkit flexbox layouts. Also trigger for: 'UI doesn't fit on mobile', 'notch safe area', 'aspect ratio issues', 'UI scaling problems', 'different screen sizes', or any question about making UI work across devices — even if they don't say 'responsive'."
---

# Responsive UI Design

## Overview
Responsive and adaptive UI design for Unity. Build interfaces that work across mobile, tablet, desktop, and console using both UGUI anchors and UI Toolkit flexbox.

## When to Use
- Use for multi-platform games
- Use for mobile/tablet adaptation
- Use for safe area handling (notches)
- Use for aspect ratio independence
- Use for accessibility scaling

## Responsive Strategies

| Strategy | Description |
|----------|-------------|
| **Fluid** | Percentage-based sizing |
| **Adaptive** | Breakpoint-based layouts |
| **Flexible** | Flexbox grow/shrink |
| **Scalable** | DPI-aware sizing |

## Best Practices
- ✅ Use percentage and flex units
- ✅ Handle Screen.safeArea for notches
- ✅ Test on multiple resolutions
- ✅ Use min/max constraints
- ✅ Scale fonts with screen density
- ❌ **NEVER** hardcode pixel positions
- ❌ **NEVER** assume fixed aspect ratio
- ❌ **NEVER** ignore safe areas on mobile

## Few-Shot Examples

### Example 1: Safe Area Handler
**User**: "Handle notch on mobile."

**Agent**:
```csharp
public class SafeAreaHandler : MonoBehaviour
{
    [SerializeField] private UIDocument _uiDocument;

    private void OnEnable()
    {
        ApplySafeArea();
    }

    private void ApplySafeArea()
    {
        var root = _uiDocument.rootVisualElement;
        var safeArea = Screen.safeArea;
        var screen = new Vector2(Screen.width, Screen.height);

        // Convert to percentages
        float left = safeArea.x / screen.x * 100f;
        float right = (screen.x - safeArea.xMax) / screen.x * 100f;
        float top = (screen.y - safeArea.yMax) / screen.y * 100f;
        float bottom = safeArea.y / screen.y * 100f;

        var content = root.Q("safe-content");
        content.style.marginLeft = new Length(left, LengthUnit.Percent);
        content.style.marginRight = new Length(right, LengthUnit.Percent);
        content.style.marginTop = new Length(top, LengthUnit.Percent);
        content.style.marginBottom = new Length(bottom, LengthUnit.Percent);
    }
}
```

### Example 2: UGUI Safe Area with RectTransform
**User**: "Safe area for Canvas-based UI."

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

### Example 3: Breakpoint Controller
**User**: "Switch layouts based on screen size."

**Agent**:
```csharp
public class ResponsiveController : MonoBehaviour
{
    [SerializeField] private UIDocument _uiDocument;

    private VisualElement _root;
    private float _lastWidth;

    private void OnEnable()
    {
        _root = _uiDocument.rootVisualElement;
        UpdateBreakpoint();
    }

    private void Update()
    {
        if (Mathf.Abs(Screen.width - _lastWidth) > 1f)
        {
            UpdateBreakpoint();
            _lastWidth = Screen.width;
        }
    }

    private void UpdateBreakpoint()
    {
        _root.RemoveFromClassList("mobile");
        _root.RemoveFromClassList("tablet");
        _root.RemoveFromClassList("desktop");

        float width = Screen.width;
        if (width < 600)
            _root.AddToClassList("mobile");
        else if (width < 1024)
            _root.AddToClassList("tablet");
        else
            _root.AddToClassList("desktop");
    }
}
```

## Platform Considerations

| Platform | Focus |
|----------|-------|
| **Mobile** | Touch, safe area, portrait/landscape |
| **Tablet** | Both orientations, larger touch targets |
| **Desktop** | Mouse hover, keyboard navigation |
| **Console** | Gamepad focus, overscan |

## Related Skills
- `@canvas-performance` - UI performance optimization
- `@menu-navigation-flow` - Multi-screen navigation
- `@canvas-performance` - Performance optimization
