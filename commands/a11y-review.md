---
name: a11y-review
description: Accessibility and REST semantics review. Checks the current diff for WCAG 2.1 AA violations (keyboard nav, contrast, ARIA, touch targets, motion) and HTTP verb correctness (GET/POST/PUT/PATCH/DELETE semantics). Run standalone or as part of /review-report.
allowed-tools: Bash(git:*), Read, Grep, Glob
---

# /a11y-review

Two focused lenses on the current diff: WCAG 2.1 AA accessibility compliance, and correct HTTP verb semantics. These are distinct from code smells — they catch a class of bugs that `/smell` and `/code-review` don't cover.

---

## Step 1 — Collect the diff

```bash
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed "s@^refs/remotes/@@")
[ -z "$BASE" ] && BASE="origin/main"
git diff "$BASE"...HEAD
```

If the diff is empty, also check working-tree changes: `git diff HEAD`.

---

## Step 2 — Identify in-scope files

- **Accessibility scan** — applies to: UI components (`.tsx`, `.jsx`, `.html`, `.svelte`, `.vue`), templates, any file that renders interactive elements or content
- **HTTP semantics scan** — applies to: API route handlers, controllers, server actions, any file defining HTTP endpoints

If neither type of file is in the diff, emit: `No UI or API files in this diff — a11y and HTTP semantics checks not applicable.` and stop.

---

## Step 3 — Accessibility scan (WCAG 2.1 AA)

Walk every UI file in the diff. Apply these checks — report only what the diff introduces or changes, not pre-existing issues.

### Level A (must pass)

| ID | Check | What to look for |
|---|---|---|
| **A11Y.KEYBOARD** | Keyboard navigation | Interactive elements (`button`, `a`, custom controls) must be focusable and operable by keyboard. Flag `div`/`span` with click handlers that have no `tabIndex`, `role`, or keyboard event handler. |
| **A11Y.HEADING** | Heading hierarchy | `h1`–`h6` must not skip levels. Flag where a heading level jumps (e.g. `h1` → `h3` with no `h2`). |
| **A11Y.LABEL** | Form labels | Every `input`, `select`, `textarea` must have an associated `<label>`, `aria-label`, or `aria-labelledby`. Flag unlabeled form controls. |
| **A11Y.ALT** | Image alt text | `<img>` must have `alt`. Decorative images use `alt=""`. Flag missing or meaningless alt text (`alt="image"`, `alt="icon"`). |
| **A11Y.COLOR-ONLY** | Color as sole indicator | State (error, success, selected, disabled) must not rely on color alone. Flag when only a color change communicates state with no accompanying text, icon, or pattern. |

### Level AA (must pass)

| ID | Check | What to look for |
|---|---|---|
| **A11Y.CONTRAST** | Color contrast | Body text: 4.5:1 minimum. Large text (18pt / 14pt bold): 3:1 minimum. Flag hardcoded colors that are likely to fail (light gray on white, low-contrast palette choices). Note: exact ratios require a tool — flag obvious violations and note that a contrast checker should be run. |
| **A11Y.TOUCH** | Touch target size | Interactive elements should be at least 44×44px (CSS). Flag targets explicitly sized smaller (e.g. `w-4 h-4` on a button with no padding). |
| **A11Y.ZOOM** | Zoom support | Avoid `user-scalable=no` in viewport meta tags. Avoid fixed pixel sizes on containers that would cause horizontal scroll at 200% zoom. |
| **A11Y.MOTION** | Reduced motion | Animations and transitions should respect `prefers-reduced-motion`. Flag CSS animations or JS-driven motion with no `prefers-reduced-motion` media query guard. |

### ARIA

| ID | Check | What to look for |
|---|---|---|
| **A11Y.ARIA-ROLE** | Correct roles | Flag invalid or misused ARIA roles (e.g. `role="button"` on an `<a>`, `role="dialog"` without managed focus). Prefer semantic HTML over ARIA. |
| **A11Y.ARIA-LIVE** | Live regions | Dynamic content changes (status messages, loading states, error notifications) should use `aria-live` or `role="status"` / `role="alert"` so screen readers announce them. Flag status changes with no live region. |
| **A11Y.ARIA-REQUIRED** | Required ARIA attributes | Some roles require specific attributes (e.g. `role="combobox"` requires `aria-expanded`). Flag roles missing their required attributes. |

---

## Step 4 — HTTP semantics scan

Walk every API/endpoint file in the diff. Apply these checks:

| ID | Verb | Required behavior |
|---|---|---|
| **HTTP.GET** | GET | Must be read-only and safe (no side effects). Flag GETs that write to the database or trigger mutations. |
| **HTTP.POST** | POST | Creates a resource. Should return `201 Created` with the new resource, or `200 OK` for RPC-style actions. |
| **HTTP.PUT** | PUT | Wholesale replace — all properties must be provided and persisted. Flag PUTs that do partial updates (that's PATCH). |
| **HTTP.PATCH** | PATCH | Partial update — only provided/non-null fields are updated. Flag PATCHes that replace the entire resource. |
| **HTTP.DELETE** | DELETE | Must be idempotent — deleting a non-existent resource should not return an error (return `204 No Content` always). Flag DELETEs that return `404` when the resource is already gone, or that return the deleted resource in the body. |
| **HTTP.IDEMPOTENT** | PUT/DELETE | Must be safe to retry. Flag non-idempotent implementations (e.g. a PUT that appends rather than replaces). |

---

## Step 5 — Report

Emit exactly this structure:

```markdown
# A11y & HTTP Semantics Review
**Base:** `<base-branch>`
**Files scanned:** <N UI files, M API files>

## Summary
- Accessibility findings: X blocker, Y high, Z medium
- HTTP semantics findings: A blocker, B high
- Top risk: <one sentence>

## Findings

### [BLOCKER] `A11Y.KEYBOARD` — `src/components/Dropdown.tsx:42`
```tsx
<div onClick={handleSelect}>...</div>
```
**Why:** Click-only handler; keyboard users cannot activate this control.
**Fix:** Replace with `<button>` or add `role="button"`, `tabIndex={0}`, and `onKeyDown` handler for Enter/Space.

### [HIGH] `HTTP.DELETE` — `src/api/members/[id]/route.ts:18`
**Why:** Returns `404` when member is already deleted; DELETE must be idempotent.
**Fix:** Return `204 No Content` regardless of whether the resource existed.

### [MEDIUM] `A11Y.MOTION` — `src/components/Sidebar.tsx:88`
```css
transition: transform 0.3s ease;
```
**Why:** Animation has no `prefers-reduced-motion` guard.
**Fix:** Wrap in `@media (prefers-reduced-motion: no-preference)` or use the `useReducedMotion` hook.
```

Severity mapping:
- **BLOCKER** — prevents access for some users (keyboard trap, missing label on required field) or breaks REST contract in a data-corrupting way (PUT doing partial update silently)
- **HIGH** — significant accessibility barrier or clearly incorrect HTTP behavior
- **MEDIUM** — best-practice gap; real users affected but workarounds exist
- **LOW / NIT** — minor; mention briefly without a full block

If no findings: emit the header and "No accessibility or HTTP semantics issues found in this diff."
