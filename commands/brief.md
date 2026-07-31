---
description: Morning project briefing. Scans ~/Documents/dt/ for active projects, loads each project's latest historian summary, and presents a prioritized status grouped by tier.
---

## Step 1 — Load priority config

Read `~/.claude/project-priorities.json`. It contains arrays `p1`, `p2`, `p3` (project directory names) and a `default_tier` fallback.

If the file does not exist, warn the user and offer to create a starter config, then stop.

## Step 2 — Load project snapshots

List all subdirectories of `~/Documents/dt/`. Skip non-directories and any name in the `ignore` array of the priority config.

For each remaining directory:
- If `DEBRIEF.md` exists in the project root → mark as **debriefed** and skip.
- Otherwise: look for `.md` files (excluding `TIMELINE.md`) in `~/.claude/history/<project-name>/`. Sort by filename date descending, take the most recent. Extract STATE and OPEN. If none found, mark as **no history**.

## Step 2b — Validate priority config entries

Cross-reference the project names listed in the `p1`, `p2`, and `p3` arrays of the priority config against the directory list from Step 2. Any name that appears in the config arrays but has no matching subdirectory in `~/Documents/dt/` is a stale entry. Collect these names — they will be surfaced at the end of the briefing (Step 4).

## Step 3 — Assign priorities

For each active project, determine its tier from the config:
- Check `p1`, `p2`, `p3` arrays in order — use the tier where the directory name appears.
- If not listed, use `default_tier`.

## Step 4 — Present the briefing

Output today's date as a header, then group projects by tier. Within each tier, sort by last-saved date descending (most recently active first). Projects with no history appear at the end of their tier group.

Use this format:

```
# Brief — <today's date>

## P1 — Time-sensitive
### <project-name>  (last saved: <date>)
**STATE:** <state section content, condensed to 1-2 sentences if long>
**OPEN:** <open items as a bullet list, or "nothing open" if section is absent>

---

## P2 — Active
...

## P3 — Background
...

## No history
- <project-name> — no saved summary yet
```

Omit any tier section entirely if it has no active projects. Do not mention debriefed projects.

Append this footer line: `_Source: live scan of ~/.claude/history/ — run /save on any project to refresh its snapshot._`

If any stale priority config entries were identified in Step 2b, append a warning after the footer:

```
Priority config references projects not found: X, Y — consider updating project-priorities.json.
```
