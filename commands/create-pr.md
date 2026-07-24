---
description: Commit remaining changes, run the pre-PR review, push, create a PR against the base branch, and link it back to the related issue. Works with GitHub and Azure DevOps.
argument-hint: "[pr-title] [--base branch] [--assignee login]"
allowed-tools: Bash(git:*), Bash(gh:*), Bash(az:*)
---

# /create-pr

Clean up uncommitted work, run the pre-PR review, push, open a PR, and close the loop on the issue.

---

## Step 0 — Detect the provider and resolve project context

**Detect the provider:**
```bash
git remote get-url origin
```
- Contains `dev.azure.com`, `ssh.dev.azure.com`, or `visualstudio.com` → **provider = ADO**. Parse `<ORG>` and `<PROJECT>` from the remote URL.
- Otherwise → **provider = GitHub**.

Parse `$ARGUMENTS` for optional flags; whatever is left over is the **PR title**.

- `--base <branch>` — base branch to target. If omitted, detect the repo's default branch:
  - **GitHub:** `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`
  - **ADO:** `az repos show --detect true --query defaultBranch -o tsv` (strip `refs/heads/`)
- `--assignee <login>` — PR assignee. If omitted, detect the current user:
  - **GitHub:** `gh api user -q .login`
  - **ADO:** `az ad signed-in-user show --query userPrincipalName -o tsv`

Hold `<BASE_BRANCH>` and `<ASSIGNEE>`.

---

## Step 1 — Confirm we are on a feature branch

```bash
git branch --show-current
```

If the current branch equals `<BASE_BRANCH>`, or is `master` or `main`, stop and tell the user to run this from a feature branch.

Hold the branch name — you'll need it throughout.

---

## Step 2 — Detect the linked ticket

Feature branches created by `/start-ticket` follow the pattern `<ticket-number>-<slug>`.

Extract the leading digits from the branch name. Example: `42-add-forgot-password-screen` → ticket **42**.

If the branch name does not start with a number, ask the user for the ticket number using **AskUserQuestion** before continuing. If they have no linked ticket, skip Steps 3 and 9.

---

## Step 3 — Fetch the ticket for context

**GitHub:**
```bash
gh issue view <NUMBER> --json number,title,body,url
```

**ADO:**
```bash
az boards work-item show --id <ID> --org <ORG> \
  --fields System.Id,System.Title,System.Description,System.AcceptanceCriteria \
  -o json
```
Strip HTML tags from description/AC fields before using.

Hold the ticket title and body — use them when generating the PR description.

---

## Step 4 — Commit any remaining uncommitted changes

Check for leftover changes:

```bash
git status --short
```

If there are staged or unstaged tracked files:

1. Stage everything tracked:
   ```bash
   git add -u
   ```
2. Review what is staged (`git diff --cached --stat`) and write a concise commit message describing the changes — do not use a generic message like "misc changes".
3. Commit:
   ```bash
   git commit -m "<your message>"
   ```

If there are **untracked** files, do not `git add .` blindly. List them and ask the user whether to include them.

If the working tree is already clean, skip this step.

---

## Step 5 — Gather context for the PR description

```bash
git log origin/<BASE_BRANCH>..HEAD --oneline
```

Also check for any OpenSpec artifacts for this change:

```bash
find openspec/changes -maxdepth 2 \( -name "proposal.md" -o -name "tasks.md" \) 2>/dev/null | head -10
```

Read any `proposal.md` and `tasks.md` found — they contain the feature description and implementation checklist that should inform the PR body.

---

## Step 6 — Verify and review before opening the PR

First, **run the test suite** so you don't open a red PR. Auto-detect the project's test command (e.g. `package.json` `scripts.test`, `pytest`/`pyproject.toml`, a `Makefile` `test` target) and run it. If tests fail, stop and fix them (or surface the failure to the user) before continuing. For a change with meaningful runtime behavior, also consider driving `/verify` to confirm it actually works, not just that tests pass.

Then run the self-review pass:

- Invoke `/review-report` (runs `/code-review` + `/smell` + `/sync-docs` and consolidates the findings).
- If the change touches a regulated or sensitive area (PHI, auth, payments, or anything flagged during the OpenSpec proposal), also invoke `/security-review`.

Address the findings. If you're intentionally deferring any, note them for the user rather than silently skipping. Commit any fixes (repeat Step 4).

---

## Step 7 — Push the branch

Push once, after the review, so the PR includes the review's doc-sync and any fixes:

```bash
git push -u origin <BRANCH_NAME>
```

If the push is rejected (non-fast-forward), stop and tell the user to resolve the conflict manually — do not force push.

---

## Step 8 — Create the PR

Use the ticket title (if available) or the PR title argument as the PR title. Keep it under 70 characters.

**GitHub** — build the PR body:

```
Closes #<TICKET_NUMBER>

## Summary
<2-4 bullet points drawn from the commit log and proposal — what was built and why>

## Changes
<bullet list of the meaningful files/areas touched, one line each>

## Test plan
<checklist drawn from the AC in the ticket body — one checkbox per criterion>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Create as a **draft**:

```bash
gh pr create \
  --base <BASE_BRANCH> \
  --draft \
  --title "<TITLE>" \
  --assignee <ASSIGNEE> \
  --body "$(cat <<'EOF'
<BODY>
EOF
)"
```

**ADO** — build the PR description (ADO uses `AB#<ID>` to link work items):

```
AB#<TICKET_ID>

## Summary
<2-4 bullet points drawn from the commit log and proposal — what was built and why>

## Changes
<bullet list of the meaningful files/areas touched, one line each>

## Test plan
<checklist drawn from the AC — one checkbox per criterion>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Create as a **draft**:

```bash
az repos pr create \
  --org <ORG> \
  --project "<PROJECT>" \
  --repository <REPO_NAME> \
  --source-branch <BRANCH_NAME> \
  --target-branch <BASE_BRANCH> \
  --title "<TITLE>" \
  --description "<DESCRIPTION>" \
  --draft true \
  --output json
```

Hold the PR number/ID and URL returned by the command.

---

## Step 9 — Link the PR back to the ticket

**GitHub:**
```bash
gh issue comment <NUMBER> --body "PR opened: <PR_URL>"
```

**ADO:**
```bash
az boards work-item comment add --id <ID> --org <ORG> \
  --text "PR opened: <PR_URL>"
```

---

## Step 10 — Report to the user

- Branch pushed
- PR URL
- Ticket comment posted (or skipped if no ticket)
- Any CLAUDE.md / AGENTS.md staleness surfaced by the review's `/sync-docs` pass that needs human attention
