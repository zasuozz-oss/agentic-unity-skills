#!/bin/bash
# Automated test runner for Unity Skills setup
# Usage: bash tests/run-tests.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0
TOTAL=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

assert() {
    TOTAL=$((TOTAL + 1))
    local desc="$1"
    local cmd="$2"
    if eval "$cmd" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $desc"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}✗${NC} $desc"
        FAIL=$((FAIL + 1))
    fi
}

# Use a temp project directory to avoid side effects
TEST_PROJECT=$(mktemp -d)

cleanup() {
    rm -rf "$TEST_PROJECT"
}
trap cleanup EXIT

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Unity Skills — Automated Test Suite                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ─── TC-01: Fresh Install ───────────────────────────────────
echo -e "${YELLOW}TC-01: Fresh Install${NC}"
cd "$TEST_PROJECT"
node "$SCRIPT_DIR/bin/cli.mjs" > /dev/null 2>&1

assert "Skills directory exists" "[ -d '$TEST_PROJECT/.agents/skills-unity' ]"
assert "INDEX.md present" "[ -f '$TEST_PROJECT/.agents/skills-unity/INDEX.md' ]"
assert "unity_context.md copied" "[ -f '$TEST_PROJECT/.agents/unity_context.md' ]"
assert "GEMINI.md exists" "[ -f '$TEST_PROJECT/GEMINI.md' ]"

# Count SKILL.md files
SKILL_COUNT=$(find "$TEST_PROJECT/.agents/skills-unity" -name "SKILL.md" -type f | wc -l | tr -d ' ')
assert "Skills installed ($SKILL_COUNT found, expect 60+)" "[ $SKILL_COUNT -ge 60 ]"

# Count category directories
CAT_COUNT=$(ls -1d "$TEST_PROJECT/.agents/skills-unity"/*/ 2>/dev/null | wc -l | tr -d ' ')
assert "Category directories exist ($CAT_COUNT)" "[ $CAT_COUNT -ge 8 ]"
echo ""

# ─── TC-02: GEMINI.md Content ────────────────────────────────
echo -e "${YELLOW}TC-02: GEMINI.md Content${NC}"
GEMINI_FILE="$TEST_PROJECT/GEMINI.md"

assert "Contains BEGIN marker" "grep -q 'BEGIN antigravity-unity-skills' '$GEMINI_FILE'"
assert "Contains END marker" "grep -q 'END antigravity-unity-skills' '$GEMINI_FILE'"
assert "References unity_context.md" "grep -q '@.agents/unity_context.md' '$GEMINI_FILE'"
assert "unity_context.md has INDEX ref" "grep -q '@.agents/skills-unity/INDEX.md' '$TEST_PROJECT/.agents/unity_context.md'"
assert "unity_context.md has rules" "grep -q 'Mandatory Unity Skill Usage' '$TEST_PROJECT/.agents/unity_context.md'"

# Count block occurrences
BEGIN_COUNT=$(grep -c 'BEGIN antigravity-unity-skills' "$GEMINI_FILE")
assert "Only 1 BEGIN marker ($BEGIN_COUNT)" "[ $BEGIN_COUNT -eq 1 ]"
echo ""

# ─── TC-03: Idempotent (No Duplication) ─────────────────────
echo -e "${YELLOW}TC-03: Idempotent — No Duplication${NC}"
LINES_BEFORE=$(wc -l < "$GEMINI_FILE")
MD5_BEFORE=$(md5 -q "$GEMINI_FILE" 2>/dev/null || md5sum "$GEMINI_FILE" | cut -d' ' -f1)

cd "$TEST_PROJECT"
node "$SCRIPT_DIR/bin/cli.mjs" > /dev/null 2>&1

LINES_AFTER=$(wc -l < "$GEMINI_FILE")
MD5_AFTER=$(md5 -q "$GEMINI_FILE" 2>/dev/null || md5sum "$GEMINI_FILE" | cut -d' ' -f1)

assert "Line count unchanged ($LINES_BEFORE → $LINES_AFTER)" "[ '$LINES_BEFORE' = '$LINES_AFTER' ]"
assert "MD5 unchanged" "[ '$MD5_BEFORE' = '$MD5_AFTER' ]"

# Third run
cd "$TEST_PROJECT"
node "$SCRIPT_DIR/bin/cli.mjs" > /dev/null 2>&1
MD5_THIRD=$(md5 -q "$GEMINI_FILE" 2>/dev/null || md5sum "$GEMINI_FILE" | cut -d' ' -f1)
assert "MD5 unchanged after 3rd run" "[ '$MD5_BEFORE' = '$MD5_THIRD' ]"
echo ""

# ─── TC-04: Existing GEMINI.md — Append Block ────────────────
echo -e "${YELLOW}TC-04: Existing GEMINI.md — Append Block${NC}"
TEST_PROJECT2=$(mktemp -d)
echo "# My Project" > "$TEST_PROJECT2/GEMINI.md"
echo "" >> "$TEST_PROJECT2/GEMINI.md"
echo "Some existing content here." >> "$TEST_PROJECT2/GEMINI.md"

cd "$TEST_PROJECT2"
node "$SCRIPT_DIR/bin/cli.mjs" > /dev/null 2>&1

assert "Original content preserved" "grep -q 'My Project' '$TEST_PROJECT2/GEMINI.md'"
assert "Original body preserved" "grep -q 'Some existing content here' '$TEST_PROJECT2/GEMINI.md'"
assert "Unity block appended" "grep -q 'BEGIN antigravity-unity-skills' '$TEST_PROJECT2/GEMINI.md'"

# Only 1 block
BEGIN_COUNT2=$(grep -c 'BEGIN antigravity-unity-skills' "$TEST_PROJECT2/GEMINI.md")
assert "Only 1 BEGIN marker ($BEGIN_COUNT2)" "[ $BEGIN_COUNT2 -eq 1 ]"

rm -rf "$TEST_PROJECT2"
echo ""

# ─── TC-05: Backup Created ──────────────────────────────────
echo -e "${YELLOW}TC-05: Backup on Re-install${NC}"
# Skills already exist from TC-01, re-run should create backup
cd "$TEST_PROJECT"
node "$SCRIPT_DIR/bin/cli.mjs" > /dev/null 2>&1

BACKUP_COUNT=$(ls -1d "$TEST_PROJECT/.agents/skills-unity-backup-"* 2>/dev/null | wc -l | tr -d ' ')
assert "Backup directory created ($BACKUP_COUNT)" "[ $BACKUP_COUNT -ge 1 ]"
if [ $BACKUP_COUNT -ge 1 ]; then
    BACKUP_ONE=$(ls -1d "$TEST_PROJECT/.agents/skills-unity-backup-"* 2>/dev/null | head -1)
    assert "Backup contains INDEX.md" "[ -f '$BACKUP_ONE/INDEX.md' ]"
fi
echo ""

# ─── TC-06: All Skills Have SKILL.md ─────────────────────────
echo -e "${YELLOW}TC-06: All Skills Have SKILL.md${NC}"
MISSING=0
for category in "$TEST_PROJECT/.agents/skills-unity"/*/; do
    CAT_NAME=$(basename "$category")
    if [ "$CAT_NAME" = "INDEX.md" ]; then continue; fi
    for skill_dir in "$category"*/; do
        if [ -d "$skill_dir" ]; then
            SKILL_NAME=$(basename "$skill_dir")
            if [ -f "$skill_dir/SKILL.md" ]; then
                assert "$CAT_NAME/$SKILL_NAME has SKILL.md" "true"
            else
                assert "$CAT_NAME/$SKILL_NAME has SKILL.md" "false"
                MISSING=$((MISSING + 1))
            fi
        fi
    done
done
echo ""

# ─── TC-07: Coexistence with Superpowers ─────────────────────
echo -e "${YELLOW}TC-07: Coexistence with Superpowers Block${NC}"
TEST_PROJECT3=$(mktemp -d)
cat > "$TEST_PROJECT3/GEMINI.md" << 'EOF'
<!-- BEGIN antigravity-superpowers -->
@~/.gemini/antigravity/skills/using-superpowers/SKILL.md
<!-- END antigravity-superpowers -->
EOF

cd "$TEST_PROJECT3"
node "$SCRIPT_DIR/bin/cli.mjs" > /dev/null 2>&1

assert "Superpowers block preserved" "grep -q 'BEGIN antigravity-superpowers' '$TEST_PROJECT3/GEMINI.md'"
assert "Unity block added" "grep -q 'BEGIN antigravity-unity-skills' '$TEST_PROJECT3/GEMINI.md'"
assert "Both END markers present" "grep -c 'END antigravity' '$TEST_PROJECT3/GEMINI.md' | grep -q '2'"

rm -rf "$TEST_PROJECT3"
echo ""

# ─── Summary ─────────────────────────────────────────────────
echo "╔════════════════════════════════════════════════════════════╗"
if [ $FAIL -eq 0 ]; then
    echo -e "║  ${GREEN}All $TOTAL tests passed${NC}                                      ║"
else
    echo -e "║  ${RED}$FAIL/$TOTAL tests failed${NC}                                       ║"
fi
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "  Passed: $PASS / $TOTAL"
echo "  Failed: $FAIL / $TOTAL"
echo ""

[ $FAIL -eq 0 ] && exit 0 || exit 1
