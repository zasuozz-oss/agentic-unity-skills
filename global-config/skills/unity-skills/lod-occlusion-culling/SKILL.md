---
name: lod-occlusion-culling
description: "LOD and occlusion culling specialist. Use this when the user optimizes rendering performance, configures LOD groups, sets up occlusion culling, or reduces draw calls. Also trigger for: 'too many draw calls', 'objects behind walls still rendered', 'distant objects too detailed', 'LOD configuration', 'frustum culling', or any question about rendering optimization via visibility management — even if they don't say 'LOD' or 'culling'."
---

# LOD & Occlusion Culling

## Overview
Reduce rendering workload by showing lower-detail models at distance (LOD) and skipping invisible objects (Occlusion Culling). Essential for open-world and mobile games.

## When to Use
- Use when draw calls are too high
- Use for open-world or large scenes
- Use for mobile performance optimization
- Use when distant objects don't need full detail
- Use for indoor scenes with many rooms

## LOD Best Practices

| LOD Level | Poly Count | Distance |
|-----------|:----------:|:--------:|
| LOD0 | 100% | 0-20m |
| LOD1 | 50% | 20-50m |
| LOD2 | 25% | 50-100m |
| Culled | 0% | 100m+ |

## Culling Types

| Type | What it Does | Performance Impact |
|------|-------------|:------------------:|
| **Frustum** | Skips off-screen objects | Free (automatic) |
| **Occlusion** | Skips hidden behind walls | Medium (bake cost) |
| **Distance** | Skips far objects (LOD cull) | Low |
| **Layer** | Skip by camera layer mask | Free |

## Best Practices
- ✅ Use LOD groups for all complex meshes
- ✅ Bake occlusion culling for static indoor scenes
- ✅ Use LODGroup.crossFadeAnimationDuration for smooth transitions
- ✅ Profile with Frame Debugger before and after
- ❌ **NEVER** skip LOD on mobile (biggest draw call saver)
- ❌ **NEVER** use occlusion culling for fully outdoor open scenes (too many occluders)
- ❌ **NEVER** manually hide/show objects for culling (use Unity's system)

## Few-Shot Examples

### Example 1: Runtime LOD Bias Adjustment
**User**: "Adjust LOD quality based on device performance."

**Agent**:
```csharp
public class AdaptiveLOD : MonoBehaviour
{
    [SerializeField] private float _targetFrameRate = 30f;
    [SerializeField, Range(0.5f, 4f)] private float _maxLodBias = 2f;
    [SerializeField, Range(0.1f, 1f)] private float _minLodBias = 0.5f;

    private float _currentBias = 1f;
    private float _sampleTimer;
    private int _frameCount;

    private void Update()
    {
        _frameCount++;
        _sampleTimer += Time.unscaledDeltaTime;

        if (_sampleTimer < 1f) return;

        float fps = _frameCount / _sampleTimer;
        _frameCount = 0;
        _sampleTimer = 0f;

        // Below target FPS → lower LOD quality (show LOD1 sooner)
        if (fps < _targetFrameRate * 0.9f)
            _currentBias = Mathf.Max(_minLodBias, _currentBias - 0.1f);
        // Above target → increase quality if headroom
        else if (fps > _targetFrameRate * 1.1f)
            _currentBias = Mathf.Min(_maxLodBias, _currentBias + 0.05f);

        QualitySettings.lodBias = _currentBias;
    }
}
```

### Example 2: LOD Group Setup via Script
**User**: "Set up LOD group programmatically."

**Agent**:
```csharp
public class LODGroupSetup : MonoBehaviour
{
    [SerializeField] private Renderer _lod0Renderer;
    [SerializeField] private Renderer _lod1Renderer;
    [SerializeField] private Renderer _lod2Renderer;

    private void Awake()
    {
        var lodGroup = gameObject.AddComponent<LODGroup>();

        var lods = new LOD[3];
        lods[0] = new LOD(0.6f, new[] { _lod0Renderer });  // 60% screen → full detail
        lods[1] = new LOD(0.3f, new[] { _lod1Renderer });  // 30% screen → medium
        lods[2] = new LOD(0.1f, new[] { _lod2Renderer });  // 10% screen → low
        // Below 10% → culled (no renderers)

        lodGroup.SetLODs(lods);
        lodGroup.RecalculateBounds();

        // Enable crossfade for smooth transitions
        lodGroup.fadeMode = LODFadeMode.CrossFade;
        lodGroup.animateCrossFading = true;
    }
}
```

### Example 3: Occlusion Culling Validator
**User**: "Check if occlusion culling is effective."

**Agent**:
```csharp
#if UNITY_EDITOR
public class OcclusionCullingStats : MonoBehaviour
{
    [Header("Debug")]
    [SerializeField] private bool _showStats;

    private int _totalRenderers;
    private int _visibleRenderers;

    private void Start()
    {
        _totalRenderers = FindObjectsOfType<Renderer>().Length;
    }

    private void OnGUI()
    {
        if (!_showStats) return;

        // Count currently visible renderers
        _visibleRenderers = 0;
        foreach (var renderer in FindObjectsOfType<Renderer>())
        {
            if (renderer.isVisible) _visibleRenderers++;
        }

        float culledPercent = (1f - (float)_visibleRenderers / _totalRenderers) * 100f;

        GUI.Label(new Rect(10, 10, 300, 60),
            $"Renderers: {_visibleRenderers}/{_totalRenderers}\n" +
            $"Culled: {culledPercent:F1}%\n" +
            $"LOD Bias: {QualitySettings.lodBias:F2}");
    }
}
#endif
```

## Related Skills
- `@performance-advisor` - General performance review
- `@mobile-optimization` - Mobile rendering budget
- `@lighting-rendering` - Lighting optimization
