---
description: Fetch the PR's review feedback, work through each thread, reply/resolve, and re-request review
argument-hint: "[--repo owner/name]"
allowed-tools: Bash(git:*), Bash(gh:*), Read, Edit, Write, Grep, Glob
---

# /address-review

Turn a reviewer's feedback into changes, replies, and a re-request — without blindly complying.

---

## Step 0 — Resolve project context

Parse `$ARGUMENTS` for flags.

- `--repo <owner/name>` — target repo. If omitted, auto-detect from the git remote: `gh repo view --json nameWithOwner -q .nameWithOwner`.

Hold `<REPO>` (and split it into `<OWNER>`/`<REPO_NAME>` for the GraphQL calls) for the rest of the run.

---

## Step 1 — Confirm we are on a feature branch

```bash
git branch --show-current
```

If the branch is `master` or `main`, stop and tell the user to run this from a feature branch. Hold the branch name.

---

## Step 2 — Find the open PR for this branch

```bash
gh pr view --repo <REPO> --json number,url,state
```

If no PR exists, stop: "No open PR found. Run `/create-pr` first." If `state` is `MERGED`/`CLOSED`, warn and stop. Hold the PR number and URL.

---

## Step 3 — Gather the feedback

Pull the review summaries and the **unresolved** inline threads:

```bash
gh api graphql -f query='
query($owner:String!,$repo:String!,$number:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$number){
      reviews(first:50){ nodes{ author{login} state body submittedAt } }
      reviewThreads(first:100){
        nodes{
          id
          isResolved
          isOutdated
          path
          line
          comments(first:20){ nodes{ author{login} body } }
        }
      }
    }
  }
}' -f owner=<OWNER> -f repo=<REPO_NAME> -F number=<PR_NUMBER>
```

Ignore resolved threads. For each unresolved thread hold: `id`, `path`, `line`, the comment text, and author. Also read the latest `CHANGES_REQUESTED` review body for higher-level asks.

If there's no actionable feedback, say so and stop.

---

## Step 4 — Triage each thread

For every unresolved thread, decide one of:

- **Fix** — the feedback is correct; change the code.
- **Push back** — you have a principled reason to disagree (the suggestion is wrong, out of scope, or conflicts with the AC/conventions). Draft a short, respectful reply explaining why instead of changing the code.
- **Ask** — the intent is ambiguous, or the fix would expand scope. Raise it with the user (**AskUserQuestion**) before acting.

Do **not** blindly comply with every comment. Present the triage plan (thread → decision, one line each) before making changes.

---

## Step 5 — Make the changes

Work through the **Fix** threads. Read the file around each `path`/`line`, make the minimal change that satisfies the feedback, and stay within scope (per the Scope discipline rule — don't drive-by-refactor adjacent code).

When done, commit with a message that describes what was addressed (not "review fixes"):

```bash
git add -u
git commit -m "<what changed in response to review>"
git push
```

If the push is rejected (non-fast-forward), stop and tell the user — do not force push.

---

## Step 6 — Reply, resolve, and re-request

- **Reply** to each thread with what you did (or, for push-backs, your reasoning). Resolve the threads you fully addressed:
  ```bash
  gh api graphql -f query='mutation($id:ID!){ resolveReviewThread(input:{threadId:$id}){ thread{ isResolved } } }' -f id=<THREAD_ID>
  ```
- Post one concise summary comment mapping each thread to its outcome:
  ```bash
  gh pr comment <PR_NUMBER> --repo <REPO> --body "<summary>"
  ```
- **Re-request review** from whoever requested changes:
  ```bash
  gh pr edit <PR_NUMBER> --repo <REPO> --add-reviewer <REVIEWER_LOGIN>
  ```

---

## Step 7 — Report to the user

- Threads addressed / pushed back on / deferred to the user
- Commit pushed
- Review re-requested from `<REVIEWER_LOGIN>`
- Anything still open that needs a human decision
