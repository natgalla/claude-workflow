---
description: Fetch the base branch and rebase (or merge) the current feature branch onto it, surfacing conflicts to resolve
argument-hint: "[--base branch] [--merge]"
allowed-tools: Bash(git:*), Bash(gh:*), Bash(az:*)
model: sonnet
---

# /sync-branch

Bring the current feature branch up to date with its base.

---

## Step 0 — Resolve project context

Parse `$ARGUMENTS` for flags.

- `--base <branch>` — base branch. If omitted, detect from the repo's default branch (see below).
- `--merge` — use a merge instead of the default **rebase**.

**Detect the provider** from the git remote, then resolve the default branch if `--base` was not provided:

```bash
git remote get-url origin
```

**GitHub** (remote does not contain `dev.azure.com` / `visualstudio.com`):
```bash
gh repo view --json defaultBranchRef -q .defaultBranchRef.name
```

**ADO** (remote contains `dev.azure.com`, `ssh.dev.azure.com`, or `visualstudio.com`):
```bash
az repos show --detect true --query defaultBranch -o tsv
```
Strip the `refs/heads/` prefix from the result.

Hold `<BASE_BRANCH>` and the chosen strategy.

---

## Step 1 — Confirm we are on a feature branch

```bash
git branch --show-current
```

If the current branch equals `<BASE_BRANCH>`, or is `master`/`main`, stop — there's nothing to sync.

---

## Step 2 — Require a clean working tree

```bash
git status --short
```

If there are uncommitted changes, stop and ask the user to commit or stash first. Do not sync over a dirty tree.

---

## Step 3 — Fetch the base

```bash
git fetch origin <BASE_BRANCH>
```

If the branch is already up to date with `origin/<BASE_BRANCH>`, report that and stop.

---

## Step 4 — Rebase (or merge)

**Rebase (default):**

```bash
git rebase origin/<BASE_BRANCH>
```

**Merge (`--merge`):**

```bash
git merge origin/<BASE_BRANCH>
```

---

## Step 5 — Resolve conflicts, if any

If there are conflicts, list the conflicted files. Resolve each by **understanding both sides** — the incoming base change and the feature change — and keeping the intent of both. Never blindly take one side or discard work. If a conflict is genuinely ambiguous or risks losing behavior, stop and hand it back to the user rather than guessing.

After resolving:

- Rebase: `git add <files>` then `git rebase --continue` (repeat per commit).
- Merge: `git add <files>` then `git commit`.

---

## Step 6 — Push

- **Rebase** rewrites history, so the push needs a lease-guarded force. This is safe on your own feature branch (not a shared one):
  ```bash
  git push --force-with-lease
  ```
- **Merge** is a normal push:
  ```bash
  git push
  ```

---

## Step 7 — Report to the user

- Base branch and strategy used
- Whether conflicts were hit, and which files were resolved
- Pushed (and whether a force-with-lease was used)
- Anything left for the user to verify (e.g., a conflict resolution they should sanity-check)
