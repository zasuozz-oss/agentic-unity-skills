---
name: audio-systems
description: "Unity audio systems specialist. Use this when the user needs AudioMixer setup, volume control, sound categories, music crossfading, environmental effects, or audio management. Also trigger for: 'volume slider', 'mute music', 'sound not playing', 'background music loop', '3D sound', 'audio ducking', or any question about sound in Unity — even if they don't say 'audio'. Do NOT use for FMOD/Wwise deep integration — this covers Unity native audio."
---

# Audio Systems

## Overview
Unity audio management using AudioMixer, AudioSource, and AudioClip. Covers volume control, music crossfading, sound categories, and environmental audio effects.

## When to Use
- Use for sound effects management
- Use for music playback and crossfading
- Use for volume settings (sliders)
- Use for audio ducking and effects
- Use for 3D spatial audio setup

## AudioMixer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AUDIOMIXER GROUPS                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  MASTER                                                      │
│  ├── MUSIC ────── Background, Menu, Battle                   │
│  ├── SFX ──────── UI Clicks, Footsteps, Combat               │
│  ├── VOICE ────── Dialogue, Announcer                        │
│  └── AMBIENT ──── Rain, Wind, Crowd                          │
│                                                              │
│  Each group: Volume, Pitch, Effects (Reverb, Chorus)         │
└─────────────────────────────────────────────────────────────┘
```

## Best Practices
- ✅ Use AudioMixer groups for each category
- ✅ Expose mixer parameters for volume control
- ✅ Use logarithmic scale for volume sliders (dB)
- ✅ Pool AudioSources for frequent SFX
- ✅ Use Audio Snapshots for environmental transitions
- ❌ **NEVER** use linear 0-1 for mixer volume (sounds wrong)
- ❌ **NEVER** create new AudioSource per sound (pool them)
- ❌ **NEVER** forget to compress audio for mobile

## Few-Shot Examples

### Example 1: Volume Control with Mixer
**User**: "Volume slider for music."

**Agent**:
```csharp
public class VolumeController : MonoBehaviour
{
    [SerializeField] private AudioMixer _audioMixer;

    // Exposed parameters: "MasterVolume", "MusicVolume", "SFXVolume"
    public void SetMusicVolume(float sliderValue)
    {
        // Convert linear slider (0-1) to logarithmic dB (-80 to 0)
        float dB = sliderValue > 0.001f
            ? Mathf.Log10(sliderValue) * 20f
            : -80f;
        _audioMixer.SetFloat("MusicVolume", dB);
    }

    public void SetMasterVolume(float sliderValue)
    {
        float dB = sliderValue > 0.001f
            ? Mathf.Log10(sliderValue) * 20f
            : -80f;
        _audioMixer.SetFloat("MasterVolume", dB);
    }

    public float GetMusicVolume()
    {
        _audioMixer.GetFloat("MusicVolume", out float dB);
        return Mathf.Pow(10, dB / 20f); // Convert back to linear for slider
    }
}
```

### Example 2: Music Crossfade
**User**: "Smoothly transition between two music tracks."

**Agent**:
```csharp
public class MusicManager : MonoBehaviour
{
    [SerializeField] private AudioSource _sourceA;
    [SerializeField] private AudioSource _sourceB;
    [SerializeField] private float _crossfadeDuration = 2f;

    private AudioSource _currentSource;

    private void Awake()
    {
        _currentSource = _sourceA;
    }

    public void CrossfadeTo(AudioClip newClip)
    {
        var nextSource = _currentSource == _sourceA ? _sourceB : _sourceA;
        nextSource.clip = newClip;
        nextSource.Play();

        StartCoroutine(CrossfadeCoroutine(_currentSource, nextSource));
        _currentSource = nextSource;
    }

    private IEnumerator CrossfadeCoroutine(AudioSource fadeOut, AudioSource fadeIn)
    {
        float elapsed = 0f;
        fadeIn.volume = 0f;

        while (elapsed < _crossfadeDuration)
        {
            elapsed += Time.deltaTime;
            float t = elapsed / _crossfadeDuration;
            fadeOut.volume = 1f - t;
            fadeIn.volume = t;
            yield return null;
        }

        fadeOut.Stop();
        fadeOut.volume = 1f;
    }
}
```

### Example 3: Environmental Audio with Snapshots
**User**: "Muffle sounds underwater."

**Agent**:
```csharp
public class EnvironmentalAudio : MonoBehaviour
{
    [SerializeField] private AudioMixerSnapshot _normalSnapshot;
    [SerializeField] private AudioMixerSnapshot _underwaterSnapshot;
    [SerializeField] private float _transitionTime = 0.5f;

    public void EnterUnderwater()
    {
        _underwaterSnapshot.TransitionTo(_transitionTime);
    }

    public void ExitUnderwater()
    {
        _normalSnapshot.TransitionTo(_transitionTime);
    }

    // In underwater AudioMixer snapshot:
    // - SFX group: LowPass filter at 800Hz
    // - Music group: Volume -10dB
    // - Ambient group: Add Reverb effect
}
```

## Audio Middleware Comparison

| Feature | Unity Audio | FMOD | Wwise |
|---------|:----------:|:----:|:-----:|
| Cost | Free | Indie free | $$$ |
| Adaptive Music | Manual | ✅ | ✅ |
| Real-time Mixing | Basic | ✅ | ✅ |
| Integration | Native | Package | Package |

## Related Skills
- `@mobile-optimization` - Audio compression for mobile
- `@addressables-asset-management` - Async audio loading
- `@backend-integration` - Persisting settings via API
