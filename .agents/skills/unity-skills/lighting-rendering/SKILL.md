---
name: lighting-rendering
description: "Lighting, post-processing, and baking specialist. Use this when the user configures URP/HDRP lighting, post-processing effects, lightmap baking, light probes, or scene atmosphere setup. Also trigger for: 'scene looks flat', 'add bloom', 'bake lightmaps', 'light probes for dynamic objects', 'Volume profile', 'color grading', or any question about scene lighting and visual mood — even if they don't say 'lighting'. Do NOT use for custom shaders — use shader-graph-expert instead."
---

# Lighting & Rendering

## Overview
Unity lighting setup, post-processing effects, and baking workflows. Covers URP/HDRP Volume system, lightmap baking, light probes, and atmospheric mood creation.

## When to Use
- Use when setting up scene lighting or atmosphere
- Use when adding visual polish (bloom, vignette, color grading)
- Use when baking lightmaps or light probes
- Use when optimizing lighting for performance

## Light Types

| Type | Use Case | Shadows |
|------|----------|:-------:|
| **Directional** | Sun, moon, main light | ✅ |
| **Point** | Lamps, fires, orbs | ✅ |
| **Spot** | Flashlights, spotlights | ✅ |
| **Area** | Soft room lighting | Baked only |

## Post-Processing Effects

| Effect | Impact | Use |
|--------|:------:|-----|
| **Bloom** | Medium | Glow, HDR highlights |
| **Color Grading** | Low | Mood, LUT |
| **Vignette** | Low | Focus, atmosphere |
| **Depth of Field** | High | Focus effect |
| **Motion Blur** | High | Speed feeling |
| **Ambient Occlusion** | High | Contact shadows |

## Best Practices
- ✅ Use Global Volume for base settings, Local Volumes for area-specific
- ✅ Bake static lighting for performance
- ✅ Use Light Probes for dynamic objects in baked scenes
- ✅ Keep bloom subtle (intensity < 1)
- ❌ **NEVER** use real-time shadows for all lights
- ❌ **NEVER** enable all post-processing effects on mobile
- ❌ **NEVER** bake lighting in Play Mode

## Few-Shot Examples

### Example 1: Volume Profile Setup via Script
**User**: "Create a warm sunset atmosphere."

**Agent**:
```csharp
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class AtmosphereController : MonoBehaviour
{
    [SerializeField] private Volume _globalVolume;
    [SerializeField] private Light _directionalLight;

    public void ApplySunsetMood()
    {
        // Directional light
        _directionalLight.color = new Color(1f, 0.7f, 0.4f); // Warm orange
        _directionalLight.intensity = 1.2f;
        _directionalLight.transform.rotation = Quaternion.Euler(15f, -30f, 0f);

        // Post-processing via Volume profile
        var profile = _globalVolume.profile;

        if (profile.TryGet<ColorAdjustments>(out var colorAdj))
        {
            colorAdj.colorFilter.overrideState = true;
            colorAdj.colorFilter.value = new Color(1f, 0.9f, 0.8f);
            colorAdj.postExposure.overrideState = true;
            colorAdj.postExposure.value = 0.5f;
        }

        if (profile.TryGet<Bloom>(out var bloom))
        {
            bloom.intensity.overrideState = true;
            bloom.intensity.value = 0.5f;
            bloom.threshold.overrideState = true;
            bloom.threshold.value = 0.9f;
        }

        if (profile.TryGet<Vignette>(out var vignette))
        {
            vignette.intensity.overrideState = true;
            vignette.intensity.value = 0.3f;
        }
    }
}
```

### Example 2: Dynamic Day-Night Cycle
**User**: "Rotate the sun and change ambient over time."

**Agent**:
```csharp
public class DayNightCycle : MonoBehaviour
{
    [SerializeField] private Light _sun;
    [SerializeField] private Gradient _sunColor;
    [SerializeField] private AnimationCurve _sunIntensity;
    [SerializeField, Range(0.01f, 1f)] private float _daySpeed = 0.1f;

    private float _timeOfDay; // 0-1 range

    private void Update()
    {
        _timeOfDay = (_timeOfDay + _daySpeed * Time.deltaTime) % 1f;

        // Rotate sun based on time
        float sunAngle = Mathf.Lerp(-90f, 270f, _timeOfDay);
        _sun.transform.rotation = Quaternion.Euler(sunAngle, 170f, 0f);

        // Adjust color and intensity
        _sun.color = _sunColor.Evaluate(_timeOfDay);
        _sun.intensity = _sunIntensity.Evaluate(_timeOfDay);

        // Update ambient
        RenderSettings.ambientIntensity = Mathf.Lerp(0.2f, 1f,
            _sunIntensity.Evaluate(_timeOfDay));
    }
}
```

### Example 3: Light Probe Placement Helper
**User**: "Validate light probe coverage."

**Agent**:
```csharp
#if UNITY_EDITOR
public class LightProbeValidator : MonoBehaviour
{
    [ContextMenu("Validate Light Probe Coverage")]
    private void ValidateCoverage()
    {
        var renderers = FindObjectsOfType<MeshRenderer>();
        int uncovered = 0;

        foreach (var renderer in renderers)
        {
            if (renderer.gameObject.isStatic) continue; // Static = baked, no probes needed

            // Check if inside probe volume
            SphericalHarmonicsL2[] probes = new SphericalHarmonicsL2[1];
            Vector3[] positions = { renderer.bounds.center };
            LightProbes.CalculateInterpolatedLightAndOcclusionProbes(
                positions, probes, null);

            // Zero probe = no coverage
            if (probes[0][0, 0] == 0 && probes[0][1, 0] == 0 && probes[0][2, 0] == 0)
            {
                Debug.LogWarning($"[LightProbes] No coverage for '{renderer.name}'", renderer);
                uncovered++;
            }
        }

        Debug.Log($"[LightProbes] {uncovered} dynamic objects lack probe coverage");
    }
}
#endif
```

## Pipeline Specific
- **URP**: Volume system, limited effects
- **HDRP**: Full feature set, volumetric fog
- **Built-in**: Post Processing Stack v2

## Related Skills
- `@shader-graph-expert` - Custom effects
- `@vfx-graph-shuriken` - Particle bloom interaction
- `@lod-occlusion-culling` - Rendering optimization
