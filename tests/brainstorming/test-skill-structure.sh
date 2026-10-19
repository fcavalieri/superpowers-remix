#!/usr/bin/env bash
# Structural checks for skills/brainstorming (the v6.4.2 how-oriented
# conversation, restored) and for the routing lines in using-superpowers.
# Behaviour is not tested here; this script checks what a shell can check:
# frontmatter, the opener that redirects to discovering-intent, the v6.4.2
# sections that must be back, the merged "how it gets made" rule, and the
# files beside SKILL.md.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL_DIR="$REPO_ROOT/skills/brainstorming"
SKILL_MD="$SKILL_DIR/SKILL.md"

PASSES=0
FAILURES=0

pass() { echo "  [PASS] $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

body_has() {
  if printf '%s\n' "$BODY" | grep -qF -- "$2"; then pass "$1"; else fail "$1"; fi
}
body_lacks() {
  if printf '%s\n' "$BODY" | grep -qF -- "$2"; then fail "$1"; else pass "$1"; fi
}

echo "brainstorming structure"

if [ -f "$SKILL_MD" ]; then
  pass "SKILL.md exists"
  frontmatter="$(awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1{print}' "$SKILL_MD")"
  BODY="$(awk 'BEGIN{fm=0} NR==1 && $0=="---"{fm=1; next} fm==1 && $0=="---"{fm=2; next} fm==2{print}' "$SKILL_MD")"

  if printf '%s\n' "$frontmatter" | grep -q '^name: brainstorming$'; then
    pass "frontmatter name is brainstorming"
  else
    fail "frontmatter name is brainstorming"
  fi
  description="$(printf '%s\n' "$frontmatter" | awk '/^description:/{sub(/^description:[ ]*"?/,""); print; found=1; next} found && /^[ ]/{print} found && !/^[ ]/{exit}' | tr '\n' ' ')"
  if printf '%s' "$description" | grep -qF 'You MUST use this before any creative work'; then
    pass "description keeps the universal creative-work trigger"
  else
    fail "description keeps the universal creative-work trigger (got: ${description:0:60})"
  fi
  if printf '%s' "$description" | grep -qF 'only when asked'; then
    pass "description says discovering-intent is only on request"
  else
    fail "description says discovering-intent is only on request"
  fi

  # --- the opener ---------------------------------------------------------
  body_has "opener heading" '## First: Do You Know What and Why?'
  body_lacks "v6.4.2 shared-understanding opener is gone" '## Establish Shared Understanding'
  body_has "intent-document check is per topic" 'an intent document for this topic exists'
  body_has "the offer is the opt-in phrase" 'say "discover intent"'
  body_has "never hands off unprompted" 'Never invoke it unprompted'
  body_has "the phrase invokes discovering-intent" 'invoke superpowers:discovering-intent'
  body_has "the offer rides on the first question, not its own turn" 'on the same line as your first question'
  body_has "control resumes here after the redirect" 'When it hands back, resume here'

  # --- the v6.4.2 how process -------------------------------------------
  for section in "## Three Paths" "<HARD-GATE>" "## Checklist" "## Process Flow" "**Exploring approaches:**" "**Presenting the design:**" "## After the Design (architectural path)"; do
    body_has "body contains '$section'" "$section"
  done
  body_has "architectural path ends in writing-plans" 'Invoke the writing-plans skill'

  # --- merged "how it gets made" rule -----------------------------------
  body_has "asks which how-it-gets-made choices they want to make" 'which of those choices they want to make themselves'
  body_has "own calls are never recorded as agreed" 'never as something they agreed to'

  # --- files --------------------------------------------------------------
  if [ -f "$SKILL_DIR/spec-document-reviewer-prompt.md" ]; then
    pass "spec-document-reviewer-prompt.md restored"
  else
    fail "spec-document-reviewer-prompt.md restored"
  fi
  if [ -f "$SKILL_DIR/builder-check-prompt.md" ]; then
    fail "builder-check-prompt.md is not here"
  else
    pass "builder-check-prompt.md is not here"
  fi
  body_lacks "body does not reference builder-check-prompt.md" 'builder-check-prompt.md'
else
  fail "SKILL.md exists"
fi

echo ""
echo "$PASSES passed, $FAILURES failed"
[ "$FAILURES" -eq 0 ]
