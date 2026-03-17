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
assert "No GEMINI.md created" "[ ! -f '$TEST_PROJECT/GEMINI.md' ]"

# Count SKILL.md files (flat structure: .agents/skills/<name>/SKILL.md)
SKILL_COUNT=$(find "$TEST_PROJECT/.agents/skills/unity-skills" -maxdepth 2 -name "SKILL.md" -type f | wc -l | tr -d ' ')
assert "Skills installed ($SKILL_COUNT found, expect 40+)" "[ $SKILL_COUNT -ge 40 ]"

# Verify flat structure — no nested category folders
NESTED=$(find "$TEST_PROJECT/.agents/skills/unity-skills" -mindepth 3 -name "SKILL.md" -type f | wc -l | tr -d ' ')
assert "Flat structure (no nested categories)" "[ $NESTED -eq 0 ]"

# Spot check a skill
assert "design-patterns exists" "[ -f '$TEST_PROJECT/.agents/skills/unity-skills/design-patterns/SKILL.md' ]"
assert "mobile-optimization exists" "[ -f '$TEST_PROJECT/.agents/skills/unity-skills/mobile-optimization/SKILL.md' ]"
assert "architecture-advisor exists" "[ -f '$TEST_PROJECT/.agents/skills/unity-skills/architecture-advisor/SKILL.md' ]"
echo ""

# ─── TC-02: YAML Frontmatter Validation ─────────────────────
echo -e "${YELLOW}TC-02: YAML Frontmatter Validation${NC}"
INVALID_FM=0
for skill_dir in "$TEST_PROJECT/.agents/skills/unity-skills"/*/; do
    if [ -d "$skill_dir" ]; then
        SKILL_FILE="$skill_dir/SKILL.md"
        if [ -f "$SKILL_FILE" ]; then
            has_name=$(grep -c '^name:' "$SKILL_FILE" 2>/dev/null || echo 0)
            has_desc=$(grep -c '^description:' "$SKILL_FILE" 2>/dev/null || echo 0)
            if [ "$has_name" -ne 1 ] || [ "$has_desc" -ne 1 ]; then
                INVALID_FM=$((INVALID_FM + 1))
            fi
        fi
    fi
done
assert "All skills have valid frontmatter (name + description)" "[ $INVALID_FM -eq 0 ]"

# Check no extra YAML fields (Antigravity standard: name + description only)
EXTRA_FIELDS=0
for skill_dir in "$TEST_PROJECT/.agents/skills/unity-skills"/*/; do
    if [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ]; then
        extras=$(grep -c -E '^(version:|tags:|argument-hint:|disable-model|user-invocable|allowed-tools:)' "$skill_dir/SKILL.md" 2>/dev/null || true)
        extras=${extras:-0}
        extras=$(echo "$extras" | tr -d '[:space:]')
        EXTRA_FIELDS=$((EXTRA_FIELDS + extras))
    fi
done
assert "No extra YAML fields (Antigravity standard)" "[ $EXTRA_FIELDS -eq 0 ]"
echo ""

# ─── TC-03: Idempotent (No Duplication) ─────────────────────
echo -e "${YELLOW}TC-03: Idempotent — No Duplication${NC}"
SKILL_COUNT_BEFORE=$SKILL_COUNT

cd "$TEST_PROJECT"
node "$SCRIPT_DIR/bin/cli.mjs" > /dev/null 2>&1

SKILL_COUNT_AFTER=$(find "$TEST_PROJECT/.agents/skills/unity-skills" -maxdepth 2 -name "SKILL.md" -type f | wc -l | tr -d ' ')
assert "Skill count unchanged ($SKILL_COUNT_BEFORE → $SKILL_COUNT_AFTER)" "[ '$SKILL_COUNT_BEFORE' = '$SKILL_COUNT_AFTER' ]"
assert "Still no GEMINI.md" "[ ! -f '$TEST_PROJECT/GEMINI.md' ]"
echo ""

# ─── TC-04: Existing Project — No Side Effects ───────────────
echo -e "${YELLOW}TC-04: Existing Project — No Side Effects${NC}"
TEST_PROJECT2=$(mktemp -d)
echo "# My Project" > "$TEST_PROJECT2/GEMINI.md"
echo "" >> "$TEST_PROJECT2/GEMINI.md"
echo "Some existing content here." >> "$TEST_PROJECT2/GEMINI.md"

cd "$TEST_PROJECT2"
node "$SCRIPT_DIR/bin/cli.mjs" > /dev/null 2>&1

assert "Existing GEMINI.md untouched" "diff -q '$TEST_PROJECT2/GEMINI.md' <(echo -e '# My Project\n\nSome existing content here.') > /dev/null 2>&1"
assert "Skills installed alongside existing files" "[ -d '$TEST_PROJECT2/.agents/skills/unity-skills' ]"

rm -rf "$TEST_PROJECT2"
echo ""

# ─── TC-05: All Skills Have SKILL.md ─────────────────────────
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
