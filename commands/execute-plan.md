---
name: execute-plan
description: Execute a markdown implementation plan file step by step with human approval at each step. Use when asked to "execute the plan", "work through plan file", or "implement from plan". Argument is the path to the plan file.
argument-hint: "<path-to-plan-file.md>"
---

# /execute-plan

Execute a structured implementation plan one step at a time. Wait for explicit user approval before proceeding between steps. Update the plan file after each approval.

---

## Step 1 — Read and understand the plan

Read the plan file at the path given in `$ARGUMENTS`. If no path was given, look for a `*.plan.md` file in the current directory and ask the user to confirm which one.

Read the **entire** plan before doing anything else. Identify:
- All phases and steps
- Open questions or decision points
- Any explicit checkpoints (build, tests, lint)
- Dependencies between steps

Present a brief summary — phases, step count, open questions — then ask:

> Ready to start? Any open questions need answering first?

**Wait for the user to confirm before proceeding.**

---

## Step 2 — Execute one step at a time

For each step in the plan:

### a. Announce
State clearly what you are about to do and which step it is (e.g., "Step 2.1 of 4 — Create the database migration").

### b. Stop at decision points
If you encounter an open question, ambiguity, or a choice between approaches — **stop and surface it to the user**. Present the options with tradeoffs. Do not assume an answer. Do not proceed until the user decides.

### c. Execute
Implement the step.

### d. Run checkpoints
If the plan defines a validation checkpoint (build passes, tests pass, lint clean), run it and report the result. Do not proceed past a failing checkpoint without explicit user approval.

### e. Report
After completing the step, present:
- Files created or modified (with paths)
- Any implementation decisions made and why
- Any deviations from the plan (and why)
- Checkpoint results

Then ask:

> Step N complete. Proceed to step N+1, or any changes first?

**Wait for the user's explicit go-ahead before moving to the next step.**

### f. Update the plan file
After the user approves, update the plan file to mark the step complete:
- Mark done steps with `[DONE]`
- Record implementation decisions or deviations inline
- Resolve open questions that were answered
- Mark the next step as `[IN PROGRESS]`

Use these status markers throughout:
- `[DONE]` — approved and complete
- `[IN PROGRESS]` — currently being worked on
- `[PENDING]` — not yet started
- `[BLOCKED]` — cannot proceed, needs resolution
- `[MODIFIED]` — implemented differently than planned (note why)

---

## Step 3 — Handle errors

If a step fails or produces unexpected results:
1. Stop immediately
2. Report the issue clearly
3. Suggest possible fixes
4. **Wait for the user to choose an approach** — do not brute-force past errors

---

## Step 4 — Final summary

After all steps are approved and complete, present:
- What was built (files created/modified)
- Any open items or follow-ups surfaced during execution
- Suggested next actions (tests to run, PR to create, etc.)
