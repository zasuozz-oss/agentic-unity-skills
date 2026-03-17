---
name: asset-import-pipeline
description: "Unity asset import configuration specialist. Use this when the user needs texture import settings, model import optimization, audio compression, or asset post-processor scripts. Also trigger for: 'texture too large', 'model import settings', 'audio compression', 'asset postprocessor', 'import preset', or any question about how assets are imported into Unity — even if they don't say 'import pipeline'. Do NOT use for runtime asset loading — use addressables-asset-management instead."
---

# Asset Import Pipeline

## Overview
Optimize imported assets (Textures, Models, Audio) with correct import settings and automated post-processors. Critical for build size and runtime memory.

## When to Use
- Use when setting up texture compression per platform
- Use when importing 3D models (FBX)
- Use when audio clips are too large
- Use when automating import settings with AssetPostprocessor
- Use when build size is too large

## Texture Import Guidelines

| Platform | Format | Alpha | Max Size |
|----------|:------:|:-----:|:--------:|
| **Android** | ASTC 6x6 | ASTC 4x4 | 1024-2048 |
| **iOS** | ASTC 6x6 | ASTC 4x4 | 1024-2048 |
| **PC** | BC7 / DXT5 | BC7 | 2048-4096 |
| **WebGL** | ETC2 | ETC2 | 512-1024 |

## Audio Import Guidelines

| Type | Load Type | Compression |
|------|-----------|:-----------:|
| **SFX (short)** | Decompress On Load | Vorbis 70% |
| **Music (long)** | Streaming | Vorbis 50% |
| **UI clicks** | Decompress On Load | PCM |
| **Ambient loops** | Compressed In Memory | Vorbis 60% |

## Best Practices
- ✅ Use platform-specific overrides for textures
- ✅ Disable unused import features (Read/Write, mipmaps for UI)
- ✅ Use AssetPostprocessor for team-wide consistency
- ✅ Compress audio appropriate to use case
- ❌ **NEVER** enable Read/Write on textures unless needed
- ❌ **NEVER** import models with unused animations or materials
- ❌ **NEVER** use uncompressed audio in builds

## Few-Shot Examples

### Example 1: Texture Import Automator
**User**: "Auto-set texture import settings for mobile."

**Agent**:
```csharp
public class TextureImportAutomator : AssetPostprocessor
{
    private void OnPreprocessTexture()
    {
        var importer = (TextureImporter)assetImporter;

        // UI textures (in UI folder)
        if (assetPath.Contains("/UI/"))
        {
            importer.textureType = TextureImporterType.Sprite;
            importer.mipmapEnabled = false;  // UI doesn't need mipmaps
            importer.isReadable = false;
            importer.maxTextureSize = 1024;

            var android = importer.GetPlatformTextureSettings("Android");
            android.overridden = true;
            android.format = TextureImporterFormat.ASTC_4x4;
            android.maxTextureSize = 1024;
            importer.SetPlatformTextureSettings(android);
        }
        // 3D textures (in Models or Textures folder)
        else if (assetPath.Contains("/Textures/") || assetPath.Contains("/Models/"))
        {
            importer.textureType = TextureImporterType.Default;
            importer.mipmapEnabled = true;
            importer.isReadable = false;
            importer.maxTextureSize = 2048;

            var android = importer.GetPlatformTextureSettings("Android");
            android.overridden = true;
            android.format = TextureImporterFormat.ASTC_6x6;
            android.maxTextureSize = 2048;
            importer.SetPlatformTextureSettings(android);
        }
    }
}
```

### Example 2: Model Import Cleanup
**User**: "Strip unnecessary data from FBX imports."

**Agent**:
```csharp
public class ModelImportCleaner : AssetPostprocessor
{
    private void OnPreprocessModel()
    {
        var importer = (ModelImporter)assetImporter;

        // Disable unused features
        importer.importCameras = false;
        importer.importLights = false;
        importer.importVisibility = false;
        importer.isReadable = false; // Save memory

        // Materials: use existing or extract
        importer.materialImportMode = ModelImporterMaterialImportMode.None;

        // If no animations expected
        if (!assetPath.Contains("/Animated/"))
        {
            importer.animationType = ModelImporterAnimationType.None;
            importer.importAnimation = false;
        }
        else
        {
            importer.animationType = ModelImporterAnimationType.Generic;
            importer.animationCompression =
                ModelImporterAnimationCompression.Optimal;
        }
    }
}
```

### Example 3: Audio Import Optimizer
**User**: "Set correct compression for SFX vs music."

**Agent**:
```csharp
public class AudioImportOptimizer : AssetPostprocessor
{
    private void OnPreprocessAudio()
    {
        var importer = (AudioImporter)assetImporter;

        // Short SFX: decompress for low latency
        if (assetPath.Contains("/SFX/"))
        {
            var settings = importer.defaultSampleSettings;
            settings.loadType = AudioClipLoadType.DecompressOnLoad;
            settings.compressionFormat = AudioCompressionFormat.Vorbis;
            settings.quality = 0.7f;
            settings.sampleRateSetting = AudioSampleRateSetting.OptimizeSampleRate;
            importer.defaultSampleSettings = settings;
        }
        // Music: stream to save memory
        else if (assetPath.Contains("/Music/"))
        {
            var settings = importer.defaultSampleSettings;
            settings.loadType = AudioClipLoadType.Streaming;
            settings.compressionFormat = AudioCompressionFormat.Vorbis;
            settings.quality = 0.5f;
            importer.defaultSampleSettings = settings;
        }

        // Always mono for non-music
        if (!assetPath.Contains("/Music/"))
        {
            importer.forceToMono = true;
        }
    }
}
```

## Related Skills
- `@addressables-asset-management` - Runtime asset loading
- `@mobile-optimization` - Platform-specific settings
- `@memory-profiler-expert` - Asset memory tracking
