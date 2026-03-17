#!/bin/bash
# Update Skills from upstream repository
# Pulls latest from the antigravity-unity-skills repo, checks for changes,
# and re-installs to the current project.
# Usage: bash scripts/update-unity-skills.sh [project-path]

set -e

# Auto-detect repo location
SCRIPT_REAL_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR=""
if [ -f "$SCRIPT_REAL_PATH/../package.json" ]; then
    REPO_DIR="$(cd "$SCRIPT_REAL_PATH/.." && pwd)"
elif [ -d "$HOME/AI-Tool/antigravity-unity-skills/global-config" ]; then
    REPO_DIR="$HOME/AI-Tool/antigravity-unity-skills"
fi

PROJECT_DIR="${1:-$(pwd)}"
SKILLS_DIR="$PROJECT_DIR/.agents/skills"
MANIFEST_FILE="$SKILLS_DIR/.ag-manifest.json"

# Source groups to check
SOURCE_GROUPS=("unity-skills" "qa-skills")

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     AG Skills — Update Workflow                            ║"
echo "║     Pull upstream → Check changes → Re-install            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if [ -z "$REPO_DIR" ] || [ ! -d "$REPO_DIR/global-config/skills" ]; then
    echo "❌ Error: Could not find antigravity-unity-skills repository"
    echo "   Expected at: $SCRIPT_REAL_PATH/.."
    exit 1
fi

# Step 1: Backup
echo "📦 Step 1: Creating backup..."
if [ -f "$MANIFEST_FILE" ]; then
    BACKUP_DIR="$SKILLS_DIR-backup-$(date +%Y%m%d-%H%M%S)"
    cp -r "$SKILLS_DIR" "$BACKUP_DIR"
    echo "   ✓ Skills backed up → $BACKUP_DIR"
else
    BACKUP_DIR=""
    echo "   - No existing manifest, skipping backup"
fi
echo ""

# Step 2: Pull latest from git
echo "🔄 Step 2: Pulling latest from repository..."
cd "$REPO_DIR"
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
    git pull origin "$CURRENT_BRANCH" 2>/dev/null || echo "   ⚠️  Could not pull (offline or no remote)"
    echo "   ✓ Repository updated"
else
    echo "   ⚠️  Not a git repository, skipping pull"
fi
echo ""

# Step 3: Check for changes
echo "🔍 Step 3: Checking for updates..."
DIFF_FILE="/tmp/ag-skills-diff-$(date +%Y%m%d-%H%M%S).txt"
HAS_CHANGES=false

for group in "${SOURCE_GROUPS[@]}"; do
    GROUP_SRC="$REPO_DIR/global-config/skills/$group"
    if [ -d "$GROUP_SRC" ]; then
        # Compare each skill folder directly against flat .agents/skills/<skill>/
        for skill_dir in "$GROUP_SRC"/*/; do
            if [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ]; then
                SKILL_NAME=$(basename "$skill_dir")
                INSTALLED_SKILL="$SKILLS_DIR/$SKILL_NAME"
                if [ -d "$INSTALLED_SKILL" ]; then
                    diff -r "$INSTALLED_SKILL/" "$skill_dir" >> "$DIFF_FILE" 2>&1 || true
                else
                    echo "Only in source: $group/$SKILL_NAME" >> "$DIFF_FILE"
                fi
            fi
        done
    fi
done

if [ -s "$DIFF_FILE" ]; then
    CHANGED=$(grep -cE "^(Only in|diff)" "$DIFF_FILE" 2>/dev/null || echo "0")
    echo "   ✓ $CHANGED changes found"
    HAS_CHANGES=true
    echo ""
else
    echo "   ✓ Already up to date!"
    rm -f "$DIFF_FILE"
    exit 0
fi

# Step 4: Choose action
echo "📝 Step 4: What to do?"
echo "   1. Update all skills (overwrite)"
if [ "$HAS_CHANGES" = true ]; then
echo "   2. Show diff only"
fi
echo "   3. Cancel"
echo ""
read -p "Choose (1-3): " option

case $option in
    1)
        echo ""
        echo "📚 Installing skills..."
        cd "$PROJECT_DIR"
        node "$REPO_DIR/bin/cli.mjs"
        ;;
    2)
        if [ "$HAS_CHANGES" = true ]; then
            echo ""
            cat "$DIFF_FILE"
            echo ""
            echo "Diff saved: $DIFF_FILE"
        else
            echo "   No diff available (fresh install)"
        fi
        exit 0
        ;;
    3)
        echo "   Cancelled"
        exit 0
        ;;
    *)
        echo "   Invalid option"
        exit 1
        ;;
esac

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Update Complete                                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Summary:"
echo "   - Project:  $PROJECT_DIR"
echo "   - Skills:   .agents/skills/ (flat structure)"
if [ -n "$BACKUP_DIR" ]; then
echo ""
echo "🔄 Rollback if needed:"
echo "   rm -rf $SKILLS_DIR && cp -r $BACKUP_DIR $SKILLS_DIR"
fi
echo ""
echo "✅ Done!"
