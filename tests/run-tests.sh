#!/bin/bash
# Automated test runner for AG Skills setup
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
echo "║     AG Skills — Automated Test Suite                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ─── TC-01: Fresh Install (Flat Structure) ──────────────────
echo -e "${YELLOW}TC-01: Fresh Install — Flat Structure${NC}"
cd "$TEST_PROJECT"
node "$SCRIPT_DIR/bin/cli.mjs" > /dev/null 2>&1

assert "Skills directory exists" "[ -d '$TEST_PROJECT/.agents/skills' ]"
assert "No legacy unity-skills group folder" "[ ! -d '$TEST_PROJECT/.agents/skills/unity-skills' ]"
assert "No legacy qa-skills group folder" "[ ! -d '$TEST_PROJECT/.agents/skills/qa-skills' ]"
assert "No GEMINI.md created" "[ ! -f '$TEST_PROJECT/GEMINI.md' ]"

# Count all SKILL.md files (flat — exactly 1 level deep)
SKILL_COUNT=$(find "$TEST_PROJECT/.agents/skills" -maxdepth 2 -name "SKILL.md" -type f | wc -l | tr -d ' ')
assert "Total skills installed ($SKILL_COUNT found, expect 13+)" "[ $SKILL_COUNT -ge 13 ]"

# Verify new audit skill exists (v5.0 redesign → v5.1 merge)
assert "unity-code-audit exists (flat)" "[ -f '$TEST_PROJECT/.agents/skills/unity-code-audit/SKILL.md' ]"

# Verify old audit skills removed
assert "unity-script-audit removed" "[ ! -d '$TEST_PROJECT/.agents/skills/unity-script-audit' ]"
assert "unity-logic-audit removed" "[ ! -d '$TEST_PROJECT/.agents/skills/unity-logic-audit' ]"

# Verify truly flat — no SKILL.md at depth 3+
NESTED=$(find "$TEST_PROJECT/.agents/skills" -mindepth 3 -name "SKILL.md" -type f | wc -l | tr -d ' ')
assert "Flat structure (no nested SKILL.md)" "[ $NESTED -eq 0 ]"

# Spot check unity skills at flat level
assert "unity-ui-performance exists (flat)" "[ -f '$TEST_PROJECT/.agents/skills/unity-ui-performance/SKILL.md' ]"
assert "unity-csharp-standards exists (flat)" "[ -f '$TEST_PROJECT/.agents/skills/unity-csharp-standards/SKILL.md' ]"

# Spot check QA skills at flat level
assert "unity-qa-parser exists (flat)" "[ -f '$TEST_PROJECT/.agents/skills/unity-qa-parser/SKILL.md' ]"
assert "unity-qa-generator exists (flat)" "[ -f '$TEST_PROJECT/.agents/skills/unity-qa-generator/SKILL.md' ]"
assert "unity-qa-verifier exists (flat)" "[ -f '$TEST_PROJECT/.agents/skills/unity-qa-verifier/SKILL.md' ]"
assert "unity-qa-scorer exists (flat)" "[ -f '$TEST_PROJECT/.agents/skills/unity-qa-scorer/SKILL.md' ]"
echo ""

# ─── TC-02: YAML Frontmatter Validation ─────────────────────
echo -e "${YELLOW}TC-02: YAML Frontmatter Validation${NC}"
INVALID_FM=0
for skill_dir in "$TEST_PROJECT/.agents/skills"/*/; do
    if [ -d "$skill_dir" ]; then
        SKILL_FILE="$skill_dir/SKILL.md"
        if [ -f "$SKILL_FILE" ]; then
            # Extract only frontmatter (between first pair of ---)
            frontmatter=$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$SKILL_FILE")
            has_name=$(echo "$frontmatter" | grep -c '^name:' 2>/dev/null || echo 0)
            has_desc=$(echo "$frontmatter" | grep -c '^description:' 2>/dev/null || echo 0)
            if [ "$has_name" -ne 1 ] || [ "$has_desc" -ne 1 ]; then
                INVALID_FM=$((INVALID_FM + 1))
            fi
        fi
    fi
done
assert "All skills have valid frontmatter (name + description)" "[ $INVALID_FM -eq 0 ]"

# Check no extra YAML fields (Antigravity standard: name + description only)
EXTRA_FIELDS=0
for skill_dir in "$TEST_PROJECT/.agents/skills"/*/; do
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

SKILL_COUNT_AFTER=$(find "$TEST_PROJECT/.agents/skills" -maxdepth 2 -name "SKILL.md" -type f | wc -l | tr -d ' ')
assert "Skill count unchanged ($SKILL_COUNT_BEFORE → $SKILL_COUNT_AFTER)" "[ '$SKILL_COUNT_BEFORE' = '$SKILL_COUNT_AFTER' ]"
assert "Still no GEMINI.md" "[ ! -f '$TEST_PROJECT/GEMINI.md' ]"
assert "Still no legacy group folders" "[ ! -d '$TEST_PROJECT/.agents/skills/unity-skills' ] && [ ! -d '$TEST_PROJECT/.agents/skills/qa-skills' ]"
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
assert "Skills installed alongside existing files" "[ -d '$TEST_PROJECT2/.agents/skills' ]"

rm -rf "$TEST_PROJECT2"
echo ""

# ─── TC-05: All Skills Have SKILL.md ──────────────────────────
echo -e "${YELLOW}TC-05: All Skills Have SKILL.md${NC}"
for skill_dir in "$TEST_PROJECT/.agents/skills"/*/; do
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

# ─── TC-06: Manifest File ────────────────────────────────────
echo -e "${YELLOW}TC-06: Manifest File${NC}"
MANIFEST_FILE="$TEST_PROJECT/.agents/skills/.ag-manifest.json"
assert "Manifest file exists" "[ -f '$MANIFEST_FILE' ]"
assert "Manifest has version field" "grep -q '\"version\"' '$MANIFEST_FILE'"
assert "Manifest has installed_at field" "grep -q '\"installed_at\"' '$MANIFEST_FILE'"
assert "Manifest has groups field" "grep -q '\"groups\"' '$MANIFEST_FILE'"
assert "Manifest lists unity-skills group" "grep -q '\"unity-skills\"' '$MANIFEST_FILE'"
assert "Manifest lists qa-skills group" "grep -q '\"qa-skills\"' '$MANIFEST_FILE'"
echo ""

# ─── TC-07: Legacy Migration ─────────────────────────────────
echo -e "${YELLOW}TC-07: Legacy Migration — Removes Old Group Folders${NC}"
TEST_PROJECT3=$(mktemp -d)

# Simulate legacy v2 structure
mkdir -p "$TEST_PROJECT3/.agents/skills/unity-skills/dotween-safety"
echo "---" > "$TEST_PROJECT3/.agents/skills/unity-skills/dotween-safety/SKILL.md"
echo "name: dotween-safety" >> "$TEST_PROJECT3/.agents/skills/unity-skills/dotween-safety/SKILL.md"
echo "description: old" >> "$TEST_PROJECT3/.agents/skills/unity-skills/dotween-safety/SKILL.md"
echo "---" >> "$TEST_PROJECT3/.agents/skills/unity-skills/dotween-safety/SKILL.md"

cd "$TEST_PROJECT3"
node "$SCRIPT_DIR/bin/cli.mjs" > /dev/null 2>&1

assert "Legacy unity-skills folder removed" "[ ! -d '$TEST_PROJECT3/.agents/skills/unity-skills' ]"
assert "Skills installed flat after migration" "[ -f '$TEST_PROJECT3/.agents/skills/unity-dotween-safety/SKILL.md' ]"

rm -rf "$TEST_PROJECT3"
echo ""
echo ""

# ─── TC-08: Workflow Installation ────────────────────────────
echo -e "${YELLOW}TC-08: Workflow Installation${NC}"
assert "Workflows directory exists" "[ -d '$TEST_PROJECT/.agents/workflows' ]"
assert "build-ui-mcp.md installed" "[ -f '$TEST_PROJECT/.agents/workflows/build-ui-mcp.md' ]"
assert "verify-assets.md installed" "[ -f '$TEST_PROJECT/.agents/workflows/verify-assets.md' ]"
assert "verify-code.md installed" "[ -f '$TEST_PROJECT/.agents/workflows/verify-code.md' ]"
assert "verify-scripts.md removed" "[ ! -f '$TEST_PROJECT/.agents/workflows/verify-scripts.md' ]"
assert "verify-logics.md removed" "[ ! -f '$TEST_PROJECT/.agents/workflows/verify-logics.md' ]"
assert "Manifest has workflows field" "grep -q '\"workflows\"' '$MANIFEST_FILE'"
assert "Manifest lists build-ui-mcp.md" "grep -q 'build-ui-mcp.md' '$MANIFEST_FILE'"

# Verify idempotent — count unchanged after re-run
WF_COUNT_BEFORE=$(find "$TEST_PROJECT/.agents/workflows" -name "*.md" -type f | wc -l | tr -d ' ')
cd "$TEST_PROJECT"
node "$SCRIPT_DIR/bin/cli.mjs" > /dev/null 2>&1
WF_COUNT_AFTER=$(find "$TEST_PROJECT/.agents/workflows" -name "*.md" -type f | wc -l | tr -d ' ')
assert "Workflow count unchanged after re-run ($WF_COUNT_BEFORE → $WF_COUNT_AFTER)" "[ '$WF_COUNT_BEFORE' = '$WF_COUNT_AFTER' ]"
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
