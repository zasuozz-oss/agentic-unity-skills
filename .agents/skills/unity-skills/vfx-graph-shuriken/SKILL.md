---
name: vfx-graph-shuriken
description: "VFX Graph and Particle System specialist. Use this when the user creates particle effects, explosions, trails, magic spells, environmental VFX, rain, fire, or smoke. Also trigger for: 'add particles', 'explosion effect', 'magic trail', 'dust particles', 'rain effect', 'hit impact VFX', or any question about visual effects — even if they don't say 'VFX' or 'particle'. Do NOT use for shader/material effects — use shader-graph-expert instead."
---

# VFX Graph & Shuriken

## Overview
Create stunning visual effects using Unity's VFX Graph (GPU) and Shuriken Particle System (CPU). From explosions to ambient particles.

## System Comparison

| Feature | Shuriken (CPU) | VFX Graph (GPU) |
|---------|:--------------:|:---------------:|
| Particle Count | Thousands | Millions |
| Physics Collisions | ✅ | Limited |
| Complex Behaviors | ✅ | ✅ |
| Performance | Medium | High |
| Ease of Use | Easy | Advanced |
| Min Unity Version | Any | 2019+ |

## Common Effects Library

| Effect | Key Settings |
|--------|--------------|
| **Fire** | Cone shape, Orange→Black color, Noise velocity |
| **Smoke** | Sphere shape, Gray, Size over lifetime ↑, Slow |
| **Explosion** | Burst emission, Sphere shape, Drag, Sub-emitters |
| **Magic Sparkle** | Point shape, HDR colors, Trails, Noise |
| **Rain** | Box shape, Gravity, Stretch, Collision |

## Best Practices
- ✅ Use object pooling for frequently spawned effects
- ✅ Use LOD for distant particle systems
- ✅ Limit collision checks (particle count limit)
- ✅ Use GPU instancing for materials
- ❌ **NEVER** use too many sub-emitters (max 2-3)
- ❌ **NEVER** enable unnecessary modules
- ❌ **NEVER** use world space for moving emitters

## Few-Shot Examples

### Example 1: VFX Spawner with Pooling
**User**: "Spawn explosion VFX at hit point."

**Agent**:
```csharp
public class VFXSpawner : MonoBehaviour
{
    [SerializeField] private ParticleSystem _explosionPrefab;
    [SerializeField] private int _poolSize = 10;

    private readonly Queue<ParticleSystem> _pool = new();

    private void Awake()
    {
        for (int i = 0; i < _poolSize; i++)
        {
            var vfx = Instantiate(_explosionPrefab, transform);
            vfx.gameObject.SetActive(false);
            _pool.Enqueue(vfx);
        }
    }

    public void SpawnAt(Vector3 position, Quaternion rotation)
    {
        if (_pool.Count == 0) return;

        var vfx = _pool.Dequeue();
        vfx.transform.SetPositionAndRotation(position, rotation);
        vfx.gameObject.SetActive(true);
        vfx.Play();

        StartCoroutine(ReturnAfterComplete(vfx));
    }

    private IEnumerator ReturnAfterComplete(ParticleSystem vfx)
    {
        yield return new WaitUntil(() => !vfx.isPlaying);
        vfx.gameObject.SetActive(false);
        _pool.Enqueue(vfx);
    }
}
```

### Example 2: Trail Effect on Projectile
**User**: "Add sparkle trail to projectile."

**Agent**:
```csharp
public class ProjectileTrail : MonoBehaviour
{
    [SerializeField] private ParticleSystem _trailParticles;
    [SerializeField] private ParticleSystem _impactParticles;

    private void Awake()
    {
        // Trail follows projectile - emit over distance
        var emission = _trailParticles.emission;
        emission.rateOverDistance = 10f;
        emission.rateOverTime = 0f;

        var trails = _trailParticles.trails;
        trails.enabled = true;
        trails.lifetime = 0.5f;
    }

    private void OnCollisionEnter(Collision collision)
    {
        // Stop trail, spawn impact
        _trailParticles.Stop(true, ParticleSystemStopBehavior.StopEmitting);

        _impactParticles.transform.position = collision.contacts[0].point;
        _impactParticles.transform.rotation =
            Quaternion.LookRotation(collision.contacts[0].normal);
        _impactParticles.Play();
    }
}
```

### Example 3: Runtime Particle Parameter Control
**User**: "Change particle color and speed based on game state."

**Agent**:
```csharp
public class DynamicVFXController : MonoBehaviour
{
    [SerializeField] private ParticleSystem _auraEffect;
    [SerializeField] private Gradient _normalColor;
    [SerializeField] private Gradient _enragedColor;

    public void SetEnraged(bool enraged)
    {
        var main = _auraEffect.main;
        main.startSpeed = enraged ? 5f : 1f;
        main.startSize = enraged ? 0.5f : 0.2f;

        var colorOverLifetime = _auraEffect.colorOverLifetime;
        colorOverLifetime.color = new ParticleSystem.MinMaxGradient(
            enraged ? _enragedColor : _normalColor);

        var emission = _auraEffect.emission;
        emission.rateOverTime = enraged ? 50f : 10f;
    }

    public void StopGracefully()
    {
        _auraEffect.Stop(true, ParticleSystemStopBehavior.StopEmitting);
        // Existing particles finish their lifetime, no new spawns
    }
}
```

## Performance Tips
- Keep Max Particles reasonable (<1000 for mobile)
- Use Simple collision mode
- Disable unnecessary modules
- Use GPU Instancing
- Pool particle systems

## Related Skills
- `@shader-graph-expert` - Custom particle materials
- `@object-pooling-system` - Effect pooling
- `@lighting-rendering` - Bloom for particles
