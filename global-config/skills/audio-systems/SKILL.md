---
name: audio-systems
description: "Unity audio management specialist. Use this when the user needs audio managers, AudioMixer setup, sound pooling, music crossfading, dynamic volume control, audio snapshots, ducking, or spatial audio."
---

# Audio Systems

## Overview
Unity audio systems for immersive soundscapes. Covers AudioSource management, AudioMixer hierarchy, spatial audio, snapshots, dynamic effects, and middleware integration (FMOD, Wwise).

## When to Use
- Use when implementing game audio systems or audio managers
- Use for volume control (settings menus, sliders)
- Use for audio ducking (dialogue/music)
- Use for context-based snapshots (underwater, combat, pause)
- Use for music crossfading and transitions
- Use for spatial 3D audio positioning

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   AUDIO MIXER HIERARCHY                     │
├─────────────────────────────────────────────────────────────┤
│                      [MASTER]                               │
│          ┌──────────┬───────┴───────┬──────────┐           │
│          ▼          ▼               ▼          ▼           │
│      [MUSIC]    [SFX]          [AMBIENT]   [VOICE]        │
│                                                             │
│  SNAPSHOTS: [Default] [Combat] [Pause] [Underwater]        │
└─────────────────────────────────────────────────────────────┘
```

## Audio Categories

| Category | Use | Settings |
|----------|-----|----------|
| **SFX** | One-shot effects | 2D/3D, pooled |
| **Music** | Background tracks | Loop, crossfade |
| **Ambient** | Environment | 3D spatial, loop |
| **Voice** | Dialogue, narration | Priority, ducking |
| **UI** | Interface feedback | 2D, low latency |

## Common Patterns

| Pattern | Implementation |
|---------|----------------|
| **Volume Slider** | Expose group volume, logarithmic dB conversion |
| **Dialogue Ducking** | Snapshot lowers music during voice |
| **Underwater** | Lowpass + Reverb snapshot |
| **Pause Menu** | Snapshot pauses SFX, keeps music |
| **Combat** | Snapshot boosts impact sounds |

## Best Practices
- ✅ Use object pooling for frequent SFX
- ✅ Use AudioMixer groups for volume control
- ✅ Compress audio (Vorbis for music, ADPCM for short SFX)
- ✅ Expose Master, Music, SFX, Voice volumes as parameters
- ✅ Use dB logarithmic conversion for sliders
- ❌ **NEVER** hardcode volume values or use linear 0-1 directly
- ❌ **NEVER** load all audio at startup
- ❌ **NEVER** skip AudioMixer for direct volume manipulation

## Few-Shot Examples

### Example 1: Volume Slider
**User**: "Connect slider to music volume."

**Agent**:
```csharp
[SerializeField] private AudioMixer _mixer;
[SerializeField] private Slider _musicSlider;

public void SetMusicVolume(float value)
{
    float dB = value > 0.001f ? Mathf.Log10(value) * 20f : -80f;
    _mixer.SetFloat("MusicVolume", dB);
}
```

### Example 2: Music Crossfade
**User**: "Fade between music tracks."

**Agent**:
```csharp
public async UniTask CrossfadeMusic(AudioClip newTrack, float duration)
{
    var fadeOut = _currentSource.DOFade(0, duration).ToUniTask();
    _nextSource.clip = newTrack;
    _nextSource.volume = 0;
    _nextSource.Play();
    var fadeIn = _nextSource.DOFade(1, duration).ToUniTask();
    await UniTask.WhenAll(fadeOut, fadeIn);
    (_currentSource, _nextSource) = (_nextSource, _currentSource);
}
```

### Example 3: Underwater Effect
**User**: "Muffle audio when player is underwater."

**Agent**:
```csharp
// "Underwater" snapshot: Lowpass Cutoff 800Hz, Reverb Wet 30%
public void EnterWater()
{
    _mixer.TransitionToSnapshots(
        new[] { _underwaterSnapshot }, 
        new[] { 1f }, 
        0.5f);
}
```

## Volume Conversion
```csharp
float LinearToDecibel(float linear) 
    => linear > 0.0001f ? Mathf.Log10(linear) * 20f : -80f;
float DecibelToLinear(float dB) 
    => Mathf.Pow(10f, dB / 20f);
```

## Middleware Comparison

| Feature | Unity Audio | FMOD | Wwise |
|---------|:-----------:|:----:|:-----:|
| Cost | Free | Indie free | $$ |
| Features | Basic | Rich | Enterprise |
| 3D Audio | Good | Excellent | Excellent |

## Related Skills
- `@juice-game-feel` - Audio feedback
- `@vfx-graph-shuriken` - Audio-reactive VFX
- `@save-load-serialization` - Persist volume settings
