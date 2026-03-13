---
name: pinchtab
description: >
  Browser automation via PinchTab — an HTTP server that controls Chrome instances.
  Use this skill whenever the user wants to automate a browser, scrape a website,
  fill out a form, click buttons on a page, take screenshots, extract text from
  web pages, navigate URLs, interact with web UIs, run browser-based workflows,
  or do anything involving controlling Chrome programmatically. Also trigger when
  the user mentions "PinchTab", "browser automation", "headless Chrome",
  "headed Chrome", "web scraping", "accessibility snapshot", or wants to open a
  URL and interact with it. Even if the user just says "go to this website and
  click X" or "fill out this form", use this skill.
---

# PinchTab Browser Automation Skill

PinchTab is a standalone HTTP server that gives direct control over Chrome through
a cURL-based HTTP API. This skill uses the **cURL API exclusively** (no CLI binary
needed in PATH).

**Base URL:** `http://localhost:9867`

## Prerequisites — Check Server Health First

Before doing ANYTHING with PinchTab, always verify the server is running:

```bash
curl -s http://localhost:9867/health | jq .
```

**If the health check fails** (connection refused, timeout, etc.), stop and tell
the user:

> PinchTab server is not running. Please start it in a separate terminal with:
> ```
> pinchtab
> ```
> Then try again. You can verify it's up with: `curl http://localhost:9867/health`

Do NOT proceed with any other PinchTab commands until health returns `{"status":"ok"}`.

## Core Workflow

The standard interaction loop is:

```
1. Ensure server is healthy
2. Start or reuse an instance (headed by default)
3. Navigate to a URL
4. Observe the page (snapshot / text / screenshot)
5. Act on elements (click, type, fill, press, scroll, select)
6. Repeat 4-5 as needed
7. Optionally stop the instance when done
```

## Step-by-Step Reference

### 1. Check for Running Instances

```bash
curl -s http://localhost:9867/instances | jq .
```

If an instance is already running, you can reuse it. Note its `id` for later use.

### 2. Start a Browser Instance

**Default: HEADED mode** (visible Chrome window). Only use headless if the user
explicitly requests it.

```bash
# Headed (DEFAULT — visible Chrome window)
curl -s -X POST http://localhost:9867/instances/start \
  -H "Content-Type: application/json" \
  -d '{"mode":"headed"}' | jq .
```

```bash
# Headless (only if user explicitly asks for headless)
curl -s -X POST http://localhost:9867/instances/start \
  -H "Content-Type: application/json" \
  -d '{"mode":"headless"}' | jq .
```

Response gives you `id`, `port`, `headless`, `status`. Wait for status `"running"`.

**With a named profile** (persists cookies/state across sessions):

```bash
# Create a profile first (optional)
curl -s -X POST http://localhost:9867/profiles \
  -H "Content-Type: application/json" \
  -d '{"name":"my-profile"}' | jq .

# Start instance with that profile
curl -s -X POST http://localhost:9867/instances/start \
  -H "Content-Type: application/json" \
  -d '{"profileId":"PROFILE_ID","mode":"headed"}' | jq .
```

### 3. Navigate to a URL

```bash
curl -s -X POST http://localhost:9867/navigate \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com"}' | jq .
```

Returns `tabId`, `title`, `url`. Save the `tabId` for tab-scoped operations.

**Optional fields:** `tabId` (reuse existing tab), `newTab`, `timeout`,
`blockImages`, `blockAds`, `waitFor`, `waitSelector`.

### 4. Observe the Page

#### Accessibility Snapshot (preferred — token-efficient, returns element refs)

```bash
# Interactive elements only (most useful for agent workflows)
curl -s "http://localhost:9867/snapshot?filter=interactive" | jq .
```

Returns `nodes` array with `ref` (like `e0`, `e1`, etc.), `role`, and `name`
for each element. These refs are used by action commands.

**Query params:** `filter` (interactive), `format`, `diff`, `selector`,
`maxTokens`, `depth`.

#### Text Extraction

```bash
curl -s "http://localhost:9867/text" | jq .
# Raw innerText mode:
curl -s "http://localhost:9867/text?mode=raw" | jq .
```

**Query params:** `mode=raw`, `maxChars`, `format=text`.

#### Screenshot (save to file on PinchTab server)

```bash
curl -s "http://localhost:9867/screenshot?output=file" | jq .
```

Returns `path` to the saved image on the server filesystem.

**Query params:** `quality`, `raw`, `output=file`, `tabId`.

### 5. Find Elements by Natural Language

Instead of manually scanning the snapshot, use `/find` to locate elements:

```bash
curl -s -X POST http://localhost:9867/find \
  -H "Content-Type: application/json" \
  -d '{"query":"login button"}' | jq .
```

Returns `best_ref`, `confidence` (high/medium/low), `score`, and `matches`.
Use `best_ref` directly with action commands when confidence is `high`.

**Optional fields:** `tabId`, `threshold`, `topK`, `explain`.

### 6. Perform Actions

All actions go through `POST /action` with a `kind` field:

#### Click
```bash
curl -s -X POST http://localhost:9867/action \
  -H "Content-Type: application/json" \
  -d '{"kind":"click","ref":"e5"}' | jq .
```

#### Type (sends key events character by character)
```bash
curl -s -X POST http://localhost:9867/action \
  -H "Content-Type: application/json" \
  -d '{"kind":"type","ref":"e8","text":"Hello World"}' | jq .
```

#### Fill (sets value directly — faster, no key events)
```bash
curl -s -X POST http://localhost:9867/action \
  -H "Content-Type: application/json" \
  -d '{"kind":"fill","ref":"e8","text":"user@example.com"}' | jq .
```

Use `fill` for inputs where you just need to set the value.
Use `type` when the page needs to see individual keystrokes (autocomplete, etc.).

#### Press (keyboard key)
```bash
curl -s -X POST http://localhost:9867/action \
  -H "Content-Type: application/json" \
  -d '{"kind":"press","key":"Enter"}' | jq .
```

Common keys: `Enter`, `Tab`, `Escape`, `ArrowDown`, `ArrowUp`, `Backspace`.

#### Scroll
```bash
curl -s -X POST http://localhost:9867/action \
  -H "Content-Type: application/json" \
  -d '{"kind":"scroll","direction":"down"}' | jq .
```

Directions: `up`, `down`. Can also use `scrollY` for pixel amounts.

#### Select (dropdown)
```bash
curl -s -X POST http://localhost:9867/action \
  -H "Content-Type: application/json" \
  -d '{"kind":"select","ref":"e12","value":"option-value"}' | jq .
```

#### Hover
```bash
curl -s -X POST http://localhost:9867/action \
  -H "Content-Type: application/json" \
  -d '{"kind":"hover","ref":"e3"}' | jq .
```

#### Focus
```bash
curl -s -X POST http://localhost:9867/action \
  -H "Content-Type: application/json" \
  -d '{"kind":"focus","ref":"e8"}' | jq .
```

### 7. Tab-Scoped Operations

When you have a `tabId`, you can use tab-scoped routes for multi-tab workflows:

```bash
# Navigate a specific tab
curl -s -X POST http://localhost:9867/tabs/TAB_ID/navigate \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com"}' | jq .

# Snapshot a specific tab
curl -s "http://localhost:9867/tabs/TAB_ID/snapshot?filter=interactive" | jq .

# Action on a specific tab
curl -s -X POST http://localhost:9867/tabs/TAB_ID/action \
  -H "Content-Type: application/json" \
  -d '{"kind":"click","ref":"e5"}' | jq .

# Find on a specific tab
curl -s -X POST http://localhost:9867/tabs/TAB_ID/find \
  -H "Content-Type: application/json" \
  -d '{"query":"submit button"}' | jq .

# Text from a specific tab
curl -s "http://localhost:9867/tabs/TAB_ID/text" | jq .

# Screenshot a specific tab
curl -s "http://localhost:9867/tabs/TAB_ID/screenshot?output=file" | jq .

# Close a tab
curl -s -X POST http://localhost:9867/tabs/TAB_ID/close | jq .
```

### 8. JavaScript Evaluation (if enabled in config)

```bash
curl -s -X POST http://localhost:9867/evaluate \
  -H "Content-Type: application/json" \
  -d '{"expression":"document.title"}' | jq .
```

Requires `security.allowEvaluate: true` in PinchTab config.

### 9. PDF Export

```bash
curl -s "http://localhost:9867/tabs/TAB_ID/pdf?raw=true" > page.pdf
```

### 10. Manage Tabs

```bash
# List tabs
curl -s http://localhost:9867/tabs | jq .

# Open new tab in specific instance
curl -s -X POST http://localhost:9867/instances/INST_ID/tabs/open \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com"}' | jq .

# List all tabs across all instances
curl -s http://localhost:9867/instances/tabs | jq .
```

### 11. Stop an Instance

```bash
curl -s -X POST http://localhost:9867/instances/INST_ID/stop | jq .
```

## Profiles

Profiles persist browser state (cookies, local storage, history) across sessions.

```bash
# List profiles
curl -s http://localhost:9867/profiles | jq .

# Create profile
curl -s -X POST http://localhost:9867/profiles \
  -H "Content-Type: application/json" \
  -d '{"name":"work","description":"Work browser","useWhen":"Work accounts"}' | jq .

# Get profile details
curl -s http://localhost:9867/profiles/PROFILE_ID | jq .

# Start instance from profile
curl -s -X POST http://localhost:9867/profiles/PROFILE_ID/start \
  -H "Content-Type: application/json" \
  -d '{"headless":false}' | jq .

# Stop instance by profile
curl -s -X POST http://localhost:9867/profiles/PROFILE_ID/stop | jq .

# Delete profile
curl -s -X DELETE http://localhost:9867/profiles/PROFILE_ID | jq .
```

Note: `POST /profiles/{id}/start` uses `headless` (boolean) not `mode` (string).

## Best Practices

1. **Always check health first** before any operation.
2. **Default to headed mode** — only use headless if the user says so.
3. **Use snapshot with `filter=interactive`** to get clickable/fillable elements.
4. **Use `/find`** for natural-language element lookup instead of scanning snapshots.
5. **Use `fill` over `type`** when you just need to set a value (faster).
6. **Use `type`** when the page needs keystroke events (autocomplete, search-as-you-type).
7. **After clicking**, re-snapshot to see updated elements (refs change between pages).
8. **Save tabId** from navigate responses for multi-tab workflows.
9. **Prefer text extraction over screenshots** — it's more token-efficient.
10. **Use profiles** when you need to persist login state across sessions.

## Troubleshooting

- **Connection refused on :9867** → PinchTab server isn't running. Tell user to start it.
- **Instance stuck in "starting"** → Wait a few seconds, poll status. Chrome init takes 5-20s.
- **503 on navigate/snapshot** → Instance not ready yet or Chrome crashed. Check instance status/logs.
- **Empty snapshot** → Page may not have loaded yet. Use `waitSelector` in navigate, or add a `sleep`.
- **Stale refs** → Refs from snapshot are only valid for the current page state. Re-snapshot after navigation or clicks that change the DOM.

## Full API Documentation

For complete details, see: https://pinchtab.com/docs/index-2
