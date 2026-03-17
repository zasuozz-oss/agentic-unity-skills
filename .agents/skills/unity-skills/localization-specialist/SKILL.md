---
name: localization-specialist
description: "Unity Localization package specialist. Use this when the user needs multi-language support, string tables, locale switching, asset tables, smart string formatting, or RTL text support. Also trigger for: 'translate to Japanese', 'multi-language', 'localize UI text', 'string table', 'locale selector', 'right-to-left text', or any question about supporting multiple languages — even if they don't say 'localization'."
---

# Localization Specialist

## Overview
Unity Localization package for multi-language support. Covers String Tables, Asset Tables, locale switching, Smart Strings, and runtime localization workflows.

## When to Use
- Use for multi-language text support
- Use for locale-specific assets (images, audio)
- Use for runtime language switching
- Use for dynamic text with variables (Smart Strings)
- Use for right-to-left (RTL) language support

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  LOCALIZATION SYSTEM                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Locale →  String Table →  Entry → Localized Text           │
│   (en)     ("UI")         ("play_button") → "Play"          │
│   (ja)     ("UI")         ("play_button") → "プレイ"         │
│   (vi)     ("UI")         ("play_button") → "Chơi"          │
│                                                              │
│  Smart Strings: "You have {count} items"                     │
│  Asset Tables: Different sprites/audio per locale            │
└─────────────────────────────────────────────────────────────┘
```

## Best Practices
- ✅ Use String Tables for all user-facing text
- ✅ Use Smart Strings for dynamic content (`{count}` placeholders)
- ✅ Use Asset Tables for locale-specific images/audio
- ✅ Test with pseudolocalization to find layout issues
- ✅ Persist selected locale in PlayerPrefs
- ❌ **NEVER** hardcode user-facing strings
- ❌ **NEVER** assume text length (some languages are 2x longer)
- ❌ **NEVER** use string concatenation for localized sentences

## Few-Shot Examples

### Example 1: Runtime Locale Switching
**User**: "Let user change language at runtime."

**Agent**:
```csharp
using UnityEngine.Localization.Settings;

public class LanguageController : MonoBehaviour
{
    public async void SetLanguage(string localeCode)
    {
        var locales = LocalizationSettings.AvailableLocales.Locales;
        var target = locales.FirstOrDefault(l => l.Identifier.Code == localeCode);

        if (target != null)
        {
            LocalizationSettings.SelectedLocale = target;
            PlayerPrefs.SetString("selected_locale", localeCode);
            PlayerPrefs.Save();
            Debug.Log($"Language changed to: {target.name}");
        }
        else
        {
            Debug.LogWarning($"Locale '{localeCode}' not found");
        }
    }

    private async void Start()
    {
        await LocalizationSettings.InitializationOperation;

        string saved = PlayerPrefs.GetString("selected_locale", "en");
        SetLanguage(saved);
    }

    public List<string> GetAvailableLanguages()
    {
        return LocalizationSettings.AvailableLocales.Locales
            .Select(l => l.Identifier.Code)
            .ToList();
    }
}
```

### Example 2: Smart String with Variables
**User**: "Dynamic text like 'You collected 5 coins'."

**Agent**:
```csharp
using UnityEngine.Localization;
using UnityEngine.Localization.SmartFormat.PersistentVariables;

public class CoinUI : MonoBehaviour
{
    [SerializeField] private LocalizedString _coinText;
    [SerializeField] private TextMeshProUGUI _label;

    // String Table entry (Smart String):
    // en: "You collected {count} coins"
    // ja: "{count}枚のコインを集めました"

    private IntVariable _countVar;

    private void Awake()
    {
        _countVar = new IntVariable { Value = 0 };
        _coinText.Add("count", _countVar);
    }

    private void OnEnable()
    {
        _coinText.StringChanged += OnStringChanged;
    }

    private void OnDisable()
    {
        _coinText.StringChanged -= OnStringChanged;
    }

    public void UpdateCoins(int count)
    {
        _countVar.Value = count;
    }

    private void OnStringChanged(string value)
    {
        _label.text = value;
    }
}
```

### Example 3: Localized Asset Tables
**User**: "Different splash images per language."

**Agent**:
```csharp
using UnityEngine.Localization;
using UnityEngine.ResourceManagement.AsyncOperations;

public class LocalizedSplashScreen : MonoBehaviour
{
    [SerializeField] private LocalizedSprite _splashSprite;
    [SerializeField] private Image _splashImage;

    private void OnEnable()
    {
        _splashSprite.AssetChanged += OnSplashChanged;
    }

    private void OnDisable()
    {
        _splashSprite.AssetChanged -= OnSplashChanged;
    }

    private void OnSplashChanged(Sprite sprite)
    {
        _splashImage.sprite = sprite;
    }

    // In Asset Table "Textures":
    // Key: "splash_screen"
    // en → splash_en.png
    // ja → splash_ja.png
    // vi → splash_vi.png
}
```

## Related Skills
- `@ui-toolkit-modern` - UI text elements
- `@responsive-ui-design` - Layout for variable text lengths
- `@save-load-serialization` - Persisting locale preference
