---
description: Scaffold an authoritative, citable domain/compliance reference doc that agents must follow
argument-hint: "[domain, e.g. HIPAA]"
allowed-tools: Read, Write, Glob, Grep, WebFetch, WebSearch, Bash(git:*)
model: opus
effort: high
---

# /domain-doc

Turn a fuzzy domain or regulatory constraint into a **concrete reference document** that agents (and people) can cite rule-by-rule — so enforcement is grounded in real requirements instead of a persona improvising.

**Accuracy guardrail (read first):** Do not state domain or legal requirements from memory. Everything normative in the output must trace to a source the user provides or points you to. Anything you can't source gets marked **`UNVERIFIED — needs SME/legal review`**. When in doubt, say so rather than filling the gap. This doc is a working draft to be reviewed by a qualified human, not legal advice.

---

## Step 1 — Identify the domain and why it applies

From the argument or by asking (**AskUserQuestion**):

- **Which domain / regulation?** (e.g. HIPAA, PCI-DSS, WCAG 2.2 AA, SOC 2, GDPR, or a specific client's business rules)
- **What does this application actually do that triggers it?** — the concrete hook. (e.g. "stores patient names + appointment data" → PHI → HIPAA). This scopes the doc to what's relevant instead of the entire regulation.
- **Who owns sign-off?** — the SME, compliance contact, or client stakeholder who can verify it.

---

## Step 2 — Gather authoritative sources

First, check the **shared domain-docs library** at `~/Documents/dt/domain-docs/` for an existing reference for this domain (SOC 2, HIPAA, PCI DSS, WCAG, GDPR, …). If one exists, use it as the primary source layer and cite it — the per-project doc should map those general rules to this application, not re-derive them.

Then ask the user for any project-specific source material and use it alongside:

- Links to the regulation/standard, internal compliance docs, client requirement docs, BAAs, prior audit findings, or a security review.
- If they give URLs, fetch them (`WebFetch`); if they name a public standard and approve a lookup, `WebSearch` for the authoritative source. Prefer primary sources.

If the user has **no** sources, do not invent requirements. Draft the structure with placeholders and mark every normative item `UNVERIFIED`, then make collecting sources the top action item.

---

## Step 3 — Draft the reference doc

Default path: `docs/domain/<domain-slug>.md` (confirm or adjust). Give every rule a **stable ID** (`HIPAA-01`, `WCAG-03`, …) so agents can cite it precisely.

```markdown
# <Domain> Reference — <Application>

**Status:** DRAFT — requires review by <owner/SME> before relied upon
**Owner / sign-off:** <name or TBD>
**Last updated:** <today's date>
**Sources:** <list of the authoritative sources used, with links>

## Scope — why this applies here
<The concrete trigger: what this app does (data, flows, users) that brings it under this domain, and what is explicitly out of scope.>

## Rules
Each rule: what's required, how it maps to *this* application, its source, and verification status.

### <ID> — <short name>
- **Requirement:** <the normative rule, in plain terms>
- **Applies here:** <the specific screens / data / flows / code areas this governs>
- **Source:** <citation + link, or `UNVERIFIED — needs SME/legal review`>
- **Status:** verified | unverified

<repeat per rule>

## How agents and reviewers use this doc
- Cite the rule ID when flagging or approving something (e.g. "blocks HIPAA-04").
- If a situation isn't covered by a rule here, say so and escalate to the owner — do not extrapolate a requirement.

## Open questions / needs review
- <items awaiting SME/legal confirmation>
```

Keep it concrete and application-specific — a generic copy of the regulation isn't the goal.

---

## Step 4 — Wire it to the enforcing agent

Look for an agent that should follow this doc:

```bash
ls .claude/agents 2>/dev/null; ls ~/.claude/agents 2>/dev/null
```

- If a relevant agent exists (e.g. a HIPAA/compliance agent), add an instruction to its definition pointing at the doc path and requiring it to **read the doc and cite rule IDs** when enforcing. Confirm the edit with the user first.
- If none exists, tell the user the doc is ready and offer to note that any future domain agent should be pointed at it.

---

## Step 5 — Report

Summarize:

- Where the doc was written.
- What's **verified** vs. **UNVERIFIED / needs SME/legal review** — be explicit; this is the part that matters.
- Which agent (if any) was wired to it.
- Top action items (usually: get authoritative sources, get owner sign-off).

Remind the user the doc is a working draft that a qualified human must review before it's treated as compliance guidance.
