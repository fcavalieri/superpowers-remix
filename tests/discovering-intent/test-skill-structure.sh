#!/usr/bin/env bash
# Structural checks for skills/discovering-intent (the v7.0.0 brainstorming
# conversation under its own name) and for its registration. Behaviour is
# not tested here; this script checks what a shell can check: frontmatter,
# the hand-off to brainstorming, the intent-document path, the shared
# visual-companion files, and that every harness that lists skills by name
# lists this one.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL_DIR="$REPO_ROOT/skills/discovering-intent"
SKILL_MD="$SKILL_DIR/SKILL.md"

PASSES=0
FAILURES=0

pass() { echo "  [PASS] $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

# body_has "<label>" "<literal>" — the literal must appear in the body (after frontmatter)
body_has() {
  if printf '%s\n' "$BODY" | grep -qF -- "$2"; then pass "$1"; else fail "$1"; fi
}
body_lacks() {
  if printf '%s\n' "$BODY" | grep -qF -- "$2"; then fail "$1"; else pass "$1"; fi
}

echo "discovering-intent structure"

if [ -f "$SKILL_MD" ]; then
  pass "SKILL.md exists"
  frontmatter="$(awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1{print}' "$SKILL_MD")"
  BODY="$(awk 'BEGIN{fm=0} NR==1 && $0=="---"{fm=1; next} fm==1 && $0=="---"{fm=2; next} fm==2{print}' "$SKILL_MD")"

  if printf '%s\n' "$frontmatter" | grep -q '^name: discovering-intent$'; then
    pass "frontmatter name is discovering-intent"
  else
    fail "frontmatter name is discovering-intent"
  fi
  description="$(printf '%s\n' "$frontmatter" | awk '/^description:/{sub(/^description:[ ]*"?/,""); print; found=1; next} found && /^[ ]/{print} found && !/^[ ]/{exit}' | tr '\n' ' ')"
  if printf '%s' "$description" | grep -q '^Use when'; then
    pass "description starts with 'Use when'"
  else
    fail "description starts with 'Use when' (got: ${description:0:60})"
  fi
  if printf '%s' "$description" | grep -q 'brainstorming'; then
    pass "description names brainstorming"
  else
    fail "description names brainstorming"
  fi
  if printf '%s' "$description" | grep -qF 'You MUST use this before any creative work'; then
    fail "description does not claim the universal creative-work trigger"
  else
    pass "description does not claim the universal creative-work trigger"
  fi

  # --- files ------------------------------------------------------------
  if [ -f "$SKILL_DIR/builder-check-prompt.md" ]; then
    pass "builder-check-prompt.md lives in discovering-intent"
  else
    fail "builder-check-prompt.md lives in discovering-intent"
  fi
  if [ -f "$REPO_ROOT/skills/brainstorming/builder-check-prompt.md" ]; then
    fail "builder-check-prompt.md no longer in brainstorming"
  else
    pass "builder-check-prompt.md no longer in brainstorming"
  fi
  for shared in "skills/brainstorming/visual-companion.md" "skills/brainstorming/scripts/start-server.sh"; do
    if [ -f "$REPO_ROOT/$shared" ]; then
      pass "shared file exists: $shared"
    else
      fail "shared file exists: $shared"
    fi
  done

  # --- body -------------------------------------------------------------
  if printf '%s
' "$BODY" | grep -q '^# Discovering Intent$'; then pass "H1 is Discovering Intent"; else fail "H1 is Discovering Intent"; fi
  body_lacks "H1 is no longer Brainstorming" '# Brainstorming'
  body_has "callee hands back instead of re-invoking brainstorming" 'If brainstorming invoked this skill'
  body_has "intent document path" 'docs/superpowers/intents/YYYY-MM-DD-<topic>-intent.md'
  body_lacks "no design-spec path" 'docs/superpowers/specs/'
  body_has "projects hand off to brainstorming" 'invoke superpowers:brainstorming'
  body_lacks "writing-plans is not invoked from here" 'superpowers:writing-plans'
  body_has "small change waits for an answer" 'nothing is assumed'
  body_has "visual companion guide referenced by path" 'skills/brainstorming/visual-companion.md'
  body_has "server scripts referenced by path" 'skills/brainstorming/scripts/'
  for heading in "## Play It Back" "## Red Flags" "<HARD-GATE>"; do
    body_has "body contains '$heading'" "$heading"
  done
else
  fail "SKILL.md exists"
fi

echo "discovering-intent registration"

USING="$REPO_ROOT/skills/using-superpowers/SKILL.md"
if grep -qF 'superpowers:discovering-intent' "$USING"; then
  pass "using-superpowers routes to discovering-intent"
else
  fail "using-superpowers routes to discovering-intent"
fi
if grep -qF '"Let'"'"'s build X" with a clear outcome' "$USING"; then
  pass "using-superpowers routes clear requests to brainstorming"
else
  fail "using-superpowers routes clear requests to brainstorming"
fi

# Muse lists skills by id; every skills/<dir>/SKILL.md must be listed.
missing="$(python3 - "$REPO_ROOT" <<'PY'
import json, os, sys
root = sys.argv[1]
manifest = json.load(open(os.path.join(root, ".muse-plugin", "plugin.json"), encoding="utf-8"))
listed = {s["id"] for s in manifest["capabilities"]["skills"]}
dirs = sorted(d for d in os.listdir(os.path.join(root, "skills"))
              if os.path.isfile(os.path.join(root, "skills", d, "SKILL.md")))
for d in dirs:
    if d not in listed:
        print(d)
PY
)"
if [ -z "$missing" ]; then
  pass "every skill directory is listed in .muse-plugin/plugin.json"
else
  for id in $missing; do fail "skill listed in .muse-plugin/plugin.json: $id"; done
fi

if grep -qF '**discovering-intent**' "$REPO_ROOT/README.md"; then
  pass "README lists discovering-intent"
else
  fail "README lists discovering-intent"
fi
if grep -qF '/plugin uninstall superpowers@superpowers-marketplace' "$REPO_ROOT/README.md"; then
  pass "README says to uninstall upstream first"
else
  fail "README says to uninstall upstream first"
fi

echo ""
echo "$PASSES passed, $FAILURES failed"
[ "$FAILURES" -eq 0 ]
