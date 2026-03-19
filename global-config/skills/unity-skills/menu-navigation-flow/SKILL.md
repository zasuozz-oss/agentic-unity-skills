---
name: menu-navigation-flow
description: "Menu navigation and screen management system. Use this when the user needs screen stack management, menu transitions, back button handling, or multi-screen UI flow. Also trigger for: 'main menu to settings', 'pause menu', 'how to navigate between screens', 'back button', 'screen history', 'push/pop UI screens', or any question about managing multiple UI screens and transitions — even if they don't say 'navigation'. Do NOT use for individual UI layout — use responsive-ui-design instead."
---

# Menu Navigation Flow

## Overview
Stack-based screen management for Unity games. Handle push/pop navigation, transitions, back button history, and overlay vs fullscreen screens.

## When to Use
- Use for main menu → settings → gameplay flow
- Use for pause menu with back stack
- Use for popup overlays with history
- Use for mobile back button handling
- Use for nested navigation (tab + stack)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   SCREEN STACK                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  NavigationService                                           │
│  ┌─────────────────────────────┐                             │
│  │ Stack<ScreenBase>           │                             │
│  │  [2] PauseScreen (TOP)     │ ← Active, receives input    │
│  │  [1] GameplayScreen        │ ← Paused                    │
│  │  [0] MainMenuScreen        │ ← Hidden                    │
│  └─────────────────────────────┘                             │
│                                                              │
│  Push("Pause") → Stack grows                                 │
│  Pop()         → Stack shrinks, previous resumes             │
│  Replace()     → Swap top without history                    │
└─────────────────────────────────────────────────────────────┘
```

## Screen Types

| Type | Stack Behavior |
|------|---------------|
| **Fullscreen** | Push, hides previous |
| **Overlay** | Push, previous visible behind |
| **Popup** | Push, dims background |
| **Replace** | Replaces top, no back navigation |

## Best Practices
- ✅ Use a stack for back navigation history
- ✅ Animate transitions (fade, slide)
- ✅ Handle Android back button (Escape key)
- ✅ Disable input on previous screens during transition
- ❌ **NEVER** hardcode screen references
- ❌ **NEVER** forget to handle back button
- ❌ **NEVER** leave hidden screens processing input

## Few-Shot Examples

### Example 1: Stack-Based Navigation Service
**User**: "Push/pop screen navigation."

**Agent**:
```csharp
public class NavigationService : MonoBehaviour
{
    [SerializeField] private Transform _screenContainer;
    private readonly Stack<ScreenBase> _screenStack = new();
    private readonly Dictionary<string, ScreenBase> _screens = new();

    public void RegisterScreen(string id, ScreenBase screen)
    {
        _screens[id] = screen;
        screen.gameObject.SetActive(false);
    }

    public void Push(string screenId)
    {
        if (_screenStack.TryPeek(out var current))
            current.OnPause();

        var screen = _screens[screenId];
        _screenStack.Push(screen);
        screen.gameObject.SetActive(true);
        screen.OnShow();
    }

    public void Pop()
    {
        if (_screenStack.Count <= 1) return; // Don't pop root

        var top = _screenStack.Pop();
        top.OnHide();
        top.gameObject.SetActive(false);

        if (_screenStack.TryPeek(out var previous))
            previous.OnResume();
    }

    private void Update()
    {
        // Android back button / Escape
        if (Input.GetKeyDown(KeyCode.Escape) && _screenStack.Count > 1)
            Pop();
    }
}

public abstract class ScreenBase : MonoBehaviour
{
    public virtual void OnShow() { }
    public virtual void OnHide() { }
    public virtual void OnPause() { }
    public virtual void OnResume() { }
}
```

### Example 2: Animated Screen Transitions
**User**: "Fade transition between screens."

**Agent**:
```csharp
public class FadeTransition : MonoBehaviour
{
    [SerializeField] private CanvasGroup _canvasGroup;
    [SerializeField] private float _fadeDuration = 0.3f;

    public async UniTask FadeInAsync(CancellationToken ct)
    {
        _canvasGroup.alpha = 0f;
        _canvasGroup.interactable = false;

        float elapsed = 0f;
        while (elapsed < _fadeDuration)
        {
            elapsed += Time.unscaledDeltaTime;
            _canvasGroup.alpha = elapsed / _fadeDuration;
            await UniTask.Yield(ct);
        }

        _canvasGroup.alpha = 1f;
        _canvasGroup.interactable = true;
    }

    public async UniTask FadeOutAsync(CancellationToken ct)
    {
        _canvasGroup.interactable = false;
        float elapsed = 0f;

        while (elapsed < _fadeDuration)
        {
            elapsed += Time.unscaledDeltaTime;
            _canvasGroup.alpha = 1f - (elapsed / _fadeDuration);
            await UniTask.Yield(ct);
        }

        _canvasGroup.alpha = 0f;
    }
}
```

### Example 3: Settings Screen Implementation
**User**: "Create settings screen with back navigation."

**Agent**:
```csharp
public class SettingsScreen : ScreenBase
{
    [SerializeField] private NavigationService _navigation;
    [SerializeField] private Slider _musicSlider;
    [SerializeField] private Slider _sfxSlider;
    [SerializeField] private Button _backButton;

    private VolumeController _volumeController;

    public override void OnShow()
    {
        _backButton.onClick.AddListener(OnBackClicked);

        // Load current settings
        _musicSlider.value = _volumeController.GetMusicVolume();
        _sfxSlider.value = _volumeController.GetSFXVolume();

        // Listen for changes
        _musicSlider.onValueChanged.AddListener(_volumeController.SetMusicVolume);
        _sfxSlider.onValueChanged.AddListener(_volumeController.SetSFXVolume);
    }

    public override void OnHide()
    {
        _backButton.onClick.RemoveListener(OnBackClicked);
        _musicSlider.onValueChanged.RemoveListener(_volumeController.SetMusicVolume);
        _sfxSlider.onValueChanged.RemoveListener(_volumeController.SetSFXVolume);
    }

    private void OnBackClicked() => _navigation.Pop();
}
```

## Related Skills
- `@responsive-ui-design` - UI layout patterns
- `@responsive-ui-design` - Screen layout
- `@canvas-performance` - UI performance
