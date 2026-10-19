# Brainstorming split: `brainstorming` (the how) and `discovering-intent` (the why)

## Why this exists

v7.0.0 rebuilt `skills/brainstorming` around drawing out intent
(`2026-10-05-brainstorming-rebuild-design.md`; upstream `dev` commits
9e63918 / #2463, 36319ad / #2482, 112fc16 / #2483). The rebuild replaced the
HOW conversation of v6.4.2 (clarifying questions, two or three approaches with
trade-offs, a sectioned design covering architecture, components, data flow,
error handling and testing, then a spec) with a WHY conversation (open
describing questions, goals, non-goals, anti-goals, playback, a builder check).
Upstream lists "designing architecture the human didn't ask to decide" as a
non-goal of the new skill.

Both conversations are valuable, at different moments. When the what and why
are already clear, the v6.4.2 skill produced deep questions about how to build
the thing; the v7 skill asks the why again and leaves the how to the builder.
This fork keeps both, as two skills, and lets each hand off to the other.

## Goals

- `brainstorming` behaves like v6.4.2 again: it designs HOW to build something
  whose purpose is understood, and keeps the universal "use before any creative
  work" trigger.
- `discovering-intent` behaves like v7.0.0: it draws out WHAT someone wants and
  WHY, plays it back, and writes an intent document.
- Either skill can route to the other, and the user can override the routing in
  one phrase.
- The fork installs from its own marketplace without colliding with upstream's.

## Non-goals

- Changing the visual companion, its server, or its tests.
- Changing writing-plans or anything downstream of a design spec.
- Rewriting upstream's harness packaging beyond registering the new skill.
- Behavioural evals. The split is verified by reading, by static tests, and by
  use.

## The two skills

### `brainstorming` (the how)

`skills/brainstorming/SKILL.md` is restored from v6.4.2, with three edits:

1. **"Establish Shared Understanding" becomes the redirect.** The v6.4.2
   opener asked one focused question about purpose and wrote back a note. It is
   replaced by a short "First: do you know what and why?" check:
   - The what and why are clear (the request names the outcome, who it is for
     and the constraints, or an intent document for this topic exists under
     `docs/superpowers/intents/`): say so in one line and continue with the
     three-path process.
   - Something non-trivial about the what or why is missing: say "I'll find out
     what you're after first" and invoke `superpowers:discovering-intent`. When
     it hands back, resume here using its playback or intent document as the
     brief, and do not re-ask what it settled.
   - Overrides, said out loud so the user can correct them: "just design it"
     skips the redirect; "let's talk about why first" takes it.
2. **"How it gets made" is merged in** (v7's #2482/#2483 rule): find out early
   which platform, language, library or medium choices the user wants to own
   and which they hand over; state defaults in plain words; build on what an
   existing project already uses; record the agent's own calls as its calls,
   never as agreed. In this skill it lives in "Understanding the idea", next to
   purpose, constraints and success criteria.
3. **The trigger description** keeps v6.4.2's wording and adds one clause:
   "Designs HOW to build something whose purpose is clear; redirects to
   discovering-intent when the what or why is not."

Everything else is v6.4.2 verbatim: the HARD-GATE, the three paths (spike,
bounded, architectural), the checklists, the process flow, the design
sections, spec self-review, the user review gate, and the hand-off to
writing-plans. `spec-document-reviewer-prompt.md` is restored beside it.
`builder-check-prompt.md` moves to the new skill.

`visual-companion.md` and `scripts/` stay in this directory and are shared
(see below).

### `discovering-intent` (the why)

`skills/discovering-intent/SKILL.md` is the v7.0.0 `brainstorming/SKILL.md`,
renamed, with these edits:

1. **Name and trigger.** `name: discovering-intent`. Description: "Use when
   what someone wants, or why, is not yet clear: a new idea, a vague feature
   request, a project without a brief, anything where you would be guessing at
   the purpose. Draws out intent, goals and anti-goals through questions that
   get them describing, plays it back, and writes an intent document. Hands off
   to brainstorming for the how." It no longer claims "use before any creative
   work"; that trigger belongs to `brainstorming`.
2. **The intent document** goes to
   `docs/superpowers/intents/YYYY-MM-DD-<topic>-intent.md`, committed, in a
   software repo; otherwise ask. User preferences override. The content list
   (intent and the why; goals, non-goals, anti-goals; constraints; the parts of
   the how they decided; what is left to the builder) is unchanged. The builder
   check (`builder-check-prompt.md`, moved here) still gates the hand-over.
3. **Sizing becomes a hand-off.** The three sizes stay, with new "Then"
   columns:

   | Size | The full description | Then |
   |------|----------------------|------|
   | A quick, clear task | the request itself | do it |
   | A small change | in chat | ask: build it now through the normal workflow, or design the how first with brainstorming? Do what they pick. |
   | A project | the intent document | invoke `superpowers:brainstorming`, which designs from the approved intent and owns the approaches, the design, the spec and the writing-plans hand-off |

   The question for a small change is one sentence, asked once, after the
   playback is approved. "Just build it" and "design it first" are both valid
   answers and nothing is assumed when they do not answer.
4. **The HARD-GATE** keeps its text except for the last paragraph, which now
   reads: after a project's intent document is approved, the next step is
   `superpowers:brainstorming`, not writing-plans. The opt-out and spike
   exceptions are unchanged.
5. **The visual companion** section stays, and the last line points at
   `skills/brainstorming/visual-companion.md` and
   `skills/brainstorming/scripts/` instead of "this directory".

Everything else is v7.0.0 verbatim: the opening check, the first message, the
conversation guidance, "how it gets made", playback, red flags.

### Shared files

`visual-companion.md`, `scripts/` and `tests/brainstorm-server/` are not
duplicated. They stay under `skills/brainstorming/` and `discovering-intent`
references them by path. Both skills already instruct the agent to read the
guide before starting the server, so a path is enough.

## Routing

The route lives in three places, each one short:

- **`using-superpowers`** gains two lines beside "Let's build X →
  superpowers:brainstorming":
  - "I have an idea" / "I want something like..." / a request whose purpose
    you would have to guess → `superpowers:discovering-intent`, then
    brainstorming.
  - "Let's build X" with a clear outcome → `superpowers:brainstorming`.
- **`brainstorming`'s opening check** redirects to `discovering-intent` when
  the why is missing, as described above.
- **`discovering-intent`'s sizing** hands projects to `brainstorming`, asks for
  small changes, and does quick tasks directly.

Each redirect is announced in one line before it happens, so the user can
override it, matching how v6.4.2 announced its path classification. A skill
that invokes the other stays loaded, so the invoking skill's "resume here"
instruction is what brings control back.

## Packaging and references

- **Marketplace name** becomes `superpowers-remix` in
  `.claude-plugin/marketplace.json`, `.agents/plugins/marketplace.json` and
  `.muse-plugin/marketplace.json`; `tests/codex/test-marketplace-manifest.sh`
  asserts the new name. The **plugin name stays `superpowers`** so every
  `superpowers:*` reference keeps working; the fork is installed in place of
  upstream's plugin, not beside it:
  `/plugin marketplace add git@github.com:fcavalieri/superpowers-remix.git`,
  then `/plugin install superpowers@superpowers-remix`.
- **Version** becomes `7.0.0-remix.1` in every manifest that carries `7.0.0`
  (`package.json`, `.claude-plugin/{plugin,marketplace}.json`,
  `.antigravity-plugin`, `.codex-plugin`, `.cursor-plugin`, `.devin-plugin`,
  `.kimi-plugin`, `.muse-plugin/{plugin,marketplace}.json`,
  `gemini-extension.json`). A changed version string is what makes installed
  copies update.
- **Muse** lists skills explicitly in `.muse-plugin/plugin.json`; add
  `discovering-intent`. Codex, Kimi, Devin, OpenCode and Hermes discover skills
  from the `skills/` directory; their tests
  (`tests/opencode/test-skill-registration.mjs`, `tests/hermes/test_plugin.py`)
  enumerate the directory and need no change.
- **README** skill list (lines 310 and 353 at v7.0.0) describes both skills and
  the install commands point at this fork. **AGENTS.md** acceptance test
  ("auto-triggers the `brainstorming` skill before any code") still holds,
  since `brainstorming` keeps the trigger.
- **RELEASE-NOTES.md** gains a `## v7.0.0-remix.1` section at the top
  describing the split and the rename, above upstream's entries.
- `docs/superpowers/intents/` is created with the first intent document the
  skill writes; no placeholder file is committed.

## Decisions

- `brainstorming` keeps the name and the universal trigger; the HOW behaviour
  is what fires by default (user decision, 2026-10-19).
- The intent skill is `discovering-intent`: gerund-first like the other
  skills, upstream's own phrase for the rebuild, and it names the deliverable.
- Intent documents live in `docs/superpowers/intents/`, separate from design
  specs, so the how skill's "an intent document exists" check is mechanical
  (user decision).
- A small change asks the user whether to build now or design first; a quick
  task is done directly; a project always goes through `brainstorming` (user
  decision).
- v7's "how it gets made" rule is merged into the restored `brainstorming`
  (user decision); it stays in `discovering-intent` too.
- Plugin name stays `superpowers`; only the marketplace is renamed (user
  decision).
- Shared visual-companion files stay in `skills/brainstorming/`; the new skill
  references them by path (builder's call: no duplication, tests unchanged).
- Version `7.0.0-remix.1` (builder's call: a semver prerelease on top of the
  upstream version it tracks, so rebases onto upstream releases read
  naturally).

## Left to the builder

- Exact wording of the redirect, the small-change question, and the two
  using-superpowers lines.
- Where in the v6.4.2 text the merged "how it gets made" paragraph sits.
- The README paragraphs for the two skills.

## Verification

- `claude plugin validate .` passes.
- `tests/codex/test-marketplace-manifest.sh`,
  `tests/opencode/test-skill-registration.mjs` and `tests/hermes/test_plugin.py`
  pass with the new skill directory present.
- `git diff v6.4.2 -- skills/brainstorming/SKILL.md` shows only the three
  edits above; `git diff v7.0.0:skills/brainstorming/SKILL.md
  skills/discovering-intent/SKILL.md` shows only the five.
- Installing `superpowers@superpowers-remix` on this machine, after
  uninstalling upstream's plugin, lists both skills.
