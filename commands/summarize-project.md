---
description: Summarize a project for performance review or resume — what was built, the tech decisions, and the agentic workflows
argument-hint: "[project name or path]"
allowed-tools: Read, Grep, Glob, Bash(git:*), Bash(ls:*), Bash(find:*), Bash(cat:*)
model: opus
effort: high
---

# /summarize-project

Generate a brag-worthy project summary suitable for a performance review or resume. The goal is to surface not just *what was built* but the judgment calls, delivery approach, and agentic workflows that made the work notable.

**Ground rule:** report only what you verified from the files. Mark inferences as inferences. Do not pad with generic praise — specifics are what make this useful in a review conversation.

---

## Step 1 — Locate the project

If an argument was given, treat it as the project name or path. Otherwise use the current working directory. Confirm it's a code project (has a manifest, source files, or `.git`). If multiple projects exist under the cwd, ask which one to summarize.

---

## Step 2 — Gather the evidence

Read as much as is available before synthesizing. Dispatch **Explore** subagents in parallel to cover:

- **Product purpose** — README, any `docs/`, OpenSpec proposals (`openspec/`), SOW or plan docs (e.g. `*_PLAN.md`, `*_SOW*.md`)
- **Tech stack** — manifests (`package.json`, `*.csproj`, `pyproject.toml`, `go.mod`, etc.), config files, Dockerfiles, CI/CD workflows
- **Architecture & notable decisions** — `CLAUDE.md`, `AGENTS.md`, architectural docs, key source files (entry points, domain logic, data layer)
- **Agentic workflows** — `CLAUDE.md`, `AGENTS.md`, `openspec/` directory, `DEBRIEF.md`, any skill or agent config files
- **Scale & compliance signals** — git log (`git log --oneline | wc -l` for commit count), file counts, regulatory keywords (HIPAA, PCI, SOC 2, GDPR), test coverage indicators, deployment targets

Have each subagent return a tight findings summary with file references — not raw file dumps.

---

## Step 3 — Synthesize and write the summary

Produce a summary in this format. Be specific and concrete — cite numbers, file names, and actual decisions. Cut anything generic.

```markdown
# <Project Name> — Project Summary

**Role:** <Solo developer / Feature developer / Tech lead / etc.>
**Date:** <Approximate timeframe>
**Stack:** <Languages, frameworks, key libraries, infra — dense, comma-separated>

## What It Is

<2–3 sentences: what the product does, who uses it, what environment it operates in. Include the stakes — clinical, financial, real-time, high-volume, etc.>

## Technical Highlights

For each highlight, lead with a bold title that names the decision, then explain the constraint that made it interesting, and the specific solution. Aim for 3–5 highlights. Examples of what makes a highlight worth including:
- Non-obvious data modeling (worked around a schema constraint, avoided a migration)
- Security or compliance controls that required real engineering (not just "added auth")
- Performance or reliability decisions with measurable context
- Architectural choices that simplified something that would otherwise be messy

## Agentic Workflow

What was notable about how the work was approached, governed, or delivered with AI tooling. Include:
- Any multi-agent systems, governance hierarchies, or conflict-resolution rules
- Structured workflows (OpenSpec gates, required review passes, proposal-before-implementation)
- Delivery scale (commit count, file count, solo vs. team, timeline)
- Documented learnings (DEBRIEF findings, retros, role reframes)

Omit this section if there was nothing agentic or AI-assisted about the workflow.

## Scale & Compliance

Bullet list of concrete indicators:
- Commit count, file count, record/entity counts
- Regulatory frameworks applied (HIPAA, PCI, SOC 2, GDPR, WCAG) and how
- Deployment targets and infrastructure
- Test coverage approach
```

---

## Step 4 — Offer to save

After presenting the summary in chat, ask the user if they want it saved to a file. If yes:

1. Suggest a filename (kebab-case project name, e.g. `abc-tablet-app.md`)
2. Default save location: `~/Documents/dt/project_summaries/` if it exists, otherwise the project root
3. Write the file using the Write tool
