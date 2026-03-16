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

assert "Skills directory exists" "[ -d '$TEST_PROJECT/.agents/skills/unity-skills' ]"
assert "GEMINI.md exists" "[ -f '$TEST_PROJECT/GEMINI.md' ]"

# Count SKILL.md files (flat structure: .agents/skills/<name>/SKILL.md)
SKILL_COUNT=$(find "$TEST_PROJECT/.agents/skills/unity-skills" -maxdepth 2 -name "SKILL.md" -type f | wc -l | tr -d ' ')
assert "Skills installed ($SKILL_COUNT found, expect 60+)" "[ $SKILL_COUNT -ge 60 ]"

# Verify flat structure — no nested category folders
NESTED=$(find "$TEST_PROJECT/.agents/skills/unity-skills" -mindepth 3 -name "SKILL.md" -type f | wc -l | tr -d ' ')
assert "Flat structure (no nested categories)" "[ $NESTED -eq 0 ]"

# Spot check a skill
assert "design-patterns exists" "[ -f '$TEST_PROJECT/.agents/skills/unity-skills/design-patterns/SKILL.md' ]"
assert "state-machine-architect exists" "[ -f '$TEST_PROJECT/.agents/skills/unity-skills/state-machine-architect/SKILL.md' ]"
assert "architecture-advisor exists" "[ -f '$TEST_PROJECT/.agents/skills/unity-skills/architecture-advisor/SKILL.md' ]"
echo ""

# ─── TC-02: GEMINI.md Content ────────────────────────────────
echo -e "${YELLOW}TC-02: GEMINI.md Content${NC}"
GEMINI_FILE="$TEST_PROJECT/GEMINI.md"

assert "Contains BEGIN marker" "grep -q 'BEGIN antigravity-unity-skills' '$GEMINI_FILE'"
assert "Contains END marker" "grep -q 'END antigravity-unity-skills' '$GEMINI_FILE'"

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

BEGIN_COUNT2=$(grep -c 'BEGIN antigravity-unity-skills' "$TEST_PROJECT2/GEMINI.md")
assert "Only 1 BEGIN marker ($BEGIN_COUNT2)" "[ $BEGIN_COUNT2 -eq 1 ]"

rm -rf "$TEST_PROJECT2"
echo ""

# ─── TC-05: Backup Created ──────────────────────────────────
echo -e "${YELLOW}TC-05: Backup on Re-install${NC}"
cd "$TEST_PROJECT"
node "$SCRIPT_DIR/bin/cli.mjs" > /dev/null 2>&1

BACKUP_COUNT=$(ls -1d "$TEST_PROJECT/.agents/skills/unity-skills-backup-"* 2>/dev/null | wc -l | tr -d ' ')
assert "Backup directory created ($BACKUP_COUNT)" "[ $BACKUP_COUNT -ge 1 ]"
echo ""

# ─── TC-06: All Skills Have SKILL.md ─────────────────────────
echo -e "${YELLOW}TC-06: All Skills Have SKILL.md${NC}"
for skill_dir in "$TEST_PROJECT/.agents/skills/unity-skills"/*/; do
    if [ -d "$skill_dir" ]; then
        SKILL_NAME=$(basename "$skill_dir")
        if [ -f "$skill_dir/SKILL.md" ]; then
            assert "$SKILL_NAME has SKILL.md" "true"
        else
            assert "$SKILL_NAME has SKILL.md" "false"
        fi
    fi
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
