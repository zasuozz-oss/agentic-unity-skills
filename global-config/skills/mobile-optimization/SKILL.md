---
name: mobile-optimization
description: "Unity mobile development and optimization specialist for Android/iOS. Use this when the user targets mobile platforms, needs framerate fixes, battery optimization, thermal throttling solutions, build size reduction, mobile coding conventions, touch input, or mobile-specific patterns."
---

# Mobile Optimization & Conventions

## Overview
Mobile-specific performance optimization and coding conventions for Android/iOS. Covers framerate targeting, resolution scaling, thermal throttling, battery efficiency, and mobile-first coding rules.

## When to Use
- Use for Android/iOS builds
- Use when battery drain is high
- Use when device overheats
- Use for adaptive quality
- Use for low-end device support
- Use for mobile coding patterns and conventions
- Use for touch input handling

---

## Mobile Coding Rules

### Performance Rules
- No LINQ in Update or loops
- No allocations in Update/LateUpdate
- No GameObject.Find/FindObjectOfType at runtime
- Cache references in Awake
- Use object pooling for frequently spawned objects

### Lifecycle Rules
- Awake: cache references only (GetComponent, transform)
- Start: scene-dependent init
- FixedUpdate: physics only
- OnEnable/OnDisable: register/unregister events
- Awake MUST NOT be used for gameplay logic, state init, event registration, or data loading

### Animation Rules
- No hardcoded animator parameter names — use Animator.StringToHash
- DOTween is the default tweening solution
- Kill tweens on disable/destroy
- Prefer DOTween over Animator for simple UI

### UI Rules
- All UI text MUST use TextMeshProUGUI (not UnityEngine.UI.Text)
- Button callbacks MUST be assigned via Inspector (not AddListener)
- Inspector serialized fields are assumed REQUIRED — no unnecessary null checks

### Logging Rules
- No log spam in release builds
- Format: [ClassName] message
- Guard hot path logs with `#if UNITY_EDITOR || DEVELOPMENT_BUILD`

### API Integrity
- Do NOT invent Unity APIs, methods, attributes, packages, or settings
- Only use verified Unity APIs
- If unsure: state "cannot verify"

---

## Mobile Performance Optimization

### Mobile Constraints

```
┌─────────────────────────────────────────────────────────────┐
│                 MOBILE PERFORMANCE PYRAMID                  │
├─────────────────────────────────────────────────────────────┤
│                    ┌────────┐                               │
│                    │ BATTERY│                               │
│                    └────┬───┘                               │
│                ┌────────┴────────┐                          │
│                │    THERMAL      │                          │
│                └────────┬────────┘                          │
│           ┌─────────────┴─────────────┐                    │
│           │         MEMORY            │                    │
│           └─────────────┬─────────────┘                    │
│      ┌──────────────────┴──────────────────┐               │
│      │             CPU / GPU               │               │
│      └─────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

### Key Settings

| Setting | Low Device | High Device |
|---------|:----------:|:-----------:|
| Target FPS | 30 | 60 |
| Resolution Scale | 0.7 | 1.0 |
| Shadow Resolution | 512 | 2048 |
| Texture Quality | Half | Full |
| MSAA | Off | 2x |

### Optimization Techniques

| Technique | Impact | Implementation |
|-----------|:------:|----------------|
| Frame Rate Cap | High | Application.targetFrameRate |
| Resolution Scale | High | Screen.SetResolution |
| VSync | Medium | QualitySettings.vSyncCount |
| GPU Skinning | Medium | Player Settings |
| Texture Streaming | High | QualitySettings |

### Best Practices
- ✅ Profile on actual device
- ✅ Use Adaptive Performance (Samsung)
- ✅ Implement quality presets
- ✅ Reduce draw calls (<100)
- ✅ Use texture atlases
- ❌ **NEVER** target 60fps on low-end
- ❌ **NEVER** ignore thermal throttling
- ❌ **NEVER** use max quality by default

## Few-Shot Examples

### Example 1: Adaptive Quality
**User**: "Auto-adjust quality based on FPS."

**Agent**:
```csharp
public class AdaptiveQuality : MonoBehaviour
{
    [SerializeField] private int _targetFPS = 30;
    [SerializeField] private int _fpsThresholdLow = 25;
    [SerializeField] private int _fpsThresholdHigh = 40;

    private float _checkInterval = 5f;
    private float _timer;
    private float _avgFPS;

    private void Update()
    {
        _avgFPS = Mathf.Lerp(_avgFPS, 1f / Time.deltaTime, 0.1f);
        _timer += Time.deltaTime;

        if (_timer >= _checkInterval)
        {
            AdjustQuality();
            _timer = 0;
        }
    }

    private void AdjustQuality()
    {
        int current = QualitySettings.GetQualityLevel();

        if (_avgFPS < _fpsThresholdLow && current > 0)
            QualitySettings.DecreaseLevel();
        else if (_avgFPS > _fpsThresholdHigh && current < QualitySettings.names.Length - 1)
            QualitySettings.IncreaseLevel();
    }
}
```

### Example 2: Battery Saver
**User**: "Add battery saving option."

**Agent**:
```csharp
public void EnableBatterySaver(bool enabled)
{
    if (enabled)
    {
        Application.targetFrameRate = 30;
        QualitySettings.SetQualityLevel(0);
        Screen.brightness = 0.5f;
    }
    else
    {
        Application.targetFrameRate = 60;
        QualitySettings.SetQualityLevel(2);
        Screen.brightness = 1f;
    }

    PlayerPrefs.SetInt("BatterySaver", enabled ? 1 : 0);
}
```

## Platform Specifics
- **Android**: Use Adaptive Performance SDK
- **iOS**: Check thermalState notifications
- **Both**: Test on min-spec devices

## Related Skills
- `@object-pooling-system` - GC-free spawning
- `@lod-occlusion-culling` - Rendering optimization
- `@memory-profiler-expert` - Memory limits
- `@my-csharp-conventions` - C# naming conventions
