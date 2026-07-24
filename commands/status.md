---
description: Show the current ticket's full state — branch, linked work item, PR, OpenSpec proposal, and grill session — in one view
argument-hint: ""
allowed-tools: Bash(git:*), Bash(gh:*), Bash(az:*), Bash(find:*), Bash(ls:*), Read
model: sonnet
---

# /status

Show where the current ticket stands across every layer of the workflow: branch → ticket → PR → grill → spec → plan.

---

## Step 1 — Detect context

```bash
git branch --show-current
git remote get-url origin 2>/dev/null
```

Hold `<BRANCH>` and detect the provider:
- Remote contains `dev.azure.com`, `ssh.dev.azure.com`, or `visualstudio.com` → **ADO**. Parse `<ORG>` and `<PROJECT>`.
- Otherwise → **GitHub**.

Extract the ticket ID from the branch name (leading digits before the first `-`). Example: `42-add-forgot-password` → `<TICKET_ID>` = `42`. If the branch doesn't start with a number, `<TICKET_ID>` = none.

---

## Step 2 — Fetch ticket status

Skip if no `<TICKET_ID>`.

**GitHub:**
```bash
gh issue view <TICKET_ID> --json number,title,state,assignees,labels,url
```

**ADO:**
```bash
az boards work-item show --id <TICKET_ID> --org <ORG> \
  --fields System.Title,System.State,System.AssignedTo,System.Tags \
  -o json
```

Hold: title, state, assignee.

---

## Step 3 — Fetch PR status

**GitHub:**
```bash
gh pr view --json number,url,state,isDraft,reviewDecision,reviews 2>/dev/null
```

**ADO:**
```bash
az repos pr list --detect true --source-branch <BRANCH> --status all --top 1 -o json 2>/dev/null
```

Hold: PR number/ID, URL, state (open/draft/merged/closed), review decision or vote summary.

---

## Step 4 — Check local workflow artifacts

Run these in parallel:

```bash
# Grill output
ls CONTEXT-<BRANCH>.md 2>/dev/null && echo "found" || echo "not found"

# Implementation plan
ls <BRANCH>.plan.md 2>/dev/null && echo "found" || echo "not found"

# OpenSpec proposal
find openspec/changes -maxdepth 2 -name "proposal.md" 2>/dev/null | head -5

# ADRs created during grill
find docs/adr -name "ADR-*.md" 2>/dev/null | sort | tail -5
```

---

## Step 5 — Present the dashboard

Output exactly this structure:

```
## Status: <BRANCH>

### Ticket
<TICKET_ID not found — branch name has no leading number>
  OR
#<TICKET_ID> — <title>
State:    <Open / Closed / Active / Resolved>
Assignee: <login or display name>
URL:      <url>

### Pull Request
No PR yet — run /create-pr when ready
  OR
#<PR_NUMBER> — <state> <(draft)>
Review:   <Approved / Changes requested / Awaiting review / N/A>
URL:      <url>

### Workflow artifacts
Grill session:    CONTEXT-<BRANCH>.md  ✅ present  |  ⚠️ not found — run /grill-with-docs
Implementation plan: <BRANCH>.plan.md  ✅ present  |  ⚠️ not found — run /create-plan
OpenSpec proposal:   <path>  ✅ present  |  ⚠️ not found  |  ➖ OpenSpec not configured
Recent ADRs:      <list filenames, or "none">

### Next step
<One sentence recommending the logical next action based on the state above.>
```

**Next step** logic:
- No grill session → "Run `/grill-with-docs` to align terminology before writing the spec."
- Grill done, no proposal, OpenSpec present → "Run `/opsx:propose` to scaffold the spec."
- Grill done, no proposal, no OpenSpec → "Run `/create-plan` to generate an implementation plan."
- Proposal present, no plan → "Run `/create-plan` to generate an implementation plan."
- Plan present, no PR → "Implement, then run `/create-pr` when ready."
- PR open as draft → "Run `/ready-for-review` when implementation is complete."
- PR awaiting review → "Waiting on reviewer. Run `/address-review` once feedback arrives."
- PR approved → "Run `/merge-pr` to merge."
- PR merged → "Run `/debrief` if this closes the engagement, or start the next ticket."
