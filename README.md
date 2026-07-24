# DeveloperTown Claude Code Workflow

User-level Claude Code configuration for DeveloperTown engineers. Drop it into `~/.claude/` and you get a consistent set of coding standards, slash commands, and agents that work across every project.

See [COPILOT.md](COPILOT.md) for instructions on converting this workflow to GitHub Copilot conventions.

---

## How Claude Code configuration works

Claude Code has two layers of configuration that compose together:

**User-level** (`~/.claude/`) — this repo. Rules, skills, and agents that apply in every project you open. Think of it as your personal engineering standards and toolbox.

**Project-level** (`.claude/` inside the repo) — project-specific rules, agents, and skills committed alongside the code. They layer on top of your user config.

When you open a project, Claude Code merges both layers. Your user CLAUDE.md sets the universal floor; the project CLAUDE.md adds repo-specific invariants on top.

---

## What's in this repo

### `CLAUDE.md` — universal engineering standards

Injected into every Claude Code session automatically. Covers:

- **Plan before code** — Claude presents a plan and waits for explicit approval before writing anything. No silent implementations.
- **PR descriptions** — structured around what changed and how to test it. No dev-process narration.
- **Tests validate requirements** — tests are written against the spec or acceptance criteria, not the implementation. A test that mirrors the code isn't a test.
- **Style** — no semicolons in prose, comments explain *why* not *what*.
- **Scope discipline** — change only what was asked. Unrelated problems get surfaced, not silently fixed.
- **Domain knowledge & agents** — any agent enforcing a regulatory or domain constraint must be backed by a concrete reference doc, not a role description. The HIPAA agent in this repo is an example of this pattern.
- **OpenSpec workflow** — for DeveloperTown projects that have OpenSpec configured, Claude knows the full ticket-to-PR sequence and won't skip steps.

### `commands/` — slash commands (skills)

Invoked as `/command-name` inside any Claude Code session. These are the workhorses of the daily workflow.

#### Feature workflow

| Command | What it does |
|---|---|
| `/start-ticket` | Full ticket-to-branch-to-proposal in one step — claims the issue, creates the branch, runs `/grill-with-docs`, then scaffolds an OpenSpec proposal. Works with GitHub and Azure DevOps. |
| `/grill-with-docs` | One-question-at-a-time alignment interview. Resolves fuzzy AC language into a branch-scoped `CONTEXT-<branch>.md` glossary and writes ADRs for hard one-way decisions. Run this before writing any spec. |
| `/create-plan` | Generates a structured `.plan.md` implementation file from an OpenSpec proposal or raw AC, ready for `/execute-plan`. |
| `/execute-plan` | Steps through a `.plan.md` file with human approval at each step. |
| `/status` | One-view summary of the current ticket — branch, linked work item, PR, OpenSpec proposal, and grill session. |

#### Review & quality

| Command | What it does |
|---|---|
| `/review-report` | Runs `/code-review`, `/smell`, `/a11y-review`, and `/sync-docs` in parallel and consolidates findings into a prioritized list. The standard pre-PR quality pass. |
| `/smell` | Scans the diff for code smells against the Clean Code + GoF + Python catalogs. |
| `/a11y-review` | Checks the diff for WCAG 2.1 AA violations and HTTP verb correctness. |
| `/security-review` | Reviews the diff against an OWASP Top 10 reference doc plus project-specific invariants. |

#### PR lifecycle

| Command | What it does |
|---|---|
| `/create-pr` | Commits remaining changes, runs the pre-PR review, pushes, and opens a **draft** PR linked back to the originating issue. GitHub and ADO. |
| `/address-review` | Fetches PR review threads, works through each one, replies/resolves, and re-requests review. |
| `/ready-for-review` | Marks the PR ready for review and optionally requests a specific reviewer. |
| `/merge-pr` | Verifies approval and merges. GitHub and ADO. |
| `/sync-branch` | Fetches the base branch and rebases (or merges) the current feature branch onto it. |

#### Communication & reporting

| Command | What it does |
|---|---|
| `/draft-message` | Drafts a clear client-facing message for non-technical audiences. |
| `/sprint-report` | Summarizes project board status and drafts an email for your PM and supervisor. |
| `/debrief` | Post-project interview that synthesizes the conversation into a `DEBRIEF.md`. |
| `/summarize-project` | Summarizes a project for a performance review or resume. |

#### Utilities

| Command | What it does |
|---|---|
| `/orient` | Reads an unfamiliar codebase and summarizes its stack, architecture, and key functionality. Good first step on a new repo. |
| `/bug-triage` | Fetches an issue, validates it, finds the root cause, assesses impact, and produces an implementation plan. |
| `/domain-doc` | Scaffolds an authoritative, citable reference doc for a domain or compliance area (HIPAA, PCI, WCAG, etc.). Agents must be backed by one of these — not just a role description. |
| `/opsx-summary` | Summarizes the current OpenSpec change — what's being built, key decisions, open questions. |
| `/ui-critique` | Reviews a screenshot or screen description for UI/UX issues. |
| `/playwright-cli` | Reference guide for browser automation with the playwright-cli tool. |

### `agents/` — subagents

Project agents that Claude Code can spin up as parallel workers via the Task tool. Right now there's one:

**`hipaa-compliance`** — HIPAA Privacy, Security, and Breach Notification Rule reviewer. Applies five checks (PHI contact, minimum necessary, Security Rule safeguards, audit trail, breach surface) to code, data models, and feature proposals. Cites specific 45 CFR rules — never improvises regulatory requirements. Backed by the `~/Documents/dt/domain-docs/hipaa.md` reference doc. Returns findings at BLOCKER / HIGH / MEDIUM / LOW severity.

**This pattern is repeatable.** For any domain or compliance area a project carries — PCI, WCAG, SOC 2, a client's specific business rules — the same two-step setup applies: run `/domain-doc <domain>` to scaffold a citable reference doc, then write an agent that reads that doc and applies it to code and proposals. The agent is only as good as its reference; a role description with no source will improvise. The HIPAA agent is the template.

---

## How this connects to project-level setup

DeveloperTown projects that are fully configured (like `work.developertown.com`) add a second layer on top of this user config:

```
~/.claude/CLAUDE.md          ← universal rules (this repo)
~/.claude/commands/          ← shared skills (this repo)
~/.claude/agents/            ← shared agents (this repo)
        +
<repo>/.claude/agents/       ← project-specific agents
<repo>/.claude/skills/       ← project-specific skills
<repo>/CLAUDE.md             ← project rules that supplement, not replace, user rules
<repo>/AGENTS.md             ← agent lifecycle table for this project
<repo>/docs/ai-context.md    ← canonical project reference, shared across all AI harnesses
```

The project CLAUDE.md points Claude at `docs/ai-context.md` first — a single source of truth that both Claude Code and GitHub Copilot (`copilot-instructions.md`) derive from. When they drift, the project's `/sync-docs` skill surfaces it.

### The OpenSpec workflow end-to-end

For feature work on a project that has OpenSpec configured:

**1. Kick off** — `/start-ticket <issue>` handles provider detection (GitHub vs Azure DevOps), creates the branch, assigns the ticket, then automatically runs `/grill-with-docs` and `/opsx:propose`.

**2. Align** — `/grill-with-docs` produces `CONTEXT-<branch>.md` (glossary of settled terms) and ADRs for hard one-way decisions. Run automatically by `/start-ticket`.

**3. Design** — `/opsx:propose` creates all artifacts (`proposal.md` + `design.md` + `tasks.md`) in one shot. Run automatically by `/start-ticket`. Use `/opsx:new-change` instead if you want to walk through each artifact one at a time with your input between each.

**4. Implement:**

| Step | Command | Output |
|---|---|---|
| 4 | `/opsx:apply-change` | implements tasks from `tasks.md`, checks them off as it goes |
| 5 | `/opsx:verify-change` | implementation sign-off against the change artifacts |
| 6 | `/create-pr` | draft PR, linked to issue |

**5. Ship:**

| Step | Command | Output |
|---|---|---|
| 7 | `/opsx:archive-change` | OpenSpec change archived alongside the PR |
| 8 | `/ready-for-review` | PR marked ready, reviewer requested |
| 9 | `/address-review` | review threads resolved |
| 10 | `/merge-pr` | — |

You can also run `/grill-with-docs` standalone on any repo, even ones without OpenSpec.

---

## Installation

```bash
bash install.sh
```

The script copies `CLAUDE.md`, `commands/`, and `agents/` into `~/.claude/`, backing up any existing files first. See `install.sh` for what it does before it does it.

### Manual install

```bash
# Back up what you have
cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak 2>/dev/null

# Copy config
cp CLAUDE.md ~/.claude/CLAUDE.md
cp -r commands/ ~/.claude/commands/
cp -r agents/ ~/.claude/agents/
```

---

## Converting to GitHub Copilot

See **[COPILOT.md](COPILOT.md)** — a prompt you can give any LLM to translate this workflow into Copilot conventions (`copilot-instructions.md`, prompt files, Copilot Extensions). It includes a mapping table and a plain-English explanation of what Copilot can and can't replicate.
