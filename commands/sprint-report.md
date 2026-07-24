---
description: Summarize project board status at sprint end and draft an email for your PM and supervisor
argument-hint: "[project-number] [--org login] [--to emails] [--label subject-label]"
allowed-tools: Bash(gh:*), Bash(python3:*), Bash(open:*)
model: sonnet
---

# /sprint-report

Pull the current board state, collect context on anything that didn't move, and draft a sprint-end email.

---

## Step 0 — Resolve project context

Parse `$ARGUMENTS` for flags; a bare number is the **project number**.

- `--org <login>` — the org that owns the project board. If omitted, default to the current repo's owner: `gh repo view --json owner -q .owner.login`. If that fails (not in a repo), ask the user with **AskUserQuestion**.
- **project number** (positional, or `--project <n>`) — the ProjectV2 number. If omitted, list the org's boards and ask the user to pick one: `gh project list --owner <ORG> --format json`.
- `--to <emails>` — comma-separated recipient list. If omitted, ask for it in Step 3 (no default).
- `--label <text>` — subject-line label for the client/project. If omitted, default to the board's own `title` (fetched in Step 1).

Hold these as `<ORG>`, `<PROJECT>`, `<RECIPIENTS>`, and `<LABEL>` for the rest of the run.

Also resolve the sender name once: `gh api user -q '.name // .login'` → `<SENDER>`.

---

## Step 1 — Fetch all board items

```bash
gh api graphql -f query='
query($org: String!, $number: Int!) {
  organization(login: $org) {
    projectV2(number: $number) {
      title
      items(first: 100) {
        nodes {
          fieldValues(first: 20) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field { ... on ProjectV2FieldCommon { name } }
              }
            }
          }
          content {
            ... on Issue {
              number
              title
              url
              assignees(first: 5) { nodes { login } }
            }
            ... on DraftIssue {
              title
            }
          }
        }
      }
    }
  }
}' -f org=<ORG> -F number=<PROJECT>
```

If `<LABEL>` was not provided as an argument, use the returned `projectV2.title` as `<LABEL>`.

Parse the response and group items by their `Status` field value into buckets:

- **Done** — any status containing "done", "complete", "merged", or "closed" (case-insensitive)
- **Ready for Review** — any status containing "review"
- **In Progress** — any status containing "in progress" or "in-progress"
- **To Do** — any status containing "todo", "to do", or "backlog"
- **Other** — anything that doesn't match the above

For each item hold: title, issue number (if linked), assignee logins, status, and URL.

---

## Step 2 — Ask about stalled items

For every item in **To Do** and **In Progress**, you need a reason to include in the report.

Ask the user about all stalled items in a single **AskUserQuestion** call. List each item by title and ask for a brief note — one question per item, up to 4 at a time. If there are more than 4 stalled items, batch them in rounds.

Example question format:

> "These items didn't complete this sprint. Add a brief note for each (blocker, deprioritized, carried over, etc.):"
>
> - #12 Add Forgot Password Screen _(In Progress)_
> - #15 Nurse role screen locks _(To Do)_

Collect a note for each. If the user leaves one blank, use "Carried over to next sprint."

---

## Step 3 — Ask for sprint metadata

Use a single **AskUserQuestion** call (multiSelect: false, open-ended) to collect (up to 4 questions total):

> "What sprint is this closing? (e.g. 'Sprint 4 · June 16–27')"

> "Anything else to highlight this sprint? (optional wins, blockers, or shoutouts)"

If `<RECIPIENTS>` was **not** supplied via `--to`, also ask in this same batch:

> "Who should receive this report? (comma-separated email addresses)"

Set `<RECIPIENTS>` from the answer.

---

## Step 4 — Draft the email

Write the email using the structure below. Use plain, professional prose — not bullet soup. Be concise.

**Formatting:** plain text only. Do **not** use tables or any character-based/ASCII layout (aligned columns, pipes, box drawing) — they look fine in a terminal but break when pasted into Outlook. Use short paragraphs and simple bullet lists.

---

**Subject:** <LABEL> · Sprint Report — [Sprint Name]

**To:** <RECIPIENTS>

Here's a summary of where things stand at the close of [Sprint Name].

**Completed**
[For each Done/Merged item: one line — issue title, brief description of what it delivers. If there are none, say so.]

**In Review**
[For each Ready for Review item: one line — issue title and what's waiting on it.]

**Carried Over**
[For each In Progress and To Do item: issue title followed by the user's note in parentheses. If there are none, omit this section.]

[If the user provided highlights/wins/shoutouts, include a short "Highlights" paragraph here.]

Let me know if you have any questions.

<SENDER>

---

Do not show the draft to the user or ask for approval — proceed directly to Step 5.

---

## Step 5 — Open in Outlook Web

URL-encode the subject and body and open a pre-filled Outlook Web compose window:

```bash
python3 - <<'EOF'
import urllib.parse, subprocess

subject = """SUBJECT_PLACEHOLDER"""
body = """BODY_PLACEHOLDER"""
to = """RECIPIENTS_PLACEHOLDER"""

params = {"subject": subject, "body": body}
if to:
    params["to"] = to

url = "https://outlook.office.com/mail/deeplink/compose?" + urllib.parse.urlencode(params, quote_via=urllib.parse.quote)
subprocess.run(["open", url])
EOF
```

Replace `SUBJECT_PLACEHOLDER` with the final subject line (without the `Subject:` label), `BODY_PLACEHOLDER` with the full email body text, and `RECIPIENTS_PLACEHOLDER` with `<RECIPIENTS>`.

After running, tell the user: "Compose window opened — edit and send when ready."
