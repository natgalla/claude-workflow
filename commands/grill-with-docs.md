---
description: One-question-at-a-time alignment interview that resolves fuzzy requirements into a CONTEXT-<BRANCH>.md glossary and ADRs before any spec or code is written
argument-hint: "[feature description or path to issue AC]"
allowed-tools: Read, Write, Edit, Bash(ls:*), Bash(mkdir:*), Bash(git:*)
model: opus
effort: high
---

# /grill-with-docs

Conduct a relentless, one-question-at-a-time interview to eliminate ambiguity from a feature before a proposal is written. Output is a branch-scoped `CONTEXT-<branch>.md` glossary and, for hard one-way decisions, ADRs under `docs/adr/`.

Stop when there is nothing left to clarify — not before.

---

## Step 0 — Detect branch and load seed context

Detect the current branch name:

```bash
git branch --show-current
```

Hold the result as `<BRANCH>`. If this returns empty (detached HEAD or not a git repo), use `default` as the fallback. The context file will be named `CONTEXT-<BRANCH>.md`.

If `$ARGUMENTS` contains a file path, read that file as the seed. Otherwise treat `$ARGUMENTS` as the raw feature description.

If no arguments were provided, ask the user:

> "Paste the issue body, acceptance criteria, or a one-paragraph description of what we're building."

Hold the result as `<SEED>`.

---

## Step 1 — Load or initialize CONTEXT-<BRANCH>.md

Check for an existing `CONTEXT-<BRANCH>.md` in the working directory root.

- If it exists, read it and hold its current glossary entries.
- If it does not exist, it will be created lazily when the first term is resolved (Step 4).

---

## Step 2 — Scan for the first unresolved ambiguity

Analyze `<SEED>` (and any loaded `CONTEXT-<BRANCH>.md`) for the single highest-priority ambiguity. Look for:

- **Vague nouns** — terms that could mean different things to different people ("user", "account", "record", "document", "admin")
- **Implicit scope** — behavior that is assumed but never stated ("updates in real-time", "the usual flow", "as expected")
- **Conflicting signals** — two AC items that could contradict each other
- **Unmeasured criteria** — AC that cannot be verified ("should be fast", "should be intuitive")
- **One-way decisions hiding in plain sight** — a phrasing that commits the team to a particular architecture, data model, or UX pattern without saying so

Pick exactly one. If nothing is ambiguous, proceed to Step 6.

---

## Step 3 — Ask one question

Ask the user a single, tightly scoped question about the ambiguity identified in Step 2. Use **AskUserQuestion** if the answer is a constrained choice; use plain text output for open-ended clarification.

The question must:
- Reference the specific phrase or criterion that is ambiguous
- Be answerable in one sentence
- Not bundle multiple sub-questions

Wait for the answer before proceeding.

---

## Step 4 — Record the resolution

Classify the answer:

**Glossary term** — the answer settles what a word or phrase means in this project:
- Append or update an entry in `CONTEXT-<BRANCH>.md` under a `## Glossary` section:
  ```
  **<Term>**: <One-sentence definition grounded in the user's answer.>
  ```
- Create `CONTEXT-<BRANCH>.md` now if it does not yet exist.

**Hard decision** — the answer commits the team to a direction that would be costly to reverse (data model choice, removal of a capability, auth strategy, external dependency):
- Create an ADR file at `docs/adr/ADR-<NNN>-<kebab-title>.md` (increment `<NNN>` from the highest existing ADR number, starting at 001):
  ```markdown
  # ADR-<NNN>: <Decision title>

  Date: <today's date>
  Status: Accepted

  ## Context
  <Why this decision point arose — reference the specific AC or requirement.>

  ## Decision
  <What was decided, in the user's own words.>

  ## Consequences
  <What this rules out or makes harder going forward.>
  ```
- Also add a short reference to the ADR in `CONTEXT-<BRANCH>.md` under a `## Decisions` section:
  ```
  **<Topic>**: See [ADR-<NNN>](docs/adr/ADR-<NNN>-<kebab-title>.md)
  ```

**Both** — if the answer both defines a term and makes a hard commitment, do both.

---

## Step 5 — Loop

Return to Step 2 and scan the seed again, now treating all resolved terms and decisions as settled. Continue until Step 2 finds nothing left to clarify.

Do not revisit already-resolved items. Do not ask about things that are genuinely out of scope for the current feature.

**Question ceiling:** After 8 questions with no new resolvable ambiguity remaining, stop asking and proceed to Step 6 regardless. The ceiling prevents the interview from becoming exhaustive when the seed is already well-specified.

---

## Step 6 — Finish

Ask the user: "Anything else to clarify before we write the spec?" Wait for a response before finalizing. If the user adds new information, resolve it as in Steps 3–4 before continuing.

Then tell the user:

- How many terms were added to `CONTEXT-<BRANCH>.md`
- How many ADRs were created (if any), with their file paths
- That `CONTEXT-<BRANCH>.md` is ready to pass as context to `/opsx:propose`

Output the absolute path to `CONTEXT-<BRANCH>.md` so the calling skill can reference it.
