---
description: Claim a GitHub or Azure DevOps work item, create a branch, record it on the ticket, then run grill-with-docs and scaffold an OpenSpec proposal from the AC
argument-hint: "[issue-url-or-number] [--repo owner/name] [--base branch] [--assignee login]"
allowed-tools: Bash(git:*), Bash(gh:*), Bash(az:*)
model: opus
effort: high
---

# /start-ticket

Turn a GitHub issue or Azure DevOps work item into a branch + OpenSpec proposal in one step.

---

## Step 0 — Detect the provider

Inspect the git remote URL to determine the issue tracker:

```bash
git remote get-url origin
```

- If the URL contains `dev.azure.com` or `ssh.dev.azure.com` or `visualstudio.com` → **provider = ADO**
- Otherwise → **provider = GitHub**

Hold `<PROVIDER>` for the rest of the run.

---

## Step 1 — Resolve project context

Parse `$ARGUMENTS` for optional flags; whatever is left over is the **issue URL or number**.

- `--base <branch>` — base branch to branch from. If omitted, detect from the default branch (see provider steps below).
- `--assignee <login>` — issue assignee login or ADO display name. If omitted, detect the current user (see provider steps below).

**GitHub only:**
- `--repo <owner/name>` — target repo. If omitted, auto-detect: `gh repo view --json nameWithOwner -q .nameWithOwner`.
- Default branch: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`
- Current user: `gh api user -q .login`

**ADO only:**
- `--org <org-url>` — ADO organization URL (e.g. `https://dev.azure.com/myorg`). If omitted, parse from the git remote URL.
- `--project <project>` — ADO project name. If omitted, parse from the git remote URL.
- Default branch: `az repos show --detect true --query defaultBranch -o tsv` (strip `refs/heads/` prefix)
- Current user display name: `az ad signed-in-user show --query displayName -o tsv`

Hold `<REPO>` (GitHub) or `<ORG>` + `<PROJECT>` (ADO), `<BASE_BRANCH>`, and `<ASSIGNEE>`.

---

## Step 2 — Identify the ticket

If a URL or number was provided in `$ARGUMENTS`, parse it and proceed to Step 3.

If **none** was provided, ask the user for the issue number or URL using **AskUserQuestion**.

---

## Step 3 — Fetch the ticket details

**GitHub:**
```bash
gh issue view <NUMBER> --repo <REPO> --json number,title,body,url,labels
```

Extract and hold: `number`, `title`, `body`, `url`.

**ADO:**
```bash
az boards work-item show --id <ID> --org <ORG> \
  --fields System.Id,System.Title,System.Description,System.AcceptanceCriteria,System.WorkItemType \
  -o json
```

Extract and hold:
- `id` → equivalent of `number`
- `System.Title` → `title`
- `System.Description` + `System.AcceptanceCriteria` (both fields, concatenated) → `body`
- Construct `url` as `<ORG>/<PROJECT>/_workitems/edit/<ID>`

---

## Step 4 — Generate a branch name

Derive a branch name from the ticket title:

```
<number>-<slugified-title>
```

Rules:
- Lowercase only
- Replace spaces and special characters with hyphens
- Strip leading/trailing hyphens
- Collapse consecutive hyphens to one
- Trim to 60 characters max

Example: ticket 42 "Add Forgot Password Screen" → `42-add-forgot-password-screen`

---

## Step 5 — Create the branch

Branch from `<BASE_BRANCH>` (same for both providers — git is provider-agnostic):

```bash
git fetch origin <BASE_BRANCH>
git checkout -b <BRANCH_NAME> origin/<BASE_BRANCH>
git push -u origin <BRANCH_NAME>
```

---

## Step 6 — Assign the ticket

**GitHub:**
```bash
gh issue edit <NUMBER> --repo <REPO> --add-assignee <ASSIGNEE>
```

**ADO:**
```bash
az boards work-item update --id <ID> --org <ORG> --assigned-to "<ASSIGNEE>"
```

---

## Step 7 — Record the branch on the ticket

**GitHub** — attempt to link via GitHub's development section first:
```bash
gh issue develop <NUMBER> --repo <REPO> --name <BRANCH_NAME> --base-branch <BASE_BRANCH>
```
If that fails, fall back to a comment:
```bash
gh issue comment <NUMBER> --repo <REPO> --body "Branch: \`<BRANCH_NAME>\`"
```

**ADO** — post a discussion comment on the work item:
```bash
az boards work-item comment add --id <ID> --org <ORG> \
  --text "Branch: \`<BRANCH_NAME>\`"
```

Confirm to the user which method was used.

---

## Step 8 — Extract the Acceptance Criteria

**GitHub:** Scan the issue body for an AC section. Look for headings matching any of:
- `## Acceptance Criteria`, `## AC`, `## Done When`, `## Definition of Done`, `## Criteria`

Extract everything from that heading to the next `##` heading (or end of body). If no explicit section exists, collect all checkbox lines (`- [ ] ...` or `- [x] ...`).

**ADO:** Prefer the `System.AcceptanceCriteria` field if it is non-empty. Fall back to the `System.Description` field. ADO stores these as HTML — strip tags to plain text before proceeding.

For both providers: if the body has no AC and no checkboxes, use the full title + body as the description for the proposal.

---

## Step 9 — Align terminology with grill-with-docs

Before writing the proposal, run `/grill-with-docs` with the AC content as seed input. This resolves fuzzy language and records hard decisions as ADRs before the spec is written.

Pass the extracted AC (from Step 8) as the argument to `/grill-with-docs`.

When the interview completes, hold the absolute path returned by `/grill-with-docs` as `<CONTEXT_PATH>` (it will be named `CONTEXT-<BRANCH_NAME>.md`).

---

## Step 10 — Open the OpenSpec proposal (if configured)

Check whether this repo has OpenSpec configured:

```bash
ls openspec/ 2>/dev/null
```

**If OpenSpec is present:**

Invoke the `/opsx:propose` skill. Pass the ticket title as the change name (kebab-case) and provide the full AC content as the description for the proposal. The proposal must:

- Use the terminology exactly as defined in `<CONTEXT_PATH>` — do not paraphrase or re-derive terms that were settled during the grill session
- Reference each AC criterion as a concrete requirement
- Reference any ADRs created during the grill session when the proposal touches those decisions

If the AC mentions data storage, PHI, role gating, Supabase schema, or email flows, flag those to the user as items that will need Security + HIPAA review during the proposal phase (per CLAUDE.md).

**If OpenSpec is not present:**

Tell the user: "OpenSpec is not configured in this repo — skipping the proposal step. The grill session output is at `<CONTEXT_PATH>` and ADRs (if any) are under `docs/adr/`. Run `/create-plan` to generate an implementation plan directly from the AC, or set up OpenSpec and run `/opsx:propose` manually."
