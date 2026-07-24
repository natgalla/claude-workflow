---
description: Generate a structured .plan.md implementation file from an OpenSpec proposal or AC, ready for /execute-plan
argument-hint: "[openspec-change-name or path to AC]"
allowed-tools: Read, Write, Glob, Bash(git:*), Bash(find:*), Bash(ls:*)
model: opus
effort: high
---

# /create-plan

Turn a settled spec (OpenSpec proposal + tasks, or raw AC + grill output) into a structured `.plan.md` ready to hand to `/execute-plan`.

---

## Step 1 — Find the source material

**Detect the current branch:**
```bash
git branch --show-current
```
Hold as `<BRANCH>`.

Locate source material in this priority order:

1. **OpenSpec change folder** — if `$ARGUMENTS` names a change, look in `openspec/changes/<name>/`. If no argument, scan `openspec/changes/*/` for a folder whose name matches the branch prefix (e.g. branch `42-add-forgot-password` → look for `openspec/changes/42-*` or `openspec/changes/*forgot-password*`). Read `proposal.md`, `tasks.md`, and any `specs/*/spec.md` files found.

2. **Grill output** — look for `CONTEXT-<BRANCH>.md` in the repo root. Read it if present — glossary terms must be used verbatim in the plan.

3. **Raw AC argument** — if `$ARGUMENTS` is a file path, read it as the AC. If it's plain text, use it directly.

If none of the above yields anything, ask the user with **AskUserQuestion** to paste the AC or point to a file.

Hold everything found as `<SPEC_CONTENT>`.

---

## Step 2 — Check for ADRs

```bash
find docs/adr -name "ADR-*.md" 2>/dev/null | sort
```

Read any ADRs found. They represent hard decisions already made — the plan must not re-open them or propose alternatives that contradict them.

---

## Step 3 — Derive the plan structure

Analyze `<SPEC_CONTENT>` and identify:

- **Phases** — logical groupings of work (e.g. Data model, API, UI, Tests). Derive from the OpenSpec `tasks.md` sections if present; otherwise infer from the AC.
- **Steps** — concrete implementation tasks within each phase, small enough to complete and verify in one sitting.
- **Checkpoints** — explicit build/test/lint validations that must pass before moving on. Place one at the end of each phase minimum.
- **Decision points** — anything the plan can't resolve from the spec alone (ambiguous requirement, unknown external dependency, choice between approaches). Mark these explicitly so `/execute-plan` surfaces them at the right moment.
- **Dependencies** — steps that must complete before others can start. Note these inline.

---

## Step 4 — Write the plan file

Write to `<BRANCH>.plan.md` in the repo root.

```markdown
# <Feature title> — Implementation Plan

**Branch:** `<BRANCH>`
**Source:** <OpenSpec change name, or "AC + grill output", or file path>
**Generated:** <today's date>

---

## Overview
<2–3 sentences: what this plan builds, the key approach, and any constraints from ADRs or the grill session.>

---

## Phase 1 — <Phase name>

### Step 1.1 — <Step title> ⏳ Pending
<Concrete description of what to implement. Reference the specific AC criterion or proposal capability this satisfies. Use terms from CONTEXT-<BRANCH>.md verbatim.>

**Files:** `<path>` (create/modify)
**Depends on:** none (or step X.Y)

### Step 1.2 — <Step title> ⏳ Pending
...

### ✔ Checkpoint 1 — <what to verify>
```bash
<build/test/lint command>
```
Expected: <what passing looks like>

---

## Phase 2 — <Phase name>

...

---

## Open questions / decision points

- [ ] **<Topic>** — <what needs to be decided before or during this step, and why it couldn't be resolved from the spec>

---

## Out of scope
<Anything the spec or AC explicitly excludes — record it so it doesn't creep in during execution.>
```

Use these status markers (same as `/execute-plan`):
- `⏳ Pending` — not yet started
- `🔄 In Progress` — currently being worked on
- `✅ Done` — approved and complete
- `❌ Blocked` — cannot proceed, needs resolution
- `⚠️ Modified` — implemented differently than planned

---

## Step 5 — Report

Tell the user:
- Path to the generated plan file
- Phase count and total step count
- Any open questions that need answers before execution starts
- That the plan is ready for `/execute-plan <BRANCH>.plan.md`
