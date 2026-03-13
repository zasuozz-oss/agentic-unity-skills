#!/bin/bash
# Update Unity Skills from upstream repository
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
SKILLS_DST="$PROJECT_DIR/.agents/skills/unity-skills"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Unity Skills — Update Workflow                        ║"
echo "║     Pull upstream → Check changes → Re-install            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if [ -z "$REPO_DIR" ] || [ ! -d "$REPO_DIR/global-config/skills" ]; then
    echo "❌ Error: Could not find antigravity-unity-skills repository"
    echo "   Expected at: $SCRIPT_REAL_PATH/.."
    exit 1
fi

# Step 1: Backup
if [ -d "$SKILLS_DST" ]; then
    BACKUP_DIR="$SKILLS_DST-backup-$(date +%Y%m%d-%H%M%S)"
    echo "📦 Step 1: Creating backup..."
    cp -r "$SKILLS_DST" "$BACKUP_DIR"
    echo "   ✓ Backup: $BACKUP_DIR"
    echo ""
else
    echo "📦 Step 1: No existing skills to backup"
    echo ""
fi

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
if [ -d "$SKILLS_DST" ]; then
    DIFF_FILE="/tmp/unity-skills-diff-$(date +%Y%m%d-%H%M%S).txt"
    diff -r "$SKILLS_DST/" "$REPO_DIR/global-config/skills/" > "$DIFF_FILE" 2>&1 || true

    if [ -s "$DIFF_FILE" ]; then
        CHANGED=$(grep -cE "^(Only in|diff)" "$DIFF_FILE" 2>/dev/null || echo "0")
        echo "   ✓ $CHANGED changes found"
        echo ""
    else
        echo "   ✓ Already up to date!"
        rm -f "$DIFF_FILE"
        exit 0
    fi
else
    echo "   ✓ Fresh install (no existing skills)"
    DIFF_FILE=""
    echo ""
fi

# Step 4: Choose action
echo "📝 Step 4: What to do?"
echo "   1. Update all skills (overwrite)"
if [ -n "$DIFF_FILE" ]; then
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
        if [ -n "$DIFF_FILE" ]; then
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
echo "   - Skills:   ✓ Updated"
if [ -n "$BACKUP_DIR" ]; then
echo "   - Backup:   $BACKUP_DIR"
fi
echo ""
echo "🔄 Rollback if needed:"
if [ -n "$BACKUP_DIR" ]; then
echo "   rm -rf $SKILLS_DST && cp -r $BACKUP_DIR $SKILLS_DST"
fi
echo ""
echo "✅ Done!"
