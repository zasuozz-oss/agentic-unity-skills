---
name: version-control-git
description: "Git workflow for Unity projects. Use this when the user needs .gitignore setup, LFS configuration, merge strategies for Unity files, branching workflows, or Git troubleshooting for Unity. Also trigger for: 'gitignore for Unity', 'Git LFS setup', 'merge conflict on scene', 'branching strategy', 'large repo size', or any question about version control in Unity projects — even if they don't say 'Git'."
---

# Version Control Git

## Overview
Setup and maintenance of robust Git workflows for Unity projects. Includes optimized `.gitignore` configuration, Git LFS (Large File Storage) for binary assets, and collaboration strategies.

## When to Use
- Use at project setup
- Use when binary assets (Texture, Audio) exceed 100MB
- Use when collaborating with teams
- Use when setting up CI/CD
- Use for branching and merging strategies

## Key Configurations

| File | Purpose |
|------|---------| 
| **.gitignore** | Excludes temp/generated files (Library, Temp, Logs) |
| **.gitattributes** | Defines LFS tracking (DLL, PNG, WAV, FBX) |
| **.gitmodules** | Manages submodules (Plugins) |

## Unity Git Best Practices
- ✅ **YAML Serialization**: Force Text in Project Settings → Editor → Asset Serialization
- ✅ **Visible Meta Files**: Project Settings → Version Control → Mode → Visible Meta Files
- ✅ **LFS**: Always track binary files with LFS to keep repo size manageable
- ✅ **Smart Merge**: Use `UnityYAMLMerge` for scene/prefab merges
- ❌ **NEVER** commit Library/ or Temp/ folders
- ❌ **NEVER** delete .meta files without deleting the corresponding asset
- ❌ **NEVER** push large binaries without LFS

## Few-Shot Examples

### Example 1: Unity .gitignore
**User**: "Generate gitignore for Unity."

**Agent**:
```gitignore
# Unity generated
/[Ll]ibrary/
/[Tt]emp/
/[Oo]bj/
/[Bb]uild/
/[Bb]uilds/
/[Ll]ogs/
/[Uu]ser[Ss]ettings/

# Visual Studio / Rider
.vs/
.idea/
*.csproj
*.sln
*.user
*.suo

# OS generated
.DS_Store
Thumbs.db
```

### Example 2: .gitattributes (LFS)
**User**: "Setup LFS for textures and models."

**Agent**:
```gitattributes
# Image formats
*.jpg filter=lfs diff=lfs merge=lfs -text
*.jpeg filter=lfs diff=lfs merge=lfs -text
*.png filter=lfs diff=lfs merge=lfs -text
*.psd filter=lfs diff=lfs merge=lfs -text
*.tga filter=lfs diff=lfs merge=lfs -text

# Audio formats
*.wav filter=lfs diff=lfs merge=lfs -text
*.mp3 filter=lfs diff=lfs merge=lfs -text
*.ogg filter=lfs diff=lfs merge=lfs -text

# 3D formats
*.fbx filter=lfs diff=lfs merge=lfs -text
*.obj filter=lfs diff=lfs merge=lfs -text
*.blend filter=lfs diff=lfs merge=lfs -text

# Unity binaries
*.unitypackage filter=lfs diff=lfs merge=lfs -text
*.dll filter=lfs diff=lfs merge=lfs -text
```

### Example 3: Scene Merge Configuration
**User**: "How to merge Unity scene files?"

**Agent**:
```yaml
# .gitconfig or project-level config
# Add Unity's SmartMerge tool for .unity and .prefab files:

# Global Git config (~/.gitconfig):
[mergetool "unityyamlmerge"]
    trustExitCode = false
    cmd = '/Applications/Unity/Unity.app/Contents/Tools/UnityYAMLMerge' merge -p "$BASE" "$REMOTE" "$LOCAL" "$MERGED"

# .gitattributes additions:
*.unity merge=unityyamlmerge
*.prefab merge=unityyamlmerge
*.asset merge=unityyamlmerge

# Best practice: avoid editing the same scene simultaneously.
# Use scene separation to minimize conflicts.
```

## Related Skills
- `@build-pipeline-manager` - CI/CD setup
- `@unity-mcp-connector` - Editor integration
