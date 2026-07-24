---
description: Draft a clear, concise client message to get clarification on something, written for a non-technical audience by default
argument-hint: "[what you need clarified] [--technical] [--outlook] [--to email]"
allowed-tools: Read, Grep, Glob, Bash(gh:*), Bash(az:*), Bash(git:*), Bash(python3:*), Bash(open:*)
model: sonnet
---

# /draft-message

Draft a short message asking a client to clarify something that's blocking work.

Three rules govern the output — hold them the whole way through:

1. **Clear and concise.** Respect the reader's time. Lead with the point, keep it short, make it easy to answer.
2. **Non-technical by default.** Assume the client is *not* technical. No jargon, no implementation detail, no internal tool/repo names. Describe things in terms of what the product does or what the user sees — not how it's built. (If `--technical` is passed, or the user says the client is technical, you may use appropriate domain terms — but stay concise.)
3. **No scope creep.** Ask only what's needed to unblock. Do **not** tack on related-but-optional questions ("while we're at it, should we also…?"). Extra questions burden the client and widen scope.

**Flags:** `--technical` (client is technical — relax rule 2), `--outlook` (open the draft in Outlook, Step 4), `--to <email>` (recipient for `--outlook`; optional).

---

## Step 1 — Understand what needs clarifying

From the argument (or by asking the user, briefly): what is the specific ambiguity or decision, and what work does it block?

If the user points at a ticket/issue, pull it for context. First detect the provider:

```bash
git remote get-url origin
```

**GitHub** (remote does not contain `dev.azure.com` / `visualstudio.com`):
```bash
gh issue view <NUMBER> --json title,body,url
```

**ADO** (remote contains `dev.azure.com`, `ssh.dev.azure.com`, or `visualstudio.com`):
```bash
az boards work-item show --id <ID> --org <ORG> \
  --fields System.Title,System.Description,System.AcceptanceCriteria \
  -o json
```
Strip HTML tags from `System.Description` and `System.AcceptanceCriteria` before reading.

Gather only what you need to write the ask. Don't interview the user extensively — that's its own kind of scope creep.

---

## Step 2 — Distill to a single, concrete ask

- Identify the **one** decision or piece of information you actually need to move forward.
- Cut everything not required to unblock. If you notice a *separate* blocker that also needs a client answer, raise it with **the user** and ask whether to include it — do not silently fold it into the message.
- Where possible, turn an open-ended question into a small set of **concrete options** (e.g. A vs. B). A non-technical client can pick between options far more easily than answering a blank question. Frame options by their real-world effect, not the technical difference.

---

## Step 3 — Write the message

Keep it to a few sentences (or a short option list). A good shape:

```
<One line of context — what we're working on and why this choice matters to the product.>

<The ask. If there are options, list them plainly with what each means for the user/business:>
- Option A: <plain-language description and its effect>
- Option B: <plain-language description and its effect>

<Single clear closing question, e.g. "Which of these fits how you'd like it to work?">
```

Omit the salutation ("Hi <name>,") and closing ("Thanks, <sender>") — the user will add those when they paste the message.

Tone: friendly, professional, neutral. No manufactured urgency — mention a deadline only if a real one exists. If it's a straight yes/no or a single fact, drop the options block and just ask directly in a sentence or two.

**Formatting:** plain text only — short sentences and simple bullet lists. Do **not** use tables or any character-based/ASCII layout (aligned columns, pipes, box drawing). They look fine in a terminal but break when pasted into email or a messaging app. If you're comparing options, use a bullet per option, not a table.

---

## Step 4 — Present the draft

Show the finished message, ready to copy-paste.

If `--outlook` was passed, also open the draft in an Outlook Web compose window (URL-encode the subject and body; derive a short subject from the topic, and set the recipient from `--to` if provided):

```bash
python3 - <<'EOF'
import urllib.parse, subprocess

subject = """SUBJECT_PLACEHOLDER"""
body = """BODY_PLACEHOLDER"""
to = """RECIPIENT_PLACEHOLDER"""

params = {"subject": subject, "body": body}
if to:
    params["to"] = to

url = "https://outlook.office.com/mail/deeplink/compose?" + urllib.parse.urlencode(params, quote_via=urllib.parse.quote)
subprocess.run(["open", url])
EOF
```

Replace `SUBJECT_PLACEHOLDER` with a short subject line, `BODY_PLACEHOLDER` with the message body, and `RECIPIENT_PLACEHOLDER` with the `--to` address (or leave empty). After opening, tell the user: "Compose window opened — edit and send when ready." If `--outlook` was not passed, don't send anywhere.

Briefly note (to the user, not in the message) any separate blocker you deliberately left out per Step 2, so nothing is lost. Offer one quick round of refinement.
