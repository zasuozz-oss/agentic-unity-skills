#!/bin/bash
# Automated test runner for AG Unity project-skill setup
# Usage: bash tests/run-tests.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0
TOTAL=0

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

TEST_PROJECT=$(mktemp -d)
TEST_HOME=$(mktemp -d)
ORIGINAL_HOME="${HOME:-}"
export HOME="$TEST_HOME"
DYNAMIC_GROUP_DIR="$SCRIPT_DIR/global-config/skills/temp-dynamic-skills"
DYNAMIC_SKILL_DIR="$DYNAMIC_GROUP_DIR/unity-dynamic-test"

cleanup() {
    export HOME="$ORIGINAL_HOME"
    rm -rf "$TEST_PROJECT" "$TEST_HOME"
    rm -rf "$DYNAMIC_GROUP_DIR"
}
trap cleanup EXIT

CLI="node $SCRIPT_DIR/dist/cli/index.js"
TARGETS=(".agents" ".claude")

echo ""
echo "============================================================"
echo "  AG Unity Skills - Automated Test Suite"
echo "============================================================"
echo ""

# ─── TC-00: Build Surface ───────────────────────────────────
echo -e "${YELLOW}TC-00: Build Surface${NC}"
cd "$SCRIPT_DIR"
rm -rf "$DYNAMIC_GROUP_DIR"
mkdir -p "$DYNAMIC_SKILL_DIR"
printf '%s\n' '---' 'name: unity-dynamic-test' 'description: Use when verifying dynamic global-config skill discovery in tests.' '---' '' '# Dynamic Test Skill' > "$DYNAMIC_SKILL_DIR/SKILL.md"
EXPECTED_SKILL_COUNT=$(find "$SCRIPT_DIR/global-config" -name "SKILL.md" -type f | wc -l | tr -d ' ')
SAMPLE_SKILL_FILE=$(find "$SCRIPT_DIR/global-config/skills" -name "SKILL.md" -type f | sort | head -n 1)
SAMPLE_SKILL_NAME=$(basename "$(dirname "$SAMPLE_SKILL_FILE")")

npm run build > /dev/null 2>&1

assert "dist CLI exists" "[ -f '$SCRIPT_DIR/dist/cli/index.js' ]"
assert "dist CLI is executable" "[ -x '$SCRIPT_DIR/dist/cli/index.js' ]"
assert "package bin points to dist CLI" "grep -q '\"ag-unity\": \"dist/cli/index.js\"' '$SCRIPT_DIR/package.json'"
assert "setup.sh exists" "[ -f '$SCRIPT_DIR/setup.sh' ]"
assert "setup.sh syntax is valid" "bash -n '$SCRIPT_DIR/setup.sh'"
assert "version command works" "$CLI version | grep -q '5.2.0'"
assert "list command works" "$CLI list | grep -q '$SAMPLE_SKILL_NAME'"
assert "list command discovers new global-config group" "$CLI list | grep -q 'unity-dynamic-test'"
echo ""

# ─── TC-01: Fresh Project Init ───────────────────────────────
echo -e "${YELLOW}TC-01: Fresh Project Init — Project Skill Targets${NC}"
cd "$TEST_PROJECT"
$CLI init > /dev/null 2>&1

for target in "${TARGETS[@]}"; do
    assert "$target skills directory exists" "[ -d '$TEST_PROJECT/$target/skills' ]"
    assert "$target manifest exists" "[ -f '$TEST_PROJECT/$target/skills/.ag-unity-manifest.json' ]"
    assert "$target has source sample skill" "[ -f '$TEST_PROJECT/$target/skills/$SAMPLE_SKILL_NAME/SKILL.md' ]"
    assert "$target has unity-qa-parser" "[ -f '$TEST_PROJECT/$target/skills/unity-qa-parser/SKILL.md' ]"
    assert "$target has dynamically discovered skill" "[ -f '$TEST_PROJECT/$target/skills/unity-dynamic-test/SKILL.md' ]"
done

SKILL_COUNT=$(find "$TEST_PROJECT/.agents/skills" -maxdepth 2 -name "SKILL.md" -type f | wc -l | tr -d ' ')
assert "Total project skills installed ($SKILL_COUNT found, expect $EXPECTED_SKILL_COUNT)" "[ '$SKILL_COUNT' = '$EXPECTED_SKILL_COUNT' ]"
assert "AGENTS.md created" "[ -f '$TEST_PROJECT/AGENTS.md' ]"
assert "AGENTS.md includes AG Unity block" "grep -q '<!-- AG-UNITY:BEGIN -->' '$TEST_PROJECT/AGENTS.md' && grep -q '<!-- AG-UNITY:END -->' '$TEST_PROJECT/AGENTS.md'"
assert "AGENTS.md includes Unity MCP verification rule" "grep -q 'Use Unity MCP' '$TEST_PROJECT/AGENTS.md'"
assert "CLAUDE.md created" "[ -f '$TEST_PROJECT/CLAUDE.md' ]"
assert "CLAUDE.md includes AG Unity block" "grep -q '<!-- AG-UNITY:BEGIN -->' '$TEST_PROJECT/CLAUDE.md' && grep -q '<!-- AG-UNITY:END -->' '$TEST_PROJECT/CLAUDE.md'"
assert "CLAUDE.md includes Unity MCP verification rule" "grep -q 'Use Unity MCP' '$TEST_PROJECT/CLAUDE.md'"
assert "No GEMINI.md created" "[ ! -f '$TEST_PROJECT/GEMINI.md' ]"
assert "No project .codex skills created" "[ ! -d '$TEST_PROJECT/.codex/skills' ]"
assert "No global Codex skills written" "[ ! -d '$TEST_HOME/.codex/skills' ]"
assert "No global Claude skills written" "[ ! -d '$TEST_HOME/.claude/skills' ]"
assert "No global Antigravity skills written" "[ ! -d '$TEST_HOME/.gemini/antigravity/skills' ]"
echo ""

# ─── TC-02: YAML Frontmatter Validation ─────────────────────
echo -e "${YELLOW}TC-02: YAML Frontmatter Validation${NC}"
INVALID_FM=0
for skill_dir in "$TEST_PROJECT/.agents/skills"/*/; do
    if [ -d "$skill_dir" ]; then
        SKILL_FILE="$skill_dir/SKILL.md"
        if [ -f "$SKILL_FILE" ]; then
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

INVALID_DESC=0
for skill_dir in "$TEST_PROJECT/.agents/skills"/*/; do
    if [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ]; then
        desc=$(awk '/^description:/{sub(/^description:[[:space:]]*/, ""); print; exit}' "$skill_dir/SKILL.md")
        desc=${desc#\"}
        desc=${desc%\"}
        desc=${desc#\'}
        desc=${desc%\'}
        case "$desc" in
            "Use when"*) ;;
            *) INVALID_DESC=$((INVALID_DESC + 1)) ;;
        esac
    fi
done
assert "All skill descriptions start with Use when" "[ $INVALID_DESC -eq 0 ]"

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

# ─── TC-03: Idempotent ──────────────────────────────────────
echo -e "${YELLOW}TC-03: Idempotent — No Duplication${NC}"
SKILL_COUNT_BEFORE=$SKILL_COUNT

cd "$TEST_PROJECT"
$CLI init > /dev/null 2>&1

SKILL_COUNT_AFTER=$(find "$TEST_PROJECT/.agents/skills" -maxdepth 2 -name "SKILL.md" -type f | wc -l | tr -d ' ')
assert "Skill count unchanged ($SKILL_COUNT_BEFORE -> $SKILL_COUNT_AFTER)" "[ '$SKILL_COUNT_BEFORE' = '$SKILL_COUNT_AFTER' ]"
for target in "${TARGETS[@]}"; do
    assert "$target still has no legacy group folders" "[ ! -d '$TEST_PROJECT/$target/skills/unity-skills' ] && [ ! -d '$TEST_PROJECT/$target/skills/qa-skills' ] && [ ! -d '$TEST_PROJECT/$target/skills/temp-dynamic-skills' ]"
done
AG_UNITY_BLOCK_COUNT=$(grep -c '<!-- AG-UNITY:BEGIN -->' "$TEST_PROJECT/AGENTS.md" 2>/dev/null || true)
CLAUDE_AG_UNITY_BLOCK_COUNT=$(grep -c '<!-- AG-UNITY:BEGIN -->' "$TEST_PROJECT/CLAUDE.md" 2>/dev/null || true)
assert "AGENTS.md AG Unity instruction block not duplicated" "[ '$AG_UNITY_BLOCK_COUNT' = '1' ]"
assert "CLAUDE.md AG Unity instruction block not duplicated" "[ '$CLAUDE_AG_UNITY_BLOCK_COUNT' = '1' ]"
echo ""

# ─── TC-04: Existing Project — No Side Effects ───────────────
echo -e "${YELLOW}TC-04: Existing Project — No Side Effects${NC}"
TEST_PROJECT2=$(mktemp -d)
printf '# My Project\n\nSome existing content here.\n' > "$TEST_PROJECT2/GEMINI.md"
printf '%s\n' \
    '# Existing Agent Rules' \
    '' \
    '<!-- OTHER-REPO:BEGIN -->' \
    'Keep this unrelated repo instruction block.' \
    '<!-- OTHER-REPO:END -->' \
    '' \
    '<!-- AG-UNITY:BEGIN -->' \
    'old Unity rule that should be replaced' \
    '<!-- AG-UNITY:END -->' \
    '' \
    'Trailing local note.' > "$TEST_PROJECT2/AGENTS.md"
printf '%s\n' \
    '# Existing Claude Rules' \
    '' \
    '<!-- CLAUDE-LOCAL:BEGIN -->' \
    'Keep this Claude-specific instruction block.' \
    '<!-- CLAUDE-LOCAL:END -->' \
    '' \
    '<!-- AG-UNITY:BEGIN -->' \
    'old Claude Unity rule that should be replaced' \
    '<!-- AG-UNITY:END -->' \
    '' \
    'Trailing Claude local note.' > "$TEST_PROJECT2/CLAUDE.md"

cd "$TEST_PROJECT2"
$CLI init > /dev/null 2>&1

assert "Existing GEMINI.md untouched" "diff -q '$TEST_PROJECT2/GEMINI.md' <(printf '# My Project\n\nSome existing content here.\n')"
assert "Existing AGENTS.md keeps unrelated instruction block" "grep -q 'Keep this unrelated repo instruction block.' '$TEST_PROJECT2/AGENTS.md'"
assert "Existing AGENTS.md keeps trailing local content" "grep -q 'Trailing local note.' '$TEST_PROJECT2/AGENTS.md'"
assert "Existing AGENTS.md replaces only AG Unity block" "grep -q 'Use Unity MCP' '$TEST_PROJECT2/AGENTS.md' && ! grep -q 'old Unity rule that should be replaced' '$TEST_PROJECT2/AGENTS.md'"
assert "Existing CLAUDE.md keeps unrelated instruction block" "grep -q 'Keep this Claude-specific instruction block.' '$TEST_PROJECT2/CLAUDE.md'"
assert "Existing CLAUDE.md keeps trailing local content" "grep -q 'Trailing Claude local note.' '$TEST_PROJECT2/CLAUDE.md'"
assert "Existing CLAUDE.md replaces only AG Unity block" "grep -q 'Use Unity MCP' '$TEST_PROJECT2/CLAUDE.md' && ! grep -q 'old Claude Unity rule that should be replaced' '$TEST_PROJECT2/CLAUDE.md'"
assert "Project skills installed alongside existing files" "[ -d '$TEST_PROJECT2/.agents/skills' ] && [ -d '$TEST_PROJECT2/.claude/skills' ] && [ ! -d '$TEST_PROJECT2/.codex/skills' ]"

rm -rf "$TEST_PROJECT2"
echo ""

# ─── TC-05: Manifest File ───────────────────────────────────
echo -e "${YELLOW}TC-05: Manifest File${NC}"
MANIFEST_FILE="$TEST_PROJECT/.agents/skills/.ag-unity-manifest.json"
assert "Manifest has package field" "grep -q '\"package\"' '$MANIFEST_FILE'"
assert "Manifest has version field" "grep -q '\"version\"' '$MANIFEST_FILE'"
assert "Manifest has installed_at field" "grep -q '\"installed_at\"' '$MANIFEST_FILE'"
assert "Manifest has groups field" "grep -q '\"groups\"' '$MANIFEST_FILE'"
assert "Manifest lists unity-skills group" "grep -q '\"unity-skills\"' '$MANIFEST_FILE'"
assert "Manifest lists qa-skills group" "grep -q '\"qa-skills\"' '$MANIFEST_FILE'"
assert "Manifest lists dynamically discovered group" "grep -q '\"temp-dynamic-skills\"' '$MANIFEST_FILE'"
assert "Manifest lists flat skills field" "grep -q '\"skills\"' '$MANIFEST_FILE'"
echo ""

# ─── TC-06: Legacy Migration ─────────────────────────────────
echo -e "${YELLOW}TC-06: Legacy Migration — Removes Old Group Folders${NC}"
TEST_PROJECT3=$(mktemp -d)

mkdir -p "$TEST_PROJECT3/.agents/skills/unity-skills/dotween-safety"
printf '%s\n' '---' 'name: dotween-safety' 'description: old' '---' > "$TEST_PROJECT3/.agents/skills/unity-skills/dotween-safety/SKILL.md"
mkdir -p "$TEST_PROJECT3/.agents/skills/removed-managed-skill"
printf '%s\n' '---' 'name: removed-managed-skill' 'description: old managed skill' '---' > "$TEST_PROJECT3/.agents/skills/removed-managed-skill/SKILL.md"
printf '%s\n' '{"groups":{"old-group":["removed-managed-skill"]},"skills":["removed-managed-skill"]}' > "$TEST_PROJECT3/.agents/skills/.ag-unity-manifest.json"

cd "$TEST_PROJECT3"
$CLI init > /dev/null 2>&1

assert "Legacy unity-skills folder removed" "[ ! -d '$TEST_PROJECT3/.agents/skills/unity-skills' ]"
assert "Skills installed flat after migration" "[ -f '$TEST_PROJECT3/.agents/skills/unity-dotween-safety/SKILL.md' ]"
assert "Old manifest-managed skill removed" "[ ! -d '$TEST_PROJECT3/.agents/skills/removed-managed-skill' ]"

rm -rf "$TEST_PROJECT3"
echo ""

# ─── TC-07: init Argument Rejection ──────────────────────────
echo -e "${YELLOW}TC-07: init Rejects Project Path Argument${NC}"
TEST_PROJECT4=$(mktemp -d)
cd "$TEST_PROJECT4"
set +e
$CLI init "$TEST_PROJECT" > "$TEST_PROJECT4/out.log" 2>&1
STATUS=$?
set -e
assert "init with project path exits non-zero" "[ $STATUS -ne 0 ]"
assert "init path error explains cwd usage" "grep -q 'does not accept a project path' '$TEST_PROJECT4/out.log'"
assert "init path rejection does not install skills" "[ ! -d '$TEST_PROJECT4/.agents/skills' ]"
rm -rf "$TEST_PROJECT4"
echo ""

# ─── Summary ─────────────────────────────────────────────────
echo "============================================================"
if [ $FAIL -eq 0 ]; then
    echo -e "  ${GREEN}All $TOTAL tests passed${NC}"
else
    echo -e "  ${RED}$FAIL/$TOTAL tests failed${NC}"
fi
echo "============================================================"
echo ""
echo "  Passed: $PASS / $TOTAL"
echo "  Failed: $FAIL / $TOTAL"
echo ""

[ $FAIL -eq 0 ] && exit 0 || exit 1
