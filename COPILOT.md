# Converting this workflow to GitHub Copilot

This file gives you a prompt you can paste into any LLM — Claude, ChatGPT, Gemini — to translate this workflow into GitHub Copilot conventions. It also includes a mapping table and an honest account of what Copilot can and can't replicate.

---

## The conversion prompt

Paste this into your LLM of choice along with the contents of `CLAUDE.md` and any `commands/*.md` files you want to carry over:

---

> I have a Claude Code user-level workflow I want to convert to GitHub Copilot conventions. I'll paste the relevant files below.
>
> Please produce:
>
> **1. `copilot-instructions.md`** — a repo-level file that goes in `.github/copilot-instructions.md`. Extract everything from `CLAUDE.md` that is universally applicable coding behavior: planning, PR style, test philosophy, scope discipline, comment style, and common gotchas. Rewrite it as direct instructions to Copilot. Omit anything that is Claude Code-specific (slash commands, agent dispatch, subagent memory, OpenSpec workflow steps) — those have no Copilot equivalent and will be confusing noise.
>
> **2. A prompt file for each slash command I want to keep** — Copilot supports `.github/prompts/*.prompt.md` files that appear as reusable prompts in VS Code. For each command I specify, produce a `.prompt.md` that captures the intent and step-by-step logic of the original skill. Note that Copilot prompt files cannot run shell commands, call external APIs, or loop autonomously — the instructions must be written as guidance for the model, not as an executable script.
>
> **3. A gap analysis** — list every capability in this workflow that Copilot cannot replicate today, and for each one note the closest available workaround (custom extension, VS Code task, manual step, etc.).
>
> Here are the files:
>
> [paste `CLAUDE.md` here]
>
> [paste each `commands/*.md` file you want to convert, one at a time, labelled with its filename]

---

## Mapping table

| Claude Code concept | Copilot equivalent | Fidelity |
|---|---|---|
| `~/.claude/CLAUDE.md` (user-level) | VS Code user settings → `github.copilot.chat.codeGeneration.instructions` | Partial — injected as a system instruction, but no per-project override at user level |
| `<repo>/CLAUDE.md` (project-level) | `.github/copilot-instructions.md` | Good — injected into every Copilot chat in the repo |
| `<repo>/docs/ai-context.md` | Can be referenced in `copilot-instructions.md` via `#file:` references in VS Code | Manual — engineer must invoke the reference explicitly |
| Slash commands (`/start-ticket`, etc.) | `.github/prompts/*.prompt.md` prompt files | Partial — prompt files are reusable but not executable; they guide the model, they don't run steps |
| Subagents dispatched via Task tool | Copilot Extensions (custom, or third-party) | Low — extensions require separate development and deployment |
| `allowed-tools` per command | Not available — Copilot doesn't expose tool-level permission scoping | None |
| `model: opus` per command | Not available — model selection is account/plan-level, not per-prompt | None |
| Persistent memory (`~/.claude/projects/*/memory/`) | Not available natively; can approximate with a `CONTEXT.md` the engineer maintains manually | None |
| `AskUserQuestion` (structured multi-choice) | Copilot asks free-form follow-up questions; no structured choice UI | Partial |
| OpenSpec workflow (`/opsx:*` commands) | No equivalent; would need to be rebuilt as a series of prompt files or a custom extension | None natively |
| `/grill-with-docs` (interview loop) | Approximate with a `.prompt.md` that instructs Copilot to ask one clarifying question at a time, but it won't loop autonomously | Weak approximation |
| HIPAA agent (reads domain-docs, cites CFR) | A `.prompt.md` that instructs Copilot to apply the same checks, backed by a `#file:docs/domain/hipaa.md` reference | Partial — depends on the engineer attaching the right file; no enforcement |
| Git/shell tool use (branch creation, PR opening) | Copilot CLI (`gh copilot suggest`) can help draft commands, but won't execute them | None automatically |

---

## What translates well

- The coding standards in `CLAUDE.md` — planning requirement, PR style, test philosophy, scope discipline, comment style — map directly into `copilot-instructions.md` with minimal rewriting.
- The *intent* of most slash commands can be captured as prompt files that guide Copilot through the same steps a human engineer would follow.
- The domain reference doc pattern (back every compliance agent with a citable doc) works in Copilot via `#file:` attachments in chat, though the engineer has to attach them manually rather than having the agent load them automatically.

## What doesn't translate

- **Autonomous multi-step execution** — Claude Code skills run loops, create files, make git commits, and call external APIs without human intervention between steps. Copilot prompt files are single-shot; the engineer drives each step.
- **Subagent dispatch** — spawning a parallel `hipaa-compliance` agent while the main agent continues implementing is a Claude Code-specific capability with no Copilot equivalent today.
- **Per-session memory** — Claude Code accumulates facts across a session and persists them across conversations. Copilot has no equivalent; context resets each chat.
- **OpenSpec workflow** — the full `/start-ticket` → `/grill-with-docs` → `/opsx:propose` → implement sequence is deeply integrated with Claude Code's tool use and looping. Rebuilding it in Copilot would require a custom extension.
- **Tool permission scoping** — `allowed-tools: Bash(git:*)` restricts what a skill can do. Copilot has no tool-level sandboxing.

---

## Recommended starting point

If you're setting up a project that needs to work with both Claude Code and Copilot, the pattern used in `work.developertown.com` is the cleanest approach:

1. Write `docs/ai-context.md` as the single canonical reference — stack, architecture, rules, testing strategy, domain invariants.
2. Write `CLAUDE.md` that points Claude at `docs/ai-context.md` and adds Claude-specific configuration (agent system, slash commands).
3. Write `.github/copilot-instructions.md` that pulls the universal rules from `docs/ai-context.md` and strips everything Claude-specific.
4. Add a `/sync-docs` skill (or equivalent) that flags when `CLAUDE.md` and `copilot-instructions.md` have drifted from `docs/ai-context.md`.

That way the source of truth is harness-agnostic, and each AI harness gets a tailored view of it.
