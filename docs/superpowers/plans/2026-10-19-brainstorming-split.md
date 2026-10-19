# Brainstorming Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore the v6.4.2 how-oriented `brainstorming` skill under its own name, keep the v7.0.0 intent-oriented rebuild as a new `discovering-intent` skill, route between them, and ship the fork under its own marketplace name.

**Architecture:** Both skills are recovered verbatim from git tags (`v6.4.2` and `v7.0.0`) and then edited in a handful of named places, so the diff against each tag is the whole design. Routing is three short passages: the opener of `brainstorming`, the sizing exit of `discovering-intent`, and two lines in `using-superpowers`. The visual companion stays in `skills/brainstorming/` and is referenced by path. Each skill gets a structural shell test in the style of `tests/diagnosing-superpowers/test-skill-structure.sh`.

**Tech Stack:** Markdown skills, bash test scripts (`awk`, `grep`), `python3` stdlib in tests, `jq` via `scripts/bump-version.sh`, Claude Code CLI 2.1.303 for `claude plugin validate`.

**Spec:** `docs/superpowers/specs/2026-10-19-brainstorming-split-design.md`

## Global Constraints

- Work on branch `brainstorming-split`; `origin` is the GitHub fork, PRs target `main`. After merge, `git push gitlab main --tags` keeps the GitLab copy current.
- Files are LF-only. After any edit made with a tool that may write CRLF, check with `git diff --stat` and `file <path>`; the repo's `.gitattributes` and existing files are LF.
- Skill prefix stays `superpowers:`; the plugin `name` in every manifest stays `superpowers`.
- Marketplace `name` becomes `superpowers-remix`; Codex marketplace `displayName` becomes `Superpowers Remix`.
- Version becomes `7.0.0-remix.1` everywhere `.version-bump.json` declares, via `scripts/bump-version.sh`, never by hand.
- `skills/brainstorming/visual-companion.md`, `skills/brainstorming/scripts/` and `tests/brainstorm-server/` are not modified or copied.
- Intent documents go to `docs/superpowers/intents/YYYY-MM-DD-<topic>-intent.md`; design specs stay in `docs/superpowers/specs/`.
- No eval runs, no live-model tests; verification is structural.
- Commit messages end with `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.

## Review Focus

1. **A request that is clear on what but silent on why** (for example "add a `--json` flag to the export command"): `brainstorming` must not redirect to `discovering-intent`; the bounded path handles it. Pinned by Task 2's test that the opener lists the clear case first and names the override phrase.
2. **An intent document that exists for a different topic**: the opener's check is "an intent document for this topic", not "any file in the folder". Pinned by the exact wording asserted in Task 2's test.
3. **A small change where the user does not answer the build-now-or-design question**: nothing is assumed; the skill waits. Pinned by Task 1's test asserting the sentence "nothing is assumed" is present.
4. **Both skills loaded in one session after a redirect**: the invoking skill must say where control resumes. Pinned by Task 1 and Task 2 tests asserting the "resume here" and "hands back" sentences.
5. **An installed upstream `superpowers@superpowers-marketplace` beside the fork**: the plugin name collides by design; the README install section must say to uninstall upstream's first. Pinned by Task 4's README assertion.

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `skills/discovering-intent/SKILL.md` | Create (from `v7.0.0:skills/brainstorming/SKILL.md`) | The why skill |
| `skills/discovering-intent/builder-check-prompt.md` | Move (from `skills/brainstorming/`) | Builder check for intent documents |
| `tests/discovering-intent/test-skill-structure.sh` | Create | Structural assertions for the why skill and its registration |
| `skills/brainstorming/SKILL.md` | Rewrite (from `v6.4.2:skills/brainstorming/SKILL.md`) | The how skill |
| `skills/brainstorming/spec-document-reviewer-prompt.md` | Restore (from `v6.4.2`) | Spec reviewer for design specs |
| `tests/brainstorming/test-skill-structure.sh` | Create | Structural assertions for the how skill and the routing lines |
| `skills/using-superpowers/SKILL.md:30` | Modify | Two routing lines |
| `.muse-plugin/plugin.json:13-16` | Modify | Register the new skill for Muse |
| `README.md:310,353` | Modify | Skill list entries |
| `README.md:68-82` | Modify | Claude Code install from this fork |
| `.claude-plugin/marketplace.json`, `.agents/plugins/marketplace.json`, `.muse-plugin/marketplace.json` | Modify | Marketplace rename |
| `tests/codex/test-marketplace-manifest.sh:25-30` | Modify | Expect the new marketplace name |
| 12 manifests listed in `.version-bump.json` | Modify (via script) | Version `7.0.0-remix.1` |
| `RELEASE-NOTES.md:1-3` | Modify | `v7.0.0-remix.1` section |

---

### Task 1: `discovering-intent` skill

**Files:**
- Create: `skills/discovering-intent/SKILL.md`
- Move: `skills/brainstorming/builder-check-prompt.md` → `skills/discovering-intent/builder-check-prompt.md`
- Test: `tests/discovering-intent/test-skill-structure.sh`

**Interfaces:**
- Consumes: nothing from other tasks. Reads `skills/brainstorming/visual-companion.md` and `skills/brainstorming/scripts/` by path (unchanged files).
- Produces: skill name `discovering-intent`, invoked as `superpowers:discovering-intent`; intent documents at `docs/superpowers/intents/YYYY-MM-DD-<topic>-intent.md`; the hand-off sentence "invoke superpowers:brainstorming" that Task 2's opener relies on.

- [ ] **Step 1: Write the failing structure test**

Create `tests/discovering-intent/test-skill-structure.sh`, modelled on `tests/diagnosing-superpowers/test-skill-structure.sh` (same `pass`/`fail` helpers, same frontmatter `awk`, exit 1 when `FAILURES` is non-zero). Assertions, each one `pass`/`fail` line:

- `skills/discovering-intent/SKILL.md` exists
- frontmatter `name: discovering-intent`
- description starts with `Use when`
- description contains `brainstorming`
- description does not contain `You MUST use this before any creative work`
- `skills/discovering-intent/builder-check-prompt.md` exists
- `skills/brainstorming/builder-check-prompt.md` does not exist
- body contains `docs/superpowers/intents/YYYY-MM-DD-<topic>-intent.md`
- body does not contain `docs/superpowers/specs/`
- body contains `invoke superpowers:brainstorming`
- body does not contain `superpowers:writing-plans`
- body contains `nothing is assumed`
- body contains `skills/brainstorming/visual-companion.md`
- body contains `skills/brainstorming/scripts/`
- `skills/brainstorming/visual-companion.md` exists and `skills/brainstorming/scripts/start-server.sh` exists
- body contains `## Play It Back` and `## Red Flags` and `<HARD-GATE>`

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/discovering-intent/test-skill-structure.sh`
Expected: `[FAIL] SKILL.md exists` and exit code 1.

- [ ] **Step 3: Create the skill from the v7.0.0 text and move the prompt**

```bash
mkdir -p skills/discovering-intent
git show v7.0.0:skills/brainstorming/SKILL.md > skills/discovering-intent/SKILL.md
git mv skills/brainstorming/builder-check-prompt.md skills/discovering-intent/builder-check-prompt.md
```

- [ ] **Step 4: Apply the five edits to `skills/discovering-intent/SKILL.md`**

Edit 1, frontmatter (lines 2-3): `name: discovering-intent` and this description, one line:

```
description: "Use when what someone wants, or why, is not yet clear: a new idea, a vague feature request, a project without a brief, anything where you would be guessing at the purpose. Draws out intent, goals and anti-goals through questions that get them describing, plays it back, and writes an intent document. Hands off to brainstorming for the how."
```

Edit 2, the document (section `## The Written Design`, lines 145-157): rename the heading to `## The Intent Document`, change "write a plain document" to "write a plain intent document", and replace the **Where it goes** path with `docs/superpowers/intents/YYYY-MM-DD-<topic>-intent.md`. The content bullets and the builder-check paragraph are unchanged.

Edit 3, sizing (section `## Size the Work`, table rows at lines 136-138). Replace the three rows with:

```
| A quick, clear task | the request itself | do it |
| A small change | in chat | ask, in one sentence, whether to build it now through the normal workflow or design the how first with superpowers:brainstorming, then do what they pick; nothing is assumed until they answer |
| A project | the intent document | invoke superpowers:brainstorming; it designs from the approved intent and owns the approaches, the design, the spec and the hand-off to writing-plans |
```

Edit 4, gate (the last paragraph inside `<HARD-GATE>`, lines 191-192). Replace with:

```
After a project's intent document is approved, the next step is the how.
Invoke superpowers:brainstorming and no other skill; it resumes from the
approved intent and does not re-ask what this conversation settled.
```

Edit 5, visual companion (line 224-225). Replace with:

```
If they accept, read `skills/brainstorming/visual-companion.md` before
starting the server; the server scripts live in `skills/brainstorming/scripts/`.
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `bash tests/discovering-intent/test-skill-structure.sh`
Expected: every line `[PASS]`, exit code 0.

- [ ] **Step 6: Verify the diff against the tag is only the five edits**

Run: `git diff --no-index <(git show v7.0.0:skills/brainstorming/SKILL.md) skills/discovering-intent/SKILL.md | grep -c '^[-+][^-+]'`
Expected: a small number (under 30 changed lines), all within frontmatter, `## Size the Work`, `## The Intent Document`, the gate's last paragraph, and the visual companion's last lines.

- [ ] **Step 7: Commit**

```bash
git add skills/discovering-intent tests/discovering-intent
git commit -m "feat(discovering-intent): the v7.0.0 intent conversation as its own skill"
```

---

### Task 2: `brainstorming` restored as the how skill

**Files:**
- Rewrite: `skills/brainstorming/SKILL.md`
- Restore: `skills/brainstorming/spec-document-reviewer-prompt.md`
- Test: `tests/brainstorming/test-skill-structure.sh`

**Interfaces:**
- Consumes: Task 1's skill name `superpowers:discovering-intent` and intent path `docs/superpowers/intents/`.
- Produces: `brainstorming` with the universal trigger; its architectural path still ends by invoking `superpowers:writing-plans`.

- [ ] **Step 1: Write the failing structure test**

Create `tests/brainstorming/test-skill-structure.sh` in the same style. Assertions:

- `skills/brainstorming/SKILL.md` exists
- frontmatter `name: brainstorming`
- description starts with `You MUST use this before any creative work`
- description contains `redirects to discovering-intent`
- body contains `## First: Do You Know What and Why?`
- body does not contain `## Establish Shared Understanding`
- body contains `an intent document for this topic exists`
- body contains `"just design it"` and `"let's talk about why first"`
- body contains `invoke superpowers:discovering-intent`
- body contains `When it hands back, resume here`
- body contains `## Three Paths`, `<HARD-GATE>`, `## Checklist`, `## Process Flow`, `**Exploring approaches:**`, `**Presenting the design:**`, `## After the Design (architectural path)`
- body contains `Invoke the writing-plans skill`
- body contains `which of those choices they want to make`
- body contains `never as something they agreed to`
- `skills/brainstorming/spec-document-reviewer-prompt.md` exists
- `skills/brainstorming/builder-check-prompt.md` does not exist
- body does not contain `builder-check-prompt.md`

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/brainstorming/test-skill-structure.sh`
Expected: `[FAIL] body contains '## Three Paths'`, `[FAIL] body contains '## First: Do You Know What and Why?'` and `[FAIL] spec-document-reviewer-prompt.md exists`, among others; exit code 1. (The description assertion passes on the v7 text, which is expected.)

- [ ] **Step 3: Restore the v6.4.2 files**

```bash
git show v6.4.2:skills/brainstorming/SKILL.md > skills/brainstorming/SKILL.md
git show v6.4.2:skills/brainstorming/spec-document-reviewer-prompt.md > skills/brainstorming/spec-document-reviewer-prompt.md
```

- [ ] **Step 4: Apply the three edits to `skills/brainstorming/SKILL.md`**

Edit 1, description (line 3). Replace with, one line:

```
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Designs HOW to build something whose purpose is clear; redirects to discovering-intent when the what or why is not."
```

Edit 2, the opener. Replace the whole `## Establish Shared Understanding` section (v6.4.2 lines 14-36, up to the blank line before `<HARD-GATE>`) with:

```markdown
## First: Do You Know What and Why?

Before your first question, ask yourself what you know about what your
human partner wants and why they want it.

- **The what and why are clear.** The request names the outcome, who it
  is for and the constraints, or an intent document for this topic exists
  under `docs/superpowers/intents/`. Say so in one line ("the intent is
  clear, so I'll go straight to the design") and continue below. An
  intent document is the design brief: do not re-ask what it settled.
- **Something non-trivial about the what or why is missing.** Say "I'll
  find out what you're after first" and invoke
  superpowers:discovering-intent. When it hands back, resume here with
  its playback or intent document as the brief.

Your human partner can override either call: "just design it" skips the
redirect; "let's talk about why first" takes it. Announce the call before
acting on it so they can.
```

Edit 3, "how it gets made". In `**Understanding the idea:**` (v6.4.2 line 199 onward), after the bullet `- Focus on understanding: purpose, constraints, success criteria`, add:

```markdown
- Find out early which choices about how it gets made (platform, language, libraries, medium, tools) your partner wants to make, which of those choices they want to make themselves and which they are handing to you, and what they already have to work with. Someone with strong views talks it through; someone counting on you gets sensible defaults, said in plain words. When there is existing work, build on what it already uses. Any choice you make goes in the design as your call, never as something they agreed to.
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `bash tests/brainstorming/test-skill-structure.sh`
Expected: every line `[PASS]`, exit code 0.

- [ ] **Step 6: Verify the diff against the tag is only the three edits**

Run: `git diff v6.4.2 -- skills/brainstorming/SKILL.md skills/brainstorming/spec-document-reviewer-prompt.md | grep '^[-+][^-+]' | wc -l`
Expected: changed lines are the description, the replaced opener section, and one added bullet; the reviewer prompt shows no diff.

- [ ] **Step 7: Run Task 1's test again**

Run: `bash tests/discovering-intent/test-skill-structure.sh`
Expected: exit code 0 (its `builder-check-prompt.md` assertions still hold).

- [ ] **Step 8: Commit**

```bash
git add skills/brainstorming tests/brainstorming
git commit -m "feat(brainstorming): restore the v6.4.2 how conversation, redirect to discovering-intent when the why is missing"
```

---

### Task 3: Routing lines and registration

**Files:**
- Modify: `skills/using-superpowers/SKILL.md:30`
- Modify: `.muse-plugin/plugin.json:13-16`
- Modify: `README.md:310` and `README.md:353`
- Test: `tests/discovering-intent/test-skill-structure.sh` (append a "registration" block)

**Interfaces:**
- Consumes: both skill names from Tasks 1 and 2.
- Produces: nothing other tasks rely on.

- [ ] **Step 1: Append failing registration assertions to the Task 1 test**

Under a new `echo "discovering-intent registration"` block in `tests/discovering-intent/test-skill-structure.sh`:

- `skills/using-superpowers/SKILL.md` contains `superpowers:discovering-intent`
- `skills/using-superpowers/SKILL.md` contains `"Let's build X" with a clear outcome`
- every directory `skills/*/` holding a `SKILL.md` has an entry with that `id` under `capabilities.skills` in `.muse-plugin/plugin.json`, checked with a `python3 - <<'PY'` block using `json` and `os.listdir`, one `fail` line per missing id
- `README.md` contains `**discovering-intent**`

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/discovering-intent/test-skill-structure.sh`
Expected: the four new assertions `[FAIL]`, exit code 1.

- [ ] **Step 3: Add the two routing lines to `skills/using-superpowers/SKILL.md`**

Replace line 30 (`- "Let's build X" → superpowers:brainstorming first, then implementation skills.`) with:

```markdown
- "I have an idea", "I want something like...", or any request whose purpose you would have to guess → superpowers:discovering-intent first, then superpowers:brainstorming.
- "Let's build X" with a clear outcome → superpowers:brainstorming first, then implementation skills.
```

- [ ] **Step 4: Register the skill for Muse**

In `.muse-plugin/plugin.json`, after the `brainstorming` entry (lines 13-16), insert in alphabetical position (before `diagnosing-superpowers`):

```json
      {
        "id": "discovering-intent",
        "path": "skills/discovering-intent/SKILL.md"
      },
```

- [ ] **Step 5: Update the README skill list**

Replace the `1. **brainstorming** - ...` paragraph at line 310 with:

```markdown
1. **brainstorming** - Activates before building anything. Designs how to build what you asked for: clarifying questions, two or three approaches with trade-offs, a sectioned design, and a written spec for larger work. When what you want or why is not yet clear, it hands off to **discovering-intent** first, which draws that out through questions that get you describing it, plays its understanding back for correction, and writes an intent document that brainstorming then designs from.
```

Replace line 353 (`- **brainstorming** - Drawing out intent before building`) with:

```markdown
- **brainstorming** - Designing how to build it, before building
- **discovering-intent** - Drawing out what you want, and why, before designing
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `bash tests/discovering-intent/test-skill-structure.sh`
Expected: exit code 0.

- [ ] **Step 7: Run the harness tests that enumerate skills**

Run: `node tests/opencode/test-skill-registration.mjs`
Expected: exit code 0.
Run: `python -m pytest tests/hermes -q`
Expected: all tests `passed`, exit code 0 (`pip install pytest` first if missing).

- [ ] **Step 8: Commit**

```bash
git add skills/using-superpowers/SKILL.md .muse-plugin/plugin.json README.md tests/discovering-intent
git commit -m "feat: route between brainstorming and discovering-intent; register the new skill"
```

---

### Task 4: Marketplace rename, version, release notes

**Files:**
- Modify: `.claude-plugin/marketplace.json`, `.agents/plugins/marketplace.json`, `.muse-plugin/marketplace.json`
- Modify: `tests/codex/test-marketplace-manifest.sh:25-30`
- Modify: the 12 files declared in `.version-bump.json` (via `scripts/bump-version.sh`)
- Modify: `README.md:68-82`
- Modify: `RELEASE-NOTES.md:1-3`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: marketplace name `superpowers-remix`, version `7.0.0-remix.1`.

- [ ] **Step 1: Change the Codex manifest test to expect the new names**

In `tests/codex/test-marketplace-manifest.sh`, change the two assertions: `"superpowers-dev"` → `"superpowers-remix"` and `"Superpowers Dev"` → `"Superpowers Remix"`.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/codex/test-marketplace-manifest.sh`
Expected: `AssertionError: marketplace name: expected 'superpowers-remix', got 'superpowers-dev'`, exit code 1.

- [ ] **Step 3: Rename the marketplace in the three files**

- `.claude-plugin/marketplace.json` and `.muse-plugin/marketplace.json`: `"name": "superpowers-remix"`, `"description": "Superpowers remix: the how-oriented brainstorming skill restored beside the intent-oriented one"`.
- `.agents/plugins/marketplace.json`: `"name": "superpowers-remix"`, `"interface": { "displayName": "Superpowers Remix" }`.

Plugin `name` and `source` fields are unchanged.

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash tests/codex/test-marketplace-manifest.sh`
Expected: `Codex marketplace manifest looks good`, exit code 0.

- [ ] **Step 5: Bump the version**

Run: `bash scripts/bump-version.sh 7.0.0-remix.1 && bash scripts/bump-version.sh --check`
Expected: all 12 declared files report `7.0.0-remix.1`, no drift.
Run: `bash scripts/bump-version.sh --audit`
Expected: the only `UNDECLARED` hits are under `docs/superpowers/` (this plan and its spec name the version); nothing else.
Run: `bash tests/version-bump/test-bump-version.sh`
Expected: exit code 0.

- [ ] **Step 6: Point the README's Claude Code install at this fork**

Replace the `#### Superpowers Marketplace` subsection (README lines 68-82) with:

```markdown
#### This fork

This fork installs in place of upstream's plugin, not beside it: both are
named `superpowers`, so uninstall upstream's first.

- Remove upstream's plugin if it is installed:

  ```bash
  /plugin uninstall superpowers@superpowers-marketplace
  ```

- Register this repository as a marketplace (the `owner/repo` shorthand
  always means github.com, so give the full URL for the GitLab copy):

  ```bash
  /plugin marketplace add fcavalieri/superpowers-remix
  ```

- Install the plugin:

  ```bash
  /plugin install superpowers@superpowers-remix
  ```
```

Leave the `#### Official Marketplace` subsection and the other harness sections as they are.

- [ ] **Step 7: Add the release-notes section**

Insert after line 1 of `RELEASE-NOTES.md` (before `## v7.0.0 (2026-10-09)`):

```markdown
## v7.0.0-remix.1 (2026-10-19)

This fork keeps both brainstorming conversations. `brainstorming` is the v6.4.2 skill again: it designs how to build something whose purpose is clear, with clarifying questions, two or three approaches, a sectioned design and a written spec. The v7.0.0 rebuild lives on as `discovering-intent`: it draws out what you want and why, plays it back, and writes an intent document to `docs/superpowers/intents/`. Each hands off to the other: `brainstorming` redirects when the why is missing, and `discovering-intent` hands a project to `brainstorming` for the how, or asks whether a small change should be built now or designed first. Design: `docs/superpowers/specs/2026-10-19-brainstorming-split-design.md`.

### Packaging

- **The marketplace is `superpowers-remix`.** The plugin is still `superpowers`, so skills keep the `superpowers:` prefix; install this fork in place of upstream's plugin.
- **`brainstorming` keeps v7's rule about who owns platform, language and tooling choices** (#2482, #2483), stated as defaults in plain words.

```

- [ ] **Step 8: Validate the plugin**

Run: `claude plugin validate .`
Expected: last line `✔ Validation passed`.

- [ ] **Step 9: Commit**

```bash
git add .claude-plugin .agents .muse-plugin .hermes-plugin .cursor-plugin .codex-plugin .devin-plugin .kimi-plugin .antigravity-plugin gemini-extension.json package.json tests/codex/test-marketplace-manifest.sh README.md RELEASE-NOTES.md
git commit -m "chore: marketplace superpowers-remix, version 7.0.0-remix.1, fork install docs and release notes"
```

---

### Task 5: Branch verification

**Files:** none created; read-only checks over the branch.

**Interfaces:**
- Consumes: everything above.
- Produces: the evidence the PR description cites.

- [ ] **Step 1: Run every test this branch touches or that enumerates skills**

```bash
bash tests/discovering-intent/test-skill-structure.sh
bash tests/brainstorming/test-skill-structure.sh
bash tests/codex/test-marketplace-manifest.sh
bash tests/codex/test-package-codex-plugin.sh
bash tests/antigravity/test-plugin-manifest.sh
bash tests/kimi/test-plugin-manifest.sh
bash tests/devin/test-devin-plugin.sh
bash tests/version-bump/test-bump-version.sh
node tests/opencode/test-skill-registration.mjs
python -m pytest tests/hermes -q
```

Expected: each exits 0. A failure in a harness manifest test that complains about the version string `7.0.0-remix.1` means that test pins a numeric-only pattern; fix the test's pattern to accept a semver prerelease, in the same commit, and say so in the PR.

- [ ] **Step 2: Confirm no CRLF and no stray files**

Run: `git ls-files -z | xargs -0 file | grep -c CRLF`
Expected: `0`.
Run: `git status --porcelain`
Expected: empty.

- [ ] **Step 3: Confirm the two tag diffs match the spec**

Run: `git diff --stat v6.4.2 -- skills/brainstorming/` and `git diff --no-index --stat <(git show v7.0.0:skills/brainstorming/SKILL.md) skills/discovering-intent/SKILL.md`
Expected: brainstorming's diff lists only `SKILL.md`; `spec-document-reviewer-prompt.md`, `visual-companion.md` and `scripts/` show no change; the discovering-intent diff is one file.

- [ ] **Step 4: Push and open the PR**

```bash
git push -u origin brainstorming-split
```

Open the PR on GitHub from `brainstorming-split` to `main`, body: the spec path, the plan path, the test commands from Step 1 and their results, ending with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`. Do not merge; the user merges.

**After merge, by the user or on their say-so, not part of this plan:** `git push gitlab main --tags`, then on this machine `/plugin uninstall superpowers@superpowers-marketplace`, `/plugin marketplace add fcavalieri/superpowers-remix`, `/plugin install superpowers@superpowers-remix`, and confirm `/plugin` lists both `brainstorming` and `discovering-intent`. This changes the machine's plugin setup, which is why it is not a task.
