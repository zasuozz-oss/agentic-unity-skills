#!/bin/bash
# Update Unity Skills in current project from source repo
# Usage: bash scripts/update-unity-skills.sh [project-path]
#
# Updates the Unity skills in a project by pulling latest from the repo
# and re-running the setup.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="${1:-$(pwd)}"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Unity Skills — Update                                 ║"
echo "║     Pull latest and re-install to project                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Pull latest
echo "📥 Step 1: Pulling latest from repository..."
cd "$REPO_DIR"
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    git pull origin "$(git branch --show-current)" 2>/dev/null || echo "   ⚠️  Could not pull (offline or no remote)"
    echo "   ✓ Repository updated"
else
    echo "   ⚠️  Not a git repository, skipping pull"
fi
echo ""

# Step 2: Re-install to project
echo "📦 Step 2: Re-installing to project..."
cd "$PROJECT_DIR"
bash "$REPO_DIR/setup-project.sh"
