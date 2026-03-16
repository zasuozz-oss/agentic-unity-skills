---
name: lighting-rendering
description: "Lighting, post-processing, and baking specialist. Use this when the user configures URP/HDRP lighting, post-processing effects, lightmap baking, light probes, NavMesh baking, or scene atmosphere setup."
---

# Lighting & Rendering

## Overview
Unity lighting setup, post-processing effects, and baking workflows. Covers URP/HDRP Volume system, lightmap baking, light probes, NavMesh surface baking, and atmospheric mood creation.

## When to Use
- Use when setting up scene lighting or atmosphere
- Use when adding visual polish (bloom, vignette, color grading)
- Use when baking lightmaps or light probes
- Use when building/baking NavMesh surfaces
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

## Baking Workflow

```
1. Mark static objects → "Static" flag
2. Configure LightSettings (Samples, Bounces)
3. Lightmapping.BakeAsync()
4. Place Light Probes for dynamic objects
5. NavMeshSurface.BuildNavMesh() for AI navigation
```

## Best Practices
- ✅ Use Global Volume for base settings, Local Volumes for area-specific
- ✅ Bake static lighting for performance
- ✅ Use Light Probes for dynamic objects in baked scenes
- ✅ Use `NavMeshSurface` (AI Navigation package) over legacy static baker
- ✅ Keep bloom subtle (intensity < 1)
- ❌ **NEVER** use real-time shadows for all lights
- ❌ **NEVER** enable all post-processing effects on mobile
- ❌ **NEVER** bake lighting in Play Mode

## Few-Shot Examples

### Example 1: Sunset Mood
**User**: "Create a warm sunset atmosphere."

**Agent**:
```
Directional Light: Color RGB(255, 180, 100), Intensity 1.2, Rotation X=15
Volume Profile:
- Color Grading: Warm temperature +20
- Bloom: Intensity 0.5, Threshold 0.9
- Vignette: Intensity 0.3
```

### Example 2: NavMesh Bake
**User**: "Rebuild NavMesh."

**Agent**:
```csharp
var surfaces = Object.FindObjectsOfType<NavMeshSurface>();
foreach (var surface in surfaces) surface.BuildNavMesh();
```

## Pipeline Specific
- **URP**: Volume system, limited effects
- **HDRP**: Full feature set, volumetric fog
- **Built-in**: Post Processing Stack v2

## Related Skills
- `@shader-graph-expert` - Custom effects
- `@vfx-graph-shuriken` - Particle bloom interaction
- `@cinemachine-specialist` - Camera DOF
