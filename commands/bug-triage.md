---
name: bug-triage
description: Investigate a bug — fetch the issue, validate it, find the root cause, assess impact, and produce an implementation plan. Works with GitHub issues and Azure DevOps work items.
argument-hint: "<issue-number-or-url>"
allowed-tools: Bash(gh:*), Bash(az:*), Bash(git:*), Read, Grep, Glob
---

# /bug-triage

Investigate a bug report end to end: validate it, find the root cause, assess impact, and produce a ready-to-implement fix plan.

---

## Step 0 — Detect the provider

```bash
git remote get-url origin
```

- URL contains `dev.azure.com`, `ssh.dev.azure.com`, or `visualstudio.com` → **provider = ADO**. Parse `<ORG>` and `<PROJECT>` from the remote URL.
- Otherwise → **provider = GitHub**.

---

## Step 1 — Fetch the issue

If no issue number or URL was given in `$ARGUMENTS`, ask the user for it.

**GitHub:**
```bash
gh issue view <NUMBER> --json number,title,body,url,labels
```

Retrieve: title, description, reproduction steps, expected vs. actual behavior, labels, linked PRs.

**ADO:**
```bash
az boards work-item show --id <ID> --org <ORG> \
  --fields System.Id,System.Title,System.Description,System.ReproSteps,System.AcceptanceCriteria,System.Tags \
  -o json
```

Retrieve: `System.Title`, `System.Description`, `System.ReproSteps` (strip HTML tags to plain text), `System.Tags`.

---

## Step 2 — Validate the issue

Before investigating the codebase, answer these questions:

| Check | Question |
|---|---|
| Reproducible | Can this be reproduced from the steps given? |
| Environment-specific | Is this dev/staging/prod only? |
| Data-dependent | Does it require specific data or user state? |
| Recent regression | Was this working before? Check recent commits. |
| Duplicate | Is there an existing open or closed issue for this? |
| Expected behavior | Is this actually a bug, or misunderstood behavior? |

If it's not a valid bug, say so clearly and stop.

---

## Step 3 — Root cause analysis

Investigate the codebase:

**1. Identify affected files** from the bug description. Search for relevant components, services, endpoints, or queries.

**2. Trace the data flow** through the affected path. Follow the chain from the entry point (UI action, API call, event) through to where the failure occurs.

**3. Check for common root causes:**
- Missing or incorrect validation
- Off-by-one or boundary condition
- Null/undefined/empty handling
- Incorrect query logic or filter
- State management issue or race condition
- Permission or authorization gap
- Incorrect error handling that swallows the real failure

**4. Check recent changes** to affected files:
```bash
git log --oneline --since="4 weeks ago" -- <affected-path>
git log --oneline -20 -- <affected-path>
```

---

## Step 4 — Output the analysis report

```markdown
# Bug Analysis: #<issue-number> — <title>

## Issue
**Ticket:** #<issue-number>
**Labels/Tags:** <labels>

<Brief one-paragraph description of the bug>

## Validation

| Check | Result | Notes |
|---|---|---|
| Reproducible | Yes/No | |
| Environment-specific | Yes/No | |
| Regression | Yes/No | |
| Duplicate | Yes/No | |
| Valid bug | Yes/No | |

## Root Cause

### Affected components
- <file or module path> — <role in the failure>

### Root cause
<Specific explanation of why the bug occurs, with code references>

### Code reference
- `<file>:<line>` — <what's wrong here>

## Impact

| Aspect | Severity | Notes |
|---|---|---|
| User impact | High/Medium/Low | |
| Data integrity | High/Medium/Low | |
| Security | High/Medium/Low | |
| Regression risk | High/Medium/Low | |
```

---

## Step 5 — Implementation plan

Append to the report:

```markdown
## Implementation Plan

**Approach:** <one sentence describing the fix strategy>

### Files to change

| File | Change | Description |
|---|---|---|
| `<path>` | Modify/Add/Delete | <what and why> |

### Steps

1. <Step description>
   - <sub-task>

2. <Step description>
   - <sub-task>

### Testing

| Type | What to test | File |
|---|---|---|
| Unit | <scenario> | `<test-file>` |
| Integration | <scenario> | `<test-file>` |
| Manual | <steps to verify fix> | — |

### Regression risk
- <Areas that could be affected by the fix>

### Complexity
**Effort:** Low / Medium / High
**Estimated time:** <hours>
```

---

## When to stop

If validation shows this is not a reproducible bug, expected behavior, or a duplicate — output the validation table with the conclusion and stop. Do not produce an implementation plan for invalid bugs.
