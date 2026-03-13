---
name: juice-game-feel
description: "Game feel and polish effects specialist. Use this when the user wants screen shake, hit stop, squash and stretch, particles on impact, or \"juicy\" feedback."
version: 1.0.0
tags: ["visuals", "game-feel", "juice", "polish", "feedback", "tweening"]
argument-hint: "effect='punch' target='button' OR feedback='hit' intensity='strong'"
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - run_command
  - list_dir
  - write_to_file
---

# Juice & Game Feel

## Overview
Game feel (juice) for satisfying player feedback. Combines visual, audio, and haptic responses to make gameplay feel impactful and responsive.

## When to Use
- Use when actions feel flat/unresponsive
- Use when adding impact/feedback
- Use when polishing core mechanics
- Use when improving UI responsiveness
- Use when creating satisfying loops

## Juice Pillars

```
┌─────────────────────────────────────────────────────────────┐
│                    GAME FEEL PILLARS                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  VISUAL  │  │  AUDIO   │  │  HAPTIC  │  │  TIMING  │   │
│  ├──────────┤  ├──────────┤  ├──────────┤  ├──────────┤   │
│  │ Squash   │  │ SFX      │  │ Rumble   │  │ Hitstop  │   │
│  │ Stretch  │  │ Pitch    │  │ Vibrate  │  │ Slowdown │   │
│  │ Shake    │  │ Layers   │  │ Impulse  │  │ Anticipat│   │
│  │ Flash    │  │ Reverb   │  │          │  │ Follow-  │   │
│  │ Particles│  │ Ducking  │  │          │  │ through  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Feedback Types

| Type | Elements | When |
|------|----------|------|
| **Impact** | Shake, flash, particles | Hit/damage |
| **Success** | Scale punch, SFX, glow | Pickup/complete |
| **Fail** | Shake, red flash, buzz | Error/damage |
| **Anticipation** | Wind-up, charge glow | Before action |
| **Follow-through** | Settle, trail, dust | After action |

## Tweening Essentials (DOTween)

| Tween | Use |
|-------|-----|
| `DOScale` | Punch, pop effects |
| `DOShakePosition` | Screen/object shake |
| `DOColor` | Flash, fade |
| `DOPunchScale` | Elastic feedback |
| `DOJump` | Bouncy movement |

## Best Practices
- ✅ Layer multiple feedback types
- ✅ Use easing curves (EaseOutElastic, EaseOutBounce)
- ✅ Keep effects short (< 0.3s)
- ✅ Scale feedback to action importance
- ✅ Use hitstop for impact (2-5 frames)
- ❌ **NEVER** overdo effects (less is more)
- ❌ **NEVER** use linear easing for organic motion
- ❌ **NEVER** block input during feedback

## Few-Shot Examples

### Example 1: Button Press
**User**: "Make button press feel satisfying."

**Agent**:
```csharp
public void OnButtonPress()
{
    transform.DOPunchScale(Vector3.one * -0.1f, 0.15f, 5, 0.5f);
    _audioSource.PlayOneShot(_clickSound);
    // Optional: Haptic.Generate(HapticType.Light);
}
```

### Example 2: Hit Impact
**User**: "Add juice to enemy hit."

**Agent**:
```csharp
public void OnHit(float damage)
{
    // Visual
    _spriteRenderer.DOColor(Color.white, 0.05f)
        .SetLoops(2, LoopType.Yoyo);
    transform.DOShakePosition(0.1f, 0.2f, 20);
    
    // Particles
    _hitVFX.Play();
    
    // Audio
    _audioSource.pitch = Random.Range(0.9f, 1.1f);
    _audioSource.PlayOneShot(_hitSound);
    
    // Hitstop
    Time.timeScale = 0.1f;
    DOVirtual.DelayedCall(0.05f, () => Time.timeScale = 1f);
}
```

### Example 3: Coin Pickup
**User**: "Satisfying coin collect."

**Agent**:
```csharp
public void OnCollect()
{
    // Pop and fly to UI
    transform.DOScale(1.3f, 0.1f).SetEase(Ease.OutBack);
    transform.DOMove(_uiTarget.position, 0.5f)
        .SetEase(Ease.InBack)
        .OnComplete(() => {
            _coinCounter.DOPunchScale(Vector3.one * 0.2f, 0.2f);
            _collectSound.Play();
            Destroy(gameObject);
        });
}
```

## Hitstop Implementation
```csharp
public static async UniTask Hitstop(float duration = 0.05f)
{
    Time.timeScale = 0f;
    await UniTask.Delay(TimeSpan.FromSeconds(duration), true);
    Time.timeScale = 1f;
}
```

## Related Skills
- `@vfx-graph-shuriken` - Visual feedback
- `@audio-soundscape-architect` - Audio feedback
- `@cinemachine-specialist` - Camera shake
