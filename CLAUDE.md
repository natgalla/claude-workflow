# Personal instructions (all projects)

## Planning before implementation
Before writing any code, always present a plan and wait for explicit approval. This applies even when the request seems straightforward or the scope is clear. The plan should cover:
- What each change is and why
- Any assumptions or open questions
- Any risks (migrations, breaking changes, new routes, external side effects)

Do NOT start implementing until the user says something like "go ahead", "looks good", "yes", or otherwise clearly approves. A list of tasks is not approval to start. When in doubt, ask.

## Pull request descriptions
Prioritize the reviewer's experience above all: a reviewer should understand the change and know how to validate it in the least time possible. Be clear and concise — favor short paragraphs and tight bullets over prose, lead with the most important information, and cut anything that doesn't help the reviewer.

Write PR descriptions around two things only: **what changed** and **how to test/validate it**.

Do NOT include narration of the development process. In particular, omit:
- self-run review passes (code-review, smell, lint, dead-code sweeps) and any "review fixes applied" section
- "NITs intentionally kept" / rationale for internal cleanup decisions
- iteration history or a changelog of how the branch evolved

Those are part of normal development, not reviewer-facing content. Present the change as it stands.

## Tests
Tests must validate the **requirements**, not just the implementation. Write tests against the behavior the code is supposed to deliver — the acceptance criteria, contract, or spec — so they would still catch a regression if the implementation were rewritten. Avoid tests that merely mirror the current code (asserting on internal calls, restating the implementation, or passing only because they were written to match what the code happens to do). If the implementation is wrong, the test should fail.

## Style
- **No semicolons** in written prose or bullet points — use a dash, period, or restructure the sentence.

## Common gotchas
- **Scope discipline** — change only what was asked. No drive-by refactors, renames, or "while I'm here" cleanups. If you spot an unrelated problem, surface it instead of fixing it silently.
- **Match existing conventions** — reuse the codebase's patterns, idioms, and libraries. Don't introduce a new dependency or pattern when one already exists; ask before adding a dependency.
- **Comments: why, not what** — write a comment when the *why* is non-obvious: a hidden constraint, a deliberate tradeoff, a workaround for a specific behavior. Do not write comments that narrate the change ("added X to fix Y"), restate what the code plainly does, or leave TODOs nobody asked for. When in doubt, a well-placed *why* comment is better than silence.
- **Edge cases & data correctness** — handle null/empty/boundary inputs, use timezone-aware dates, use decimal (not float) for money, and be deliberate about encoding.

## Domain knowledge & agents
When a project carries domain-specific or regulatory constraints (HIPAA, PCI, WCAG/accessibility, SOC 2, or a client's business rules), any agent or workflow meant to enforce them must be backed by **concrete, citable reference documentation** — the actual rules distilled into a doc that lives in the repo — not just a role description. A persona with no source will improvise and sound confident while doing it. Do not state domain or legal requirements from memory; ground them in provided/authoritative sources and mark anything unverified as needing SME/legal review. If I stand up such an agent, or ask you to enforce a domain constraint, without a reference doc behind it, flag the gap and offer to scaffold one (`/domain-doc`). Agents should cite the specific rule they're applying by its ID.

## OpenSpec workflow
For DeveloperTown projects, feature work and data-touching changes are expected to go through the OpenSpec (OPSX) workflow when the repo has it set up. Detect this by an `openspec/` directory, `/opsx:*` commands, or skills like `start-ticket` that scaffold an OpenSpec proposal.

The full pre-implementation sequence is:

```
/grill-with-docs  →  CONTEXT.md + ADRs  →  /opsx:propose  →  implement
```

- **`/grill-with-docs`** comes first — it's a one-question-at-a-time alignment interview that resolves fuzzy AC language into a `CONTEXT.md` glossary and records hard one-way decisions as ADRs in `docs/adr/`. Run it before writing the proposal so the proposal uses settled terminology.
- **`/opsx:propose`** consumes the AC and `CONTEXT.md`. The proposal must use terms exactly as defined in `CONTEXT.md` and reference any ADRs created during the grill session.
- `/start-ticket` runs both steps automatically — grill first, then propose. It auto-detects GitHub vs Azure DevOps from the git remote URL and uses `gh` or `az boards`/`az repos` accordingly.

If I'm about to start feature work in a repo that has OpenSpec configured and no proposal exists yet, flag it and confirm before proceeding rather than silently skipping it. If a proposal exists but no grill session ran, check whether `CONTEXT.md` exists; if not, offer to run `/grill-with-docs` retroactively before implementation begins.
