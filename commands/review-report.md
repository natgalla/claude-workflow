---
name: "Review Report"
description: Run /code-review, /smell, and /sync-docs in parallel, consolidate findings into a prioritized action item list, and present for approval.
model: opus
effort: xhigh
---

# /review-report

**Goal:** produce a single, de-duplicated, prioritized list of action items drawn from two quality scans. Present it for approval — do not implement anything until the user responds.

---

## Step 1 — Run the scans in parallel

Invoke all four skills in a **single message** (simultaneous Skill tool calls):

- Skill `code-review` — no args (medium effort, no `--fix`, no `--comment`)
- Skill `smell` — no args (auto-detects base branch)
- Skill `a11y-review` — no args; covers WCAG 2.1 AA accessibility and HTTP verb semantics
- Skill `sync-docs` — no args. Unlike the others (read-only), this one **acts**: it fixes and commits `README.md` if stale, and reports (without editing) stale content in `CLAUDE.md` / `AGENTS.md`.

---

## Step 2 — Synthesize findings

Once both complete, merge their outputs into one ranked list.

**De-duplication:** if both scans flag the same location for the same root cause, keep one entry and note both sources (e.g. `code-review + smell CC.G5`).

**Ranking order:**

1. BLOCKER — security, correctness, data loss, or crash risk
2. HIGH — clearly wrong; will regress behavior or maintainability
3. MEDIUM — design weakness worth fixing before merge
4. LOW — minor; in-passing fix
5. NIT — style, no real cost

Within a tier: security/correctness > maintainability > style.

**Exclusion:** skip any finding that was already fixed or explicitly deferred earlier in this conversation.

---

## Step 3 — Present the action item list

Output exactly this structure — nothing before or after it:

```
## Review Report

**Branch:** `<current-branch>`
**Scans:** `/code-review` (medium) · `/smell` · `/a11y-review` · `/sync-docs`
**Total:** N items — X blocker · Y high · Z medium · W low · V nit

| # | Severity | Source | Location | Finding | Suggested fix |
|---|----------|--------|----------|---------|---------------|
| 1 | BLOCKER  | code-review | `src/foo.ts:12` | One-line description | One-line fix |
| 2 | HIGH     | smell `CC.G5` | `src/bar.tsx:40` | One-line description | One-line fix |
| 3 | MEDIUM   | both | `src/baz.tsx:80` | One-line description | One-line fix |

**Docs:** README `<synced & committed / already current>`. Stale in CLAUDE.md/AGENTS.md: `<list, or "none">`.
```

Then ask on a new line:

> Which items would you like to address? Reply with numbers (e.g. `1, 3`), `all`, or give direction on any item.

**Stop here. Do not implement the code findings until the user responds.** (The `/sync-docs` pass has already applied and committed its README fix — that's its normal behavior; only the findings in the table await your go-ahead.)
