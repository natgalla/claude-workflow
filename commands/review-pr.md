---
name: review-pr
description: Review a pull request — explores and explains it if you are not a requested reviewer; runs full code review + manual QA checklist if you are.
argument-hint: "<pr-number>"
allowed-tools: Bash(gh:*), Bash(az:*), Bash(git:*), Read, Grep, Glob, Agent, Skill
---

# /review-pr

Review a pull request based on whether you have been requested as a reviewer.

---

## Step 0 — Resolve context

Parse `$ARGUMENTS` for the PR number. If none provided, ask the user for it.

Detect the provider:

```bash
git remote get-url origin
```

- Contains `dev.azure.com`, `ssh.dev.azure.com`, or `visualstudio.com` → **provider = ADO**
- Otherwise → **provider = GitHub**

Resolve the current GitHub user login:

```bash
gh api user -q .login
```

Hold `<CURRENT_USER>` for reviewer checks.

---

## Step 1 — Fetch PR metadata

**GitHub:**

```bash
gh pr view <PR_NUMBER> --json number,title,body,headRefName,baseRefName,author,reviewRequests,state,url,labels,additions,deletions,changedFiles,commits
```

Hold:
- `<TITLE>`, `<BODY>`, `<HEAD_BRANCH>`, `<BASE_BRANCH>`, `<PR_URL>`
- `<REVIEWER_LOGINS>` — extract `.reviewRequests[].login` from the JSON

Check: is `<CURRENT_USER>` in `<REVIEWER_LOGINS>`?

- **Yes** → proceed to **Full Review path** (Step 3)
- **No** → proceed to **Explore path** (Step 2)

---

## Step 2 — Explore path (not a requested reviewer)

Fetch the diff summary and a sample of the actual changes:

```bash
gh pr diff <PR_NUMBER> --name-only
gh pr diff <PR_NUMBER>
```

Read the files most central to the change (up to 5) using the Read tool to understand context. Do not check out the branch.

Produce a structured explanation:

```
## PR #<NUMBER>: <TITLE>
<PR_URL>

**Author:** <author>  **Base:** `<BASE_BRANCH>`  **Size:** +<additions> / -<deletions> across <changedFiles> files

### What it does
<2-4 sentences describing the purpose and approach — not a file list>

### Key changes
- `<file or area>` — <one-line description of what changed and why>
- ...

### Approach & decisions
<Any notable design choices, tradeoffs, or patterns the PR introduces>

### Things to watch
<Anything that looks risky, surprising, or worth extra scrutiny — or "Nothing notable" if clean>
```

Then ask:

> Want me to run a full review (checkout + automated scan + QA checklist)?

**Stop here and wait for the user's response.**

If the user says yes, continue to Step 3 using the already-fetched PR metadata.

---

## Step 3 — Full review path (requested reviewer, or user escalated)

### 3a — Check out the branch

```bash
git fetch origin <HEAD_BRANCH>
git checkout <HEAD_BRANCH>
```

If the checkout fails (uncommitted changes on the current branch), stop and tell the user — do not stash automatically.

**Read-only constraint:** This is a review-only checkout. Do not make any commits, pushes, or file modifications to this branch at any point during the review.

### 3b — Run the automated code review

Delegate to the **code-review** agent:

> Run a full review-report on the current branch (`<HEAD_BRANCH>`) against base `<BASE_BRANCH>`. This is a PR review — include code-review, smell, and a11y findings.

Wait for the agent to complete and hold its output.

### 3c — Build the manual QA checklist

Analyze the PR description and diff to produce a checklist of specific, testable scenarios. The checklist must be derived from what this PR actually does — not a generic template.

Structure:

```
## Manual QA Checklist — PR #<NUMBER>

### Setup
- [ ] <Any seed data, feature flags, env vars, or config needed to test this change>

### Happy path
- [ ] <Specific scenario 1 — what to do and what to expect>
- [ ] <Specific scenario 2>
- ...

### Edge cases & error states
- [ ] <Boundary condition or error scenario>
- ...

### Regression checks
- [ ] <Existing behavior that could be affected — verify it still works>
- ...

### Review criteria
- [ ] <Any AC from the PR description that requires human judgment to verify>
- ...
```

Heuristics to apply when building the checklist:
- **Auth/permissions changes** — include a check for each role that could be affected, plus an unauthorized-access attempt
- **Data mutations** — include a check for what happens to existing records, and a rollback/undo scenario if applicable
- **UI changes** — include viewport checks (mobile + desktop), keyboard navigation, and any visible state transitions
- **Migrations** — include a check that existing data survives the migration and the schema is correct
- **API changes** — include at least one consumer (UI or test) that exercises the new contract
- **Background jobs / async** — include a check that the job completes, and what happens if it fails

### 3d — Present findings

Output in this order:

1. The automated review-report output from Step 3b (verbatim, not summarized)
2. The manual QA checklist from Step 3c

Then ask:

> Which findings would you like to post as PR comments? Reply with numbers, `all`, or give direction. Findings with file and line context will be posted as inline review comments; others as general review comments.

---

## Step 3e — Post PR comments

For each finding the user selects, post it as a PR comment.

**Inline comment** (when a specific file and line number are known):

```bash
gh api repos/{owner}/{repo}/pulls/<PR_NUMBER>/comments \
  --method POST \
  --field body="<finding text>" \
  --field commit_id="<HEAD_COMMIT_SHA>" \
  --field path="<file_path>" \
  --field line=<line_number> \
  --field side="RIGHT"
```

Resolve `{owner}/{repo}` from the remote URL. Resolve `<HEAD_COMMIT_SHA>` with:

```bash
git rev-parse origin/<HEAD_BRANCH>
```

**General review comment** (when no specific line is available):

```bash
gh pr review <PR_NUMBER> --comment --body "<finding text>"
```

Post each finding separately so threads remain independent. After posting, report which comments were created and link to `<PR_URL>` for the user to verify.
