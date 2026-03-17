---
name: di-container-manager
description: "Dependency injection in Unity using VContainer or Zenject. Use this when the user needs DI setup, service registration, constructor injection, lifetime management, or wants to reduce tight coupling. Also trigger for: 'how to avoid singletons', 'inject dependencies', 'VContainer setup', 'Zenject binding', 'loose coupling without statics', or any question about DI containers in Unity — even if they don't say 'dependency injection'. Do NOT use for simple Service Locator pattern — use architecture-advisor instead."
---

# DI Container Manager

## Overview
Dependency Injection (DI) in Unity for loose coupling and testability. Covers VContainer (recommended — lightweight) and Zenject/Extenject.

## When to Use
- Use when multiple systems depend on shared services
- Use when you want to avoid singleton globals
- Use when testability (mock injection) is important
- Use when project has 5+ interacting systems
- Use when team size > 3 developers

## DI Concepts

| Concept | Description |
|---------|-------------|
| **Registration** | Tell the container how to create objects |
| **Resolution** | Container creates/provides objects |
| **Lifetime** | Singleton, Transient, or Scoped |
| **Injection** | Constructor, field `[Inject]`, or method |

## Container Comparison

| Feature | VContainer | Zenject |
|---------|:----------:|:-------:|
| Performance | ✅ Fast | ⚠️ Slower |
| Bundle Size | Small | Large |
| Source Gen | ✅ | ❌ |
| Learning Curve | Moderate | Steep |
| Community | Growing | Established |

## Best Practices
- ✅ Prefer constructor injection over field injection
- ✅ Register interfaces, not concrete types
- ✅ Use `Lifetime.Singleton` for managers, `Transient` for data
- ✅ Keep the installer/scope focused
- ❌ **NEVER** inject into MonoBehaviour constructors (use `[Inject]` or method injection)
- ❌ **NEVER** register everything as Singleton
- ❌ **NEVER** use the container as a Service Locator (`container.Resolve<T>()`)

## Few-Shot Examples

### Example 1: VContainer Setup
**User**: "Set up DI with VContainer."

**Agent**:
```csharp
// LifetimeScope — the installer
public class GameLifetimeScope : LifetimeScope
{
    [SerializeField] private GameConfigSO _gameConfig;

    protected override void Configure(IContainerBuilder builder)
    {
        // Register services
        builder.Register<IScoreService, ScoreService>(Lifetime.Singleton);
        builder.Register<IAudioService, AudioService>(Lifetime.Singleton);
        builder.Register<ISaveService, FileSaveService>(Lifetime.Singleton);

        // Register SO config as instance
        builder.RegisterInstance(_gameConfig);

        // Register MonoBehaviour in scene
        builder.RegisterComponentInHierarchy<PlayerController>();
    }
}

// Service with constructor injection (preferred)
public class ScoreService : IScoreService
{
    private readonly ISaveService _saveService;
    private int _score;

    public ScoreService(ISaveService saveService)
    {
        _saveService = saveService;
    }

    public void AddScore(int points)
    {
        _score += points;
        _saveService.SaveInt("score", _score);
    }
}
```

### Example 2: MonoBehaviour Injection
**User**: "Inject services into a MonoBehaviour."

**Agent**:
```csharp
// MonoBehaviour — use [Inject] method (NOT constructor)
public class PlayerHUD : MonoBehaviour
{
    [SerializeField] private TextMeshProUGUI _scoreText;

    private IScoreService _scoreService;

    [Inject]
    public void Construct(IScoreService scoreService)
    {
        _scoreService = scoreService;
    }

    private void OnEnable()
    {
        _scoreService.OnScoreChanged += UpdateScore;
    }

    private void OnDisable()
    {
        _scoreService.OnScoreChanged -= UpdateScore;
    }

    private void UpdateScore(int score)
    {
        _scoreText.text = score.ToString();
    }
}
```

### Example 3: Scoped Lifetime (Per-Scene)
**User**: "How to have different DI registrations per scene?"

**Agent**:
```csharp
// Root scope — persists across scenes
public class RootLifetimeScope : LifetimeScope
{
    protected override void Configure(IContainerBuilder builder)
    {
        // Global singletons
        builder.Register<IAudioService, AudioService>(Lifetime.Singleton);
        builder.Register<ISaveService, FileSaveService>(Lifetime.Singleton);
    }
}

// Scene scope — inherits from root, adds scene-specific services
public class GameplayLifetimeScope : LifetimeScope
{
    protected override void Configure(IContainerBuilder builder)
    {
        // Scene-specific (disposed on scene unload)
        builder.Register<IEnemySpawner, EnemySpawner>(Lifetime.Scoped);
        builder.Register<IWaveManager, WaveManager>(Lifetime.Scoped);

        // MonoBehaviours in this scene
        builder.RegisterComponentInHierarchy<PlayerController>();
    }
}
```

## Related Skills
- `@architecture-advisor` - When to use DI vs simpler patterns
- `@interface-driven-development` - Interface design for DI
- `@testability-advisor` - Mock injection for testing
