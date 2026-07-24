---
name: playwright-cli
description: Reference for browser automation with the playwright-cli tool. Use when automating browser interactions, scraping pages, filling forms, testing UI flows, or generating Playwright tests.
allowed-tools: Bash(playwright-cli:*), Bash(npx:*), Bash(npm:*)
---

# Browser Automation with playwright-cli

## Quick start

```bash
playwright-cli open
playwright-cli goto https://example.com
# interact using refs from the snapshot
playwright-cli click e15
playwright-cli type "search query"
playwright-cli press Enter
playwright-cli screenshot
playwright-cli close
```

## Commands

### Core

```bash
playwright-cli open
playwright-cli open https://example.com/
playwright-cli goto https://playwright.dev
playwright-cli type "search query"
playwright-cli click e3
playwright-cli dblclick e7
# --submit presses Enter after filling
playwright-cli fill e5 "user@example.com" --submit
playwright-cli drag e2 e8
playwright-cli drop e4 --path=./image.png
playwright-cli drop e4 --data="text/plain=hello world"
playwright-cli hover e4
playwright-cli select e9 "option-value"
playwright-cli upload ./document.pdf
playwright-cli check e12
playwright-cli uncheck e12
playwright-cli snapshot
playwright-cli eval "document.title"
playwright-cli eval "el => el.textContent" e5
playwright-cli eval "el => el.getAttribute('data-testid')" e5
playwright-cli dialog-accept
playwright-cli dialog-accept "confirmation text"
playwright-cli dialog-dismiss
playwright-cli resize 1920 1080
playwright-cli close
```

### Navigation

```bash
playwright-cli go-back
playwright-cli go-forward
playwright-cli reload
```

### Keyboard & Mouse

```bash
playwright-cli press Enter
playwright-cli press ArrowDown
playwright-cli keydown Shift
playwright-cli keyup Shift
playwright-cli mousemove 150 300
playwright-cli mousedown
playwright-cli mousedown right
playwright-cli mouseup
playwright-cli mousewheel 0 100
```

### Screenshots & PDF

```bash
playwright-cli screenshot
playwright-cli screenshot e5
playwright-cli screenshot --filename=page.png
playwright-cli pdf --filename=page.pdf
```

### Tabs

```bash
playwright-cli tab-list
playwright-cli tab-new
playwright-cli tab-new https://example.com/page
playwright-cli tab-close
playwright-cli tab-select 0
```

### Storage

```bash
playwright-cli state-save
playwright-cli state-save auth.json
playwright-cli state-load auth.json

# Cookies
playwright-cli cookie-list
playwright-cli cookie-get session_id
playwright-cli cookie-set session_id abc123 --domain=example.com --httpOnly --secure
playwright-cli cookie-delete session_id
playwright-cli cookie-clear

# LocalStorage
playwright-cli localstorage-list
playwright-cli localstorage-get theme
playwright-cli localstorage-set theme dark
playwright-cli localstorage-clear

# SessionStorage
playwright-cli sessionstorage-get step
playwright-cli sessionstorage-set step 3
```

### Network mocking

```bash
playwright-cli route "**/*.jpg" --status=404
playwright-cli route "https://api.example.com/**" --body='{"mock": true}'
playwright-cli route-list
playwright-cli unroute "**/*.jpg"
playwright-cli unroute
```

### DevTools & Debugging

```bash
playwright-cli console
playwright-cli console warning
playwright-cli network
playwright-cli run-code "async page => await page.context().grantPermissions(['geolocation'])"
playwright-cli run-code --filename=script.js
playwright-cli tracing-start
playwright-cli tracing-stop
playwright-cli video-start video.webm
playwright-cli video-stop
playwright-cli generate-locator e5 --raw
playwright-cli highlight e5
playwright-cli highlight e5 --style="outline: 3px dashed red"
playwright-cli highlight --hide
# launch dashboard with annotation prompt
playwright-cli show --annotate
```

### Browser Sessions

```bash
playwright-cli -s=mysession open example.com --persistent
playwright-cli -s=mysession click e6
playwright-cli -s=mysession close
playwright-cli list
playwright-cli close-all
playwright-cli kill-all
```

### Open options

```bash
playwright-cli open --browser=chrome
playwright-cli open --browser=firefox
playwright-cli open --browser=webkit
playwright-cli open --browser=msedge
playwright-cli open --persistent
playwright-cli open --profile=/path/to/profile
playwright-cli attach --cdp=http://localhost:9222
```

## Targeting elements

Use refs from the snapshot (preferred):
```bash
playwright-cli snapshot
playwright-cli click e15
```

Or CSS/Playwright locators:
```bash
playwright-cli click "#main > button.submit"
playwright-cli click "getByRole('button', { name: 'Submit' })"
playwright-cli click "getByTestId('submit-button')"
```

## Snapshots

Each command returns a snapshot of the current page state. Take one on demand:
```bash
playwright-cli snapshot
playwright-cli snapshot --depth=4        # limit depth for large pages
playwright-cli snapshot e34              # snapshot a specific element
playwright-cli snapshot --boxes          # include bounding boxes
playwright-cli snapshot --filename=after-click.yaml
```

## Raw output

Strip status/code/snapshot sections with `--raw`:
```bash
playwright-cli --raw eval "JSON.stringify(performance.timing)" | jq '.loadEventEnd - .navigationStart'
playwright-cli --raw snapshot > before.yml
playwright-cli click e5
playwright-cli --raw snapshot > after.yml
diff before.yml after.yml
```

## Installation

If `playwright-cli` is not available globally:
```bash
npx --no-install playwright-cli --version
# or install globally
npm install -g @playwright/cli@latest
```

## Examples

### Form submission
```bash
playwright-cli open https://example.com/form
playwright-cli snapshot
playwright-cli fill e1 "user@example.com"
playwright-cli fill e2 "password123"
playwright-cli click e3
playwright-cli snapshot
playwright-cli close
```

### Multi-tab workflow
```bash
playwright-cli open https://example.com
playwright-cli tab-new https://example.com/other
playwright-cli tab-list
playwright-cli tab-select 0
playwright-cli snapshot
playwright-cli close
```

### Auth state persistence
```bash
playwright-cli open https://example.com/login --persistent --profile=./auth-profile
playwright-cli fill e1 "user@example.com"
playwright-cli fill e2 "password"
playwright-cli click e3
playwright-cli state-save auth.json
playwright-cli close
# Reuse saved state in next session
playwright-cli open https://example.com --persistent
playwright-cli state-load auth.json
```

### Network debugging
```bash
playwright-cli open https://example.com
playwright-cli tracing-start
playwright-cli click e4
playwright-cli fill e7 "test"
playwright-cli console
playwright-cli network
playwright-cli tracing-stop
playwright-cli close
```
