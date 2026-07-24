---
description: Verify the PR is approved and merge it into the base branch. Works with GitHub and Azure DevOps.
argument-hint: "[--reviewer login]"
allowed-tools: Bash(git:*), Bash(gh:*), Bash(az:*)
model: sonnet
---

# /merge-pr

Gate on approval and merge into the PR's base branch.

---

## Step 0 — Detect the provider and resolve project context

```bash
git remote get-url origin
```

- Contains `dev.azure.com`, `ssh.dev.azure.com`, or `visualstudio.com` → **provider = ADO**. Parse `<ORG>` and `<PROJECT>` from the remote URL.
- Otherwise → **provider = GitHub**.

Parse `$ARGUMENTS` for optional flags.

- `--reviewer <login>` — the required approver to gate on. Optional; if omitted, gate on **any** approving review.

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
gh pr view --json number,url,state,baseRefName
```

**ADO:**
```bash
az repos pr list --detect true --source-branch <BRANCH_NAME> --status active -o json
```
Take the first result. If none, stop: "No active PR found. Run `/create-pr` first."

For either provider: if the PR is already merged or closed, stop and say so.

Hold the PR number/ID, URL, and base branch name.

---

## Step 3 — Verify the PR is approved

**GitHub:**
```bash
gh pr view <PR_NUMBER> --json reviews
```

The `reviews` array contains objects with `author.login` and `state`.

- **If `<REVIEWER>` was provided**, require a review where `author.login` matches `<REVIEWER>` (case-insensitive) and `state` is `APPROVED`. If none, stop: "PR has not been approved by `<REVIEWER>` yet."
- If `<REVIEWER>` has a `CHANGES_REQUESTED` review (and no subsequent `APPROVED`), stop: "`<REVIEWER>` has requested changes. Address the feedback before merging."
- **If no `<REVIEWER>`**, require at least one `APPROVED` and no outstanding `CHANGES_REQUESTED`.

**ADO:**
```bash
az repos pr reviewer list --id <PR_ID> --org <ORG> -o json
```

Each reviewer has a `vote` field:
- `10` = Approved
- `5` = Approved with suggestions (counts as approved)
- `0` = No vote
- `-5` = Waiting for author
- `-10` = Rejected (equivalent to Changes Requested)

- **If `<REVIEWER>` was provided**, require that reviewer's `vote` ≥ 5. If `vote` is `-10`, stop with a changes-requested message. If `vote` is 0 or -5, stop: "Not yet approved by `<REVIEWER>`."
- **If no `<REVIEWER>`**, require at least one reviewer with `vote` ≥ 5 and no reviewer with `vote` = -10.

---

## Step 4 — Merge the PR

**GitHub** (merge commit, deletes source branch):
```bash
gh pr merge <PR_NUMBER> --merge --delete-branch
```

**ADO** (complete, deletes source branch):
```bash
az repos pr update --id <PR_ID> --org <ORG> \
  --status completed \
  --delete-source-branch true \
  -o json
```

If the merge/complete fails due to conflicts, stop and tell the user to resolve them manually (run `/sync-branch` first).

---

## Step 5 — Archive the OpenSpec change (if applicable)

If the repo uses OpenSpec (an `openspec/` directory exists) and this change has an active proposal under `openspec/changes/<name>/`, archive it now that it's merged — using the repo's OpenSpec archive command (the `/opsx:archive` skill or `openspec archive <name>`, whichever the repo provides). Archiving moves the proposal into the archive and folds its spec deltas into the canonical specs.

If archiving produces file changes, they must be committed to the base branch (or via a short follow-up PR) per the repo's convention. If OpenSpec isn't in use or there's no active proposal for this change, skip this step.

---

## Step 6 — Report to the user

- PR #<NUMBER> merged into `<baseRefName>`
- Branch deleted
- OpenSpec change archived (or "n/a")
