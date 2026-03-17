---
name: shader-graph-expert
description: "Shader Graph development specialist. Use this when the user creates custom shaders, visual effects in Shader Graph, dissolve effects, toon shading, or custom material properties. Also trigger for: 'hologram effect', 'dissolve shader', 'outline shader', 'water shader', 'glowing material', or any question about visual material effects — even if they don't say 'shader'. Do NOT use for lighting/post-processing setup — use lighting-rendering instead."
---

# Shader Graph Expert

## Overview
Unity Shader Graph for creating custom shaders visually. Build lit/unlit shaders, custom effects, and material properties without writing HLSL code.

## When to Use
- Use when creating custom material effects
- Use when implementing dissolve, hologram, force field effects
- Use when building stylized rendering
- Use when vertex displacement is needed
- Use when creating procedural textures

## Shader Types

| Type | Use Case |
|------|----------|
| **Lit** | PBR materials with lighting |
| **Unlit** | UI, effects, no lighting |
| **Sprite Lit** | 2D sprites with lighting |
| **Decal** | Surface overlays |
| **Fullscreen** | Post-processing effects |

## Common Effects

| Effect | Key Nodes |
|--------|-----------|
| **Dissolve** | Noise + Step + Alpha Clip |
| **Hologram** | Fresnel + Scanlines + Emission |
| **Force Field** | Intersection + Fresnel + Distortion |
| **Water** | Noise + Normal Map + Refraction |
| **Outline** | Vertex Offset + Inverse Hull |

## Best Practices
- ✅ Use Sub Graphs for reusable node groups
- ✅ Expose properties for material variants
- ✅ Use Keywords for shader variants
- ✅ Preview performance in Scene view
- ✅ Use Gradient nodes for color ramps
- ❌ **NEVER** overuse expensive nodes (Voronoi, expensive math)
- ❌ **NEVER** forget to set precision (Full/Half)
- ❌ **NEVER** ignore GPU instancing compatibility

## Few-Shot Examples

### Example 1: Dissolve Effect Controller
**User**: "Create a dissolve shader and control it from script."

**Agent**:
```csharp
// Shader Graph setup:
// 1. Simple Noise (Scale 20) → Step (Edge: _DissolveAmount, In: Noise) → Alpha
// 2. Set Alpha Clip Threshold = 0.5
// 3. Create _DissolveAmount property (Float, Range 0-1)
// 4. Optional: Smoothstep for edge glow → Emission

// C# Controller:
public class DissolveEffect : MonoBehaviour
{
    [SerializeField] private Renderer _renderer;
    [SerializeField] private float _dissolveDuration = 1.5f;
    [SerializeField] private Color _edgeColor = Color.red;

    private Material _material;
    private static readonly int DissolveAmount = Shader.PropertyToID("_DissolveAmount");
    private static readonly int EdgeColor = Shader.PropertyToID("_EdgeColor");

    private void Awake()
    {
        _material = _renderer.material; // Instance the material
        _material.SetColor(EdgeColor, _edgeColor);
    }

    public async UniTask DissolveAsync(CancellationToken ct)
    {
        float elapsed = 0f;
        while (elapsed < _dissolveDuration)
        {
            elapsed += Time.deltaTime;
            float t = elapsed / _dissolveDuration;
            _material.SetFloat(DissolveAmount, t);
            await UniTask.Yield(ct);
        }
        gameObject.SetActive(false);
    }

    private void OnDestroy()
    {
        if (_material != null) Destroy(_material);
    }
}
```

### Example 2: Hologram Material Controller
**User**: "Make a hologram material with scanlines."

**Agent**:
```csharp
// Shader Graph setup (Unlit):
// 1. Fresnel Effect (Power: 3) → Multiply with HDR color → rim glow
// 2. UV.y * 100 + _Time → Frac → Step(0.5) → scanlines
// 3. Multiply rim * scanlines * _HologramColor → Emission
// Properties: _HologramColor (Color HDR), _ScanlineSpeed (Float), _Glitch (Float)

// C# Controller:
public class HologramEffect : MonoBehaviour
{
    [SerializeField] private Renderer _renderer;
    [SerializeField, ColorUsage(true, true)] private Color _holoColor = Color.cyan;
    [SerializeField, Range(0f, 1f)] private float _glitchIntensity = 0.1f;

    private Material _material;
    private static readonly int HoloColor = Shader.PropertyToID("_HologramColor");
    private static readonly int Glitch = Shader.PropertyToID("_Glitch");

    private void Awake()
    {
        _material = _renderer.material;
        _material.SetColor(HoloColor, _holoColor);
    }

    private void Update()
    {
        // Random glitch effect
        float glitch = Random.value < 0.05f ? _glitchIntensity : 0f;
        _material.SetFloat(Glitch, glitch);
    }

    private void OnDestroy()
    {
        if (_material != null) Destroy(_material);
    }
}
```

### Example 3: Material Property Block (GPU Instancing Safe)
**User**: "Change shader properties per-object without breaking instancing."

**Agent**:
```csharp
// Use MaterialPropertyBlock instead of material.SetFloat
// This keeps GPU instancing intact (batching preserved)
public class ShaderPropertyController : MonoBehaviour
{
    [SerializeField] private Renderer _renderer;
    [SerializeField, Range(0f, 1f)] private float _fillAmount = 1f;
    [SerializeField] private Color _tintColor = Color.white;

    private MaterialPropertyBlock _mpb;
    private static readonly int FillAmount = Shader.PropertyToID("_FillAmount");
    private static readonly int TintColor = Shader.PropertyToID("_TintColor");

    private void Awake()
    {
        _mpb = new MaterialPropertyBlock();
    }

    public void SetFill(float amount)
    {
        _fillAmount = amount;
        ApplyProperties();
    }

    private void ApplyProperties()
    {
        _renderer.GetPropertyBlock(_mpb);
        _mpb.SetFloat(FillAmount, _fillAmount);
        _mpb.SetColor(TintColor, _tintColor);
        _renderer.SetPropertyBlock(_mpb);
    }

    private void OnValidate()
    {
        if (_renderer != null && _mpb != null) ApplyProperties();
    }
}
```

## Pipeline Compatibility
- **URP**: Full support, use URP shaders
- **HDRP**: Full support, more features
- **Built-in**: Limited, use Amplify Shader instead

## Related Skills
- `@vfx-graph-shuriken` - Particle effects
- `@lighting-rendering` - Lighting setup
- `@mobile-optimization` - Shader optimization for mobile
