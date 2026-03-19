---
name: mobile-optimization
description: "Unity mobile and general performance optimizer for Android/iOS. Use this when the user needs performance tuning, battery optimization, thermal throttling, hot-path analysis, GC allocation review, Update optimization, or frame rate management. Also trigger for: 'game runs slow', 'battery drains fast', 'heating on mobile', 'frame drops', 'GC spikes', 'slow Update loop', 'too many draw calls', 'how to optimize this script', or any question about runtime performance — even if they don't say 'performance' or 'mobile'."
---

# Mobile Optimization

## Overview
Mobile-specific optimization techniques for Android and iOS. Covers frame rate, resolution scaling, texture compression, battery management, and device-tier adaptation.

## When to Use
- Use for any mobile game project
- Use when performance drops on low-end devices
- Use when battery drain is a concern
- Use when app size needs reduction
- Use when targeting both Android and iOS

## Mobile Performance Budget

| Metric | Budget |
|--------|:------:|
| Frame Time | < 33ms (30fps) / < 16ms (60fps) |
| Draw Calls | < 100 |
| Triangles | < 200K per frame |
| Texture Memory | < 150MB |
| Audio Memory | < 30MB |
| App Size | < 150MB (store limit) |

## Coding Rules
- ✅ Use `Application.targetFrameRate = 30` for non-action games
- ✅ Use `Screen.SetResolution` for dynamic resolution
- ✅ Use ASTC (Android) / PVRTC (iOS) texture compression
- ✅ Cap physics to 30 FPS (`Time.fixedDeltaTime = 1f/30f`)
- ✅ Use `OnDemandRendering.renderFrameInterval` for idle screens
- ❌ **NEVER** use real-time shadows on mobile (bake them)
- ❌ **NEVER** use `Debug.Log` in release builds
- ❌ **NEVER** use reflection in hot paths

## Few-Shot Examples

### Example 1: Adaptive Quality System
**User**: "Auto-adjust quality based on device."

**Agent**:
```csharp
public class AdaptiveQuality : MonoBehaviour
{
    [SerializeField] private int _targetFPS = 30;

    private float _sampleTimer;
    private int _frameCount;
    private int _currentQualityLevel;

    private void Start()
    {
        Application.targetFrameRate = _targetFPS;
        _currentQualityLevel = DetectDeviceTier();
        ApplyQuality(_currentQualityLevel);
    }

    private int DetectDeviceTier()
    {
        int ram = SystemInfo.systemMemorySize;
        int cores = SystemInfo.processorCount;

        if (ram >= 6000 && cores >= 8) return 2; // High
        if (ram >= 4000 && cores >= 4) return 1; // Medium
        return 0; // Low
    }

    private void ApplyQuality(int tier)
    {
        switch (tier)
        {
            case 0: // Low
                QualitySettings.SetQualityLevel(0);
                Screen.SetResolution(Screen.width / 2, Screen.height / 2, true);
                QualitySettings.shadows = ShadowQuality.Disable;
                QualitySettings.lodBias = 0.5f;
                break;
            case 1: // Medium
                QualitySettings.SetQualityLevel(1);
                Screen.SetResolution((int)(Screen.width * 0.75f),
                    (int)(Screen.height * 0.75f), true);
                QualitySettings.shadows = ShadowQuality.HardOnly;
                QualitySettings.lodBias = 1f;
                break;
            case 2: // High
                QualitySettings.SetQualityLevel(2);
                QualitySettings.shadows = ShadowQuality.All;
                QualitySettings.lodBias = 1.5f;
                break;
        }
    }

    private void Update()
    {
        _frameCount++;
        _sampleTimer += Time.unscaledDeltaTime;
        if (_sampleTimer < 2f) return;

        float fps = _frameCount / _sampleTimer;
        _frameCount = 0;
        _sampleTimer = 0f;

        if (fps < _targetFPS * 0.8f && _currentQualityLevel > 0)
        {
            _currentQualityLevel--;
            ApplyQuality(_currentQualityLevel);
        }
    }
}
```

### Example 2: Battery-Saving Mode
**User**: "Reduce power usage when game is idle."

**Agent**:
```csharp
public class BatterySaver : MonoBehaviour
{
    private bool _isBatterySaving;

    public void EnableBatterySaving()
    {
        _isBatterySaving = true;

        // Reduce frame rate to minimum needed
        Application.targetFrameRate = 20;

        // Reduce rendering for idle screens (render every 3rd frame)
        OnDemandRendering.renderFrameInterval = 3;

        // Lower resolution
        Screen.SetResolution(Screen.width / 2, Screen.height / 2, true);

        // Disable non-essential systems
        QualitySettings.vSyncCount = 0;
        QualitySettings.shadows = ShadowQuality.Disable;
    }

    public void DisableBatterySaving()
    {
        _isBatterySaving = false;

        Application.targetFrameRate = 30;
        OnDemandRendering.renderFrameInterval = 1;
        Screen.SetResolution(Screen.width, Screen.height, true);
    }

    // Auto-enable when battery is low (check periodically)
    private void CheckBattery()
    {
        if (SystemInfo.batteryLevel < 0.2f && SystemInfo.batteryLevel > 0f
            && !_isBatterySaving)
        {
            EnableBatterySaving();
            Debug.Log("[BatterySaver] Low battery detected, enabling power saving");
        }
    }
}
```

### Example 3: Conditional Debug Logging
**User**: "Remove Debug.Log from release builds."

**Agent**:
```csharp
public static class GameLog
{
    [System.Diagnostics.Conditional("UNITY_EDITOR")]
    [System.Diagnostics.Conditional("DEVELOPMENT_BUILD")]
    public static void Log(string message)
    {
        Debug.Log(message);
    }

    [System.Diagnostics.Conditional("UNITY_EDITOR")]
    [System.Diagnostics.Conditional("DEVELOPMENT_BUILD")]
    public static void LogWarning(string message)
    {
        Debug.LogWarning(message);
    }

    // Errors always log (even in release)
    public static void LogError(string message)
    {
        Debug.LogError(message);
    }
}

// Usage:
// GameLog.Log("Enemy spawned"); // Compiled out in Release
// GameLog.LogError("Critical failure"); // Always included
```

## Platform-Specific

| Setting | Android | iOS |
|---------|---------|-----|
| Texture | ASTC | ASTC (modern) / PVRTC (legacy) |
| Scripting Backend | IL2CPP | IL2CPP |
| Min API | 24 (Android 7) | iOS 14 |
| Architecture | ARM64 | ARM64 |

## General Performance Red Flags

These apply to ALL platforms but are critical on mobile:

### Update Loop
- ❌ `Camera.main` not cached (uses `FindGameObjectWithTag` internally)
- ❌ `GetComponent<T>()` per frame (cache in Awake/Start)
- ❌ `FindObjectOfType` at runtime
- ❌ LINQ (`.Where`, `.Select`, `.Any`) in hot paths
- ❌ String concatenation (`+`, `$""`) per frame
- ❌ `new List<T>()` / closures / lambdas per frame

### Caching
- ✅ Cache component references in Awake/Start
- ✅ Use `sqrMagnitude` instead of `Distance`
- ✅ Use `Animator.StringToHash` for parameters
- ✅ Use `const string` for status comparisons

### Allocation Reduction
- ✅ Use object pooling for frequent spawn/destroy
- ✅ Use `StringBuilder` for string building in loops
- ✅ Replace `foreach` with `for` on non-List collections
- ✅ Cache delegates/lambdas as fields

### Event-Driven vs Polling
- Replace `Update()` checks with C# Events or `UnityEvent` triggers
- If polling is required, use timer throttling

## Related Skills
- `@memory-profiler-expert` - Deep memory analysis
- `@addressables-asset-management` - Asset management
- `@canvas-performance` - UI optimization
- `@object-pooling-system` - Pooling implementation
