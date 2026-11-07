#!/usr/bin/env bash
# Regression check: isolated worktrees are opt-in in this fork.
#
# using-git-worktrees runs only when the human partner or a project
# instruction asks for an isolated worktree. The plan executors work on a
# feature branch in place by default and must not tell the agent to create a
# worktree unconditionally. Guards against upstream merges silently restoring
# the always-on worktree setup.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

USING_SKILL="$REPO_ROOT/skills/using-git-worktrees/SKILL.md"
SDD_SKILL="$REPO_ROOT/skills/subagent-driven-development/SKILL.md"
EP_SKILL="$REPO_ROOT/skills/executing-plans/SKILL.md"
README="$REPO_ROOT/README.md"

failures=0

pass() { echo "  [PASS] $1"; }
fail() {
    echo "  [FAIL] $1"
    shift
    for line in "$@"; do echo "    $line"; done
    failures=$((failures + 1))
}

assert_contains() {
    local file="$1" pattern="$2" label="$3"
    if grep -Fq -- "$pattern" "$file"; then
        pass "$label"
    else
        fail "$label" "Expected to find: $pattern" "In file: $file"
    fi
}

assert_not_contains() {
    local file="$1" pattern="$2" label="$3"
    if grep -Fq -- "$pattern" "$file"; then
        fail "$label" "Did not expect to find: $pattern" "In file: $file"
    else
        pass "$label"
    fi
}

echo "=== Worktree Opt-In Test ==="
echo ""

description="$(grep -m1 '^description:' "$USING_SKILL" || true)"
if printf '%s' "$description" | grep -Fq "never pick it on your own"; then
    pass "using-git-worktrees description makes it opt-in"
else
    fail "using-git-worktrees description makes it opt-in" \
        "Expected 'never pick it on your own' in: $description"
fi

for skill in "$SDD_SKILL" "$EP_SKILL"; do
    name="$(basename "$(dirname "$skill")")"
    assert_not_contains "$skill" "superpowers:using-git-worktrees to create one or verify the existing one" \
        "$name Setup does not create a worktree unconditionally"
    assert_contains "$skill" "An isolated worktree is opt-in" \
        "$name Setup states the opt-in condition"
    assert_not_contains "$skill" "Setup: worktree" \
        "$name process graph does not list a worktree in Setup"
done

assert_contains "$README" "2. **using-git-worktrees** - Opt-in." \
    "README workflow step marks using-git-worktrees opt-in"
assert_contains "$README" "- **using-git-worktrees** - Opt-in" \
    "README skills library marks using-git-worktrees opt-in"

echo ""

if [ "$failures" -gt 0 ]; then
    echo "STATUS: FAILED ($failures failures)"
    exit 1
fi

echo "STATUS: PASSED"
