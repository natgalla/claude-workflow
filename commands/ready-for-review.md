---
description: Mark the open PR ready for review and optionally request a reviewer. Works with GitHub and Azure DevOps.
argument-hint: "[--reviewer login]"
allowed-tools: Bash(git:*), Bash(gh:*), Bash(az:*)
model: sonnet
---

# /ready-for-review

Request a review on the open PR.

---

## Step 0 — Detect the provider and resolve project context

```bash
git remote get-url origin
```

- Contains `dev.azure.com`, `ssh.dev.azure.com`, or `visualstudio.com` → **provider = ADO**. Parse `<ORG>` and `<PROJECT>` from the remote URL.
- Otherwise → **provider = GitHub**.

Parse `$ARGUMENTS` for optional flags.

- `--reviewer <login>` — reviewer to request. Optional; if omitted, the PR is marked ready without adding a reviewer.

---

## Step 1 — Confirm we are on a feature branch

```bash
git branch --show-current
```

If the branch is `master` or `main`, stop and tell the user to run this from a feature branch.

Hold the branch name.

---

## Step 2 — Find the open PR for this branch

**GitHub:**
```bash
gh pr view --json number,url,state
```

If no PR exists, tell the user to run `/create-pr` first and stop.

If the PR state is already `MERGED` or `CLOSED`, warn the user and stop.

**ADO:**
```bash
az repos pr list --detect true --source-branch <BRANCH_NAME> --status active -o json
```

Take the first result. If none, tell the user to run `/create-pr` first and stop.

Hold the PR number/ID and URL.

---

## Step 3 — Mark the PR ready for review

**GitHub** — promote out of draft (this advances the linked issue in GitHub Projects):
```bash
gh pr ready <PR_NUMBER>
```

**ADO** — remove draft status:
```bash
az repos pr update --id <PR_ID> --org <ORG> --draft false -o json
```

---

## Step 4 — Request a reviewer

If a `<REVIEWER>` was resolved:

**GitHub:**
```bash
gh pr edit <PR_NUMBER> --add-reviewer <REVIEWER>
```

**ADO:**
```bash
az repos pr reviewer add --id <PR_ID> --org <ORG> --reviewers "<REVIEWER>"
```

If no reviewer was provided, skip this step.

---

## Step 5 — Report to the user

- PR URL
- Draft status removed
- Reviewer requested: `<REVIEWER>` (or "none")
