---
name: asset-import-pipeline
description: "Asset import automation and configuration. Use this skill whenever the user mentions texture compression, FBX import settings, asset postprocessor, mobile optimization for assets, or naming convention enforcement. Also trigger for: 'textures too large', 'materials messing up on import', 'how to automate import settings', 'batch configure assets', or any Unity asset pipeline customization."
---

# Asset Import Pipeline

## Overview
Acts as a "gatekeeper" for the project. Automatically applies compression settings, naming conventions, and validation rules when assets are imported. Prevents "4K Texture Bloat" and ensures mobile compatibility.

## When to Use
- Use to enforce "Android/iOS" compression standards automatically.
- Use to disable "Import Materials" on FBX files (prevent mess).
- Use to force "Mono" on 3D sound effects.
- Use to validate asset naming conventions.
- Use to detect duplicates.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   IMPORT PIPELINE                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  FILE SYSTEM              ASSET POSTPROCESSOR (Editor)      │
│  ┌────────────────┐      ┌───────────────────────────┐      │
│  │ "Hero.fbx"     │─────▶│ OnPreprocessModel()       │      │
│  │ "Grass.png"    │      │ - Scale Factor: 1.0       │      │
│  └────────────────┘      │ - Import Materials: False │      │
│                          └─────────────┬─────────────┘      │
│                                        │                    │
│                                        ▼                    │
│                           ┌───────────────────────────┐     │
│                           │ OnPostprocessTexture()    │     │
│                           │ - Android: ASTC 6x6       │     │
│                           │ - iOS: ASTC 6x6           │     │
│                           │ - PC: BC7                 │     │
│                           └───────────────────────────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Best Practices
- ✅ Segregate rules by folder (e.g., `_UI/` vs `_3D/`).
- ✅ Use `AssetPostprocessor` (native Unity API).
- ✅ Detect Normal Maps by suffix (`_Normal`, `_N`) and set TextureType automatically.
- ✅ Log warnings if an asset exceeds size limits (e.g., > 2048px).
- ❌ **NEVER** modify source assets; only import settings.
- ❌ **NEVER** apply heavy compression to UI sprites (artifacts).

## Few-Shot Examples

### Example 1: Texture Rules
**User**: "Compress all textures for mobile."

**Agent**:
```csharp
void OnPreprocessTexture()
{
    TextureImporter importer = (TextureImporter)assetImporter;
    importer.textureCompression = TextureImporterCompression.Compressed;

    var androidOverride = new TextureImporterPlatformSettings
    {
        name = "Android",
        overridden = true,
        format = TextureImporterFormat.ASTC_6x6,
        maxTextureSize = 1024
    };
    importer.SetPlatformTextureSettings(androidOverride);

    var iosOverride = new TextureImporterPlatformSettings
    {
        name = "iPhone",
        overridden = true,
        format = TextureImporterFormat.ASTC_6x6,
        maxTextureSize = 1024
    };
    importer.SetPlatformTextureSettings(iosOverride);
}
```

### Example 2: Model Cleanup
**User**: "Don't import materials from FBX."

**Agent**:
```csharp
void OnPreprocessModel()
{
    ModelImporter modelImporter = (ModelImporter)assetImporter;
    modelImporter.materialImportMode = ModelImporterMaterialImportMode.None;
}

### Example 3: Naming Convention Validation
**User**: "Enforce texture naming prefix T_ automatically."

**Agent**:
```csharp
public class AssetNamingValidator : AssetPostprocessor
{
    static void OnPostprocessAllAssets(
        string[] importedAssets, string[] deletedAssets,
        string[] movedAssets, string[] movedFromAssetPaths)
    {
        foreach (var path in importedAssets)
        {
            var fileName = Path.GetFileNameWithoutExtension(path);
            if (path.Contains("/Textures/") && !fileName.StartsWith("T_"))
                Debug.LogWarning($"[NamingConvention] Texture should start with 'T_': {path}");
        }
    }
}
```

## Related Skills
- `@mobile-optimization` - Defines the compression standards
- `@custom-editor-scripting` - Editor API
