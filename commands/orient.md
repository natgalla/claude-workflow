---
description: Explore an unfamiliar codebase and summarize its stack, architecture, structure, and key functionality
argument-hint: "[path or subdir to focus on]"
allowed-tools: Read, Grep, Glob, Bash(git:*), Bash(ls:*), Bash(find:*), Bash(cat:*), Bash(head:*)
model: opus
effort: high
---

# /orient

Build an accurate mental model of a codebase and hand it back as a structured summary. This is for **a human to read** — it does not write `CLAUDE.md` (that's `/init`; offer it at the end if the user wants the summary persisted for agents).

**Ground rule:** report only what you verified from the files. Mark inferences as inferences, and put anything you couldn't determine under "Unknowns" rather than guessing. A confident-but-wrong architecture summary misleads everything downstream.

---

## Step 1 — Scope

If an argument was given, focus on that path/subdir; otherwise use the repo root (cwd). Confirm it's a code repo (has a manifest, source files, or `.git`); if it's empty or not a codebase, say so and stop.

---

## Step 2 — Map the surface (cheap, do this yourself — manifests only)

Read only top-level dependency manifests: `package.json`, `pyproject.toml`, `requirements.txt`, `go.mod`, `Gemfile`, `pom.xml`, `build.gradle`, `Cargo.toml`, `composer.json`, and equivalent `*.csproj` / `*.sln` files. These give you the stack and key libraries without pulling in config files.

Do not read README or config files inline in Step 2 — those go to the subagent pass in Step 3.

Also get the directory shape:
- **Shape** — the directory tree a couple of levels deep (`git ls-files` or `find` with a depth limit) to see how the project is organized.

---

## Step 3 — Fan out with subagents (keep it cheap and your context lean)

Dispatch several **Explore** subagents in parallel — one per area — and have each return a **tight summary, not raw file contents**. This keeps the token-heavy reading out of your main context and off the expensive model. Include one subagent for non-manifest surface files: `README`, framework/build configs (`tsconfig`, `next.config`, `vite.config`, Django `settings`), `Dockerfile`/`compose`, CI configs, `.env.example`, and `Makefile`. Typical areas (adapt to the project):

- Entry points & app bootstrap (how it starts, wiring, config loading)
- Data model & persistence (schema, ORM/models, migrations, datastore)
- API / routes / UI surface (what's exposed, major screens or endpoints)
- Auth, permissions, and external integrations (third-party APIs, services)
- Tests & how the project is built/run

Give each subagent a specific question and ask for a concise findings summary with file references, not dumps.

---

## Step 4 — Synthesize and present

Combine the surface scan and subagent findings into the summary below. Keep it dense and skimmable; cite representative paths so the reader can jump in.

```
# <Project> — Orientation

## Stack
<languages, runtime, framework(s), package manager, key libraries, datastore, infra/deploy.>

## Architecture
<The overall shape (monolith / service / layered / MVC / event-driven / etc.), the major components, and how they interact / how data flows. A sentence or two, then the pieces.>

## Structure
<Key directories and what lives in each — the map a newcomer needs.>

## Key functionality
<What the application actually does — its primary features and the entry points that implement them.>

## Data & integrations
<Data model / storage, and external services, APIs, or systems it depends on.>

## Running it
<How to install, build, run, and test — pulled from scripts / Makefile / README, not invented. Note entry points.>

## Conventions & patterns
<Notable idioms worth matching: state management, error handling, config, naming, testing approach.>

## Unknowns & risks
<What you couldn't determine, plus tech-debt or fragility signals. If the code handles regulated/sensitive data (PHI, payments, PII), flag it here and note that a domain reference (/domain-doc) may be warranted.>
```

---

## Step 5 — Offer next steps

Present the summary, then briefly offer:

- To persist it for agents as a `CLAUDE.md` via `/init`.
- To go deeper on any one area.
- To save the summary to a file if the user wants it (note it won't be git-ignored unless they add it).
