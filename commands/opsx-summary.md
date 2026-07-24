---
name: "OpenSpec Summary"
description: Summarize the current OpenSpec change — what's being built, key decisions, PHI/compliance notes, and open questions.
---

# /opsx-summary

Produce a concise summary of the active OpenSpec change. Read the artifacts in the current change directory and present a structured brief the user can share or reference.

---

## Step 1 — Find the active change

Run:

```bash
openspec status --json 2>/dev/null || find openspec/changes -mindepth 1 -maxdepth 1 -type d | head -20
```

If multiple changes exist, pick the most recently modified one (check `tasks.md` modification time). If it's ambiguous, list the options and ask the user which one to summarize.

---

## Step 2 — Read the artifacts

Read whichever of these exist in the change directory:

- `proposal.md` — what and why
- `hipaa-review.md` — PHI contact and compliance decisions
- `design.md` — key technical decisions
- `security-check.md` — findings and their severities
- `tasks.md` — count total tasks and completed tasks

Read all in parallel.

---

## Step 3 — Output the summary

Present exactly this structure:

```
## [Change Name]

**What's being built:**
2–4 bullet points drawn from proposal.md — new screens, components, or integrations. Be specific.

**Key architecture decisions:**
2–4 bullet points from design.md — data layer, state management, API pattern, offline strategy.

**PHI / compliance:**
- List each resolved PHI field decision (included/excluded from which surface, and why)
- Note any open compliance questions that still need sign-off
- Flag any BLOCKER in security-check.md in bold

**Security findings:**
| Severity | Finding | Mitigation |
(from security-check.md — omit if no findings)

**Progress:** X / Y tasks complete
**Open questions:** bullet list from design.md and hipaa-review.md (resolved items omitted)
```

Keep each section tight — this is a handoff brief, not a document dump.
