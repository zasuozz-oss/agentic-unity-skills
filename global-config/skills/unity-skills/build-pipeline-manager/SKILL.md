---
name: build-pipeline-manager
description: "Unity build pipeline and CI/CD specialist. Use this when the user needs build automation, platform-specific build settings, CI/CD configuration, build scripts, or addressable build pipeline setup. Also trigger for: 'automate builds', 'build for Android', 'CI/CD Unity', 'build script', 'platform switching', or any question about building and deploying Unity projects — even if they don't say 'build pipeline'."
---

# Build Pipeline Manager

## Overview
Automate Unity builds for multiple platforms. Covers build scripts, platform configurations, CI/CD integration, and addressable content builds.

## When to Use
- Use when setting up automated builds
- Use when configuring multi-platform builds
- Use when creating CI/CD pipelines (GitHub Actions, GitLab CI)
- Use when build times need optimization
- Use when managing build variants (dev, staging, prod)

## Build Configuration Matrix

| Platform | Scripting Backend | Architecture | Notes |
|----------|:-----------------:|:------------:|-------|
| **Android** | IL2CPP | ARM64 | Min API 24 |
| **iOS** | IL2CPP | ARM64 | Xcode required |
| **Windows** | Mono / IL2CPP | x64 | |
| **WebGL** | IL2CPP | WASM | No threads |
| **macOS** | Mono / IL2CPP | Apple Silicon + Intel | Universal |

## Best Practices
- ✅ Use BuildPlayerOptions for reproducible builds
- ✅ Separate build config from build script
- ✅ Use scripting defines for build variants
- ✅ Cache Library/ folder in CI for faster builds
- ❌ **NEVER** build from Unity UI for release (use scripts)
- ❌ **NEVER** skip Addressables build before player build
- ❌ **NEVER** use Development Build for store releases

## Few-Shot Examples

### Example 1: Automated Build Script
**User**: "Create a build script for Android and iOS."

**Agent**:
```csharp
public static class BuildScript
{
    [MenuItem("Build/Android — Release")]
    public static void BuildAndroid()
    {
        var options = new BuildPlayerOptions
        {
            scenes = GetEnabledScenes(),
            locationPathName = "Builds/Android/game.apk",
            target = BuildTarget.Android,
            options = BuildOptions.CompressWithLz4HC
        };

        PlayerSettings.Android.bundleVersionCode++;
        PlayerSettings.SetScriptingBackend(
            BuildTargetGroup.Android, ScriptingImplementation.IL2CPP);
        PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;

        var report = BuildPipeline.BuildPlayer(options);
        if (report.summary.result != BuildResult.Succeeded)
            throw new Exception($"Build failed: {report.summary.totalErrors} errors");

        Debug.Log($"Build succeeded: {report.summary.outputPath}");
    }

    private static string[] GetEnabledScenes()
    {
        return EditorBuildSettings.scenes
            .Where(s => s.enabled)
            .Select(s => s.path)
            .ToArray();
    }
}
```

### Example 2: GitHub Actions CI
**User**: "Set up GitHub Actions for Unity builds."

**Agent**:
```yaml
# .github/workflows/unity-build.yml
name: Unity Build
on:
  push:
    branches: [main, develop]

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        targetPlatform: [Android, iOS, StandaloneWindows64]
    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true

      - uses: actions/cache@v3
        with:
          path: Library
          key: Library-${{ matrix.targetPlatform }}-${{ hashFiles('Assets/**', 'Packages/**') }}

      - uses: game-ci/unity-builder@v4
        env:
          UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}
        with:
          targetPlatform: ${{ matrix.targetPlatform }}
          buildMethod: BuildScript.Build

      - uses: actions/upload-artifact@v4
        with:
          name: Build-${{ matrix.targetPlatform }}
          path: build
```

### Example 3: Pre-Build Validation
**User**: "Validate settings before building."

**Agent**:
```csharp
public static class PreBuildValidator
{
    [MenuItem("Build/Validate Settings")]
    public static bool Validate()
    {
        bool valid = true;

        // Check scenes
        var scenes = EditorBuildSettings.scenes.Where(s => s.enabled).ToArray();
        if (scenes.Length == 0)
        {
            Debug.LogError("[Build] No scenes in Build Settings!");
            valid = false;
        }

        // Check bundle identifier
        if (string.IsNullOrEmpty(PlayerSettings.applicationIdentifier))
        {
            Debug.LogError("[Build] Bundle identifier not set!");
            valid = false;
        }

        // Check scripting backend
        var backend = PlayerSettings.GetScriptingBackend(
            EditorUserBuildSettings.selectedBuildTargetGroup);
        if (backend != ScriptingImplementation.IL2CPP)
        {
            Debug.LogWarning("[Build] Using Mono instead of IL2CPP — not recommended for release");
        }

        // Check for Debug.Log calls in non-editor code
        // (would need a custom analyzer, just flag the concern)
        Debug.Log(valid ? "[Build] All checks passed ✅" : "[Build] Issues found ❌");
        return valid;
    }
}
```

## Related Skills
- `@version-control-git` - Git workflow for CI/CD
- `@addressables-asset-management` - Content build pipeline
- `@mobile-optimization` - Platform-specific settings
