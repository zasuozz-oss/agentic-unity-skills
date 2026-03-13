#!/bin/bash
# Setup Unity Skills for current project
# Usage: bash /path/to/antigravity-unity-skills/setup-project.sh
#
# Installs Unity skills into the current project's .agents/skills-unity/ directory
# and updates the project's GEMINI.md with skill references.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR=$(pwd)
SKILLS_SRC="$SCRIPT_DIR/global-config/skills"
SKILLS_DST="$PROJECT_DIR/.agents/skills-unity"
GEMINI_MD="$PROJECT_DIR/GEMINI.md"

# Block markers for detect/replace
BLOCK_START="<!-- BEGIN antigravity-unity-skills -->"
BLOCK_END="<!-- END antigravity-unity-skills -->"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Unity Skills — Project Setup                          ║"
echo "║     Install 70 Unity skills into current project          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if source exists
if [ ! -d "$SKILLS_SRC" ]; then
    echo "❌ Error: global-config/skills/ not found"
    echo "   Make sure the script path is correct"
    exit 1
fi

# Step 1: Install skills
echo "📚 Step 1: Installing Unity skills..."
mkdir -p "$SKILLS_DST"

if [ -d "$SKILLS_DST" ] && [ "$(ls -A "$SKILLS_DST" 2>/dev/null)" ]; then
    echo "   ⚠️  Existing skills found, updating..."
    rm -rf "$SKILLS_DST"
fi

cp -r "$SKILLS_SRC" "$SKILLS_DST"
SKILL_COUNT=$(find "$SKILLS_DST" -name "SKILL.md" -type f | wc -l | tr -d ' ')
echo "   ✓ $SKILL_COUNT skills installed to .agents/skills-unity/"
echo ""

# Step 2: Update GEMINI.md (block-based, non-destructive)
echo "📝 Step 2: Updating project GEMINI.md..."

UNITY_BLOCK="$BLOCK_START
@.agents/skills-unity/INDEX.md
$BLOCK_END"

if [ -f "$GEMINI_MD" ]; then
    if grep -q "$BLOCK_START" "$GEMINI_MD" 2>/dev/null; then
        # Replace existing block — use awk to skip old content, then print new block
        awk -v start="$BLOCK_START" -v end="$BLOCK_END" '
            $0 == start {
                print start
                print "@.agents/skills-unity/INDEX.md"
                print end
                skip=1; next
            }
            $0 == end { skip=0; next }
            !skip { print }
        ' "$GEMINI_MD" > "$GEMINI_MD.tmp"
        mv "$GEMINI_MD.tmp" "$GEMINI_MD"
        echo "   ✓ Updated existing block in: GEMINI.md"
    else
        # Append block to existing file
        echo "" >> "$GEMINI_MD"
        echo "$UNITY_BLOCK" >> "$GEMINI_MD"
        echo "   ✓ Appended block to: GEMINI.md"
    fi
else
    # Create new file with block
    echo "$UNITY_BLOCK" > "$GEMINI_MD"
    echo "   ✓ Created: GEMINI.md"
fi
echo ""

# Step 3: Verify
echo "✅ Step 3: Verification..."
echo "   Skills:    $SKILL_COUNT"
echo "   Location:  .agents/skills-unity/"
echo "   GEMINI.md: ✓"
echo ""

# Summary
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Setup Complete                                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Summary:"
echo "   - Project:  $PROJECT_DIR"
echo "   - Skills:   $SKILL_COUNT Unity skills installed"
echo "   - Config:   GEMINI.md updated"
echo ""
echo "🚀 Next steps:"
echo "   1. Open Antigravity in this project"
echo "   2. Unity skills auto-load via GEMINI.md"
echo ""
echo "✅ Done!"
