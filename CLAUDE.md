# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Ultimate Turbo Modal (UTMR) v3 is a full-featured modal and drawer implementation for Rails applications using Turbo, Stimulus, and Hotwire. It consists of a **Ruby gem** (server-side HTML generation via Phlex) and an **npm package** (client-side behavior via Stimulus). v3 is built on the native HTML `<dialog>` element, eliminating external dependencies for focus trapping and transitions.

## Project Structure

```
/                               # Ruby gem root
├── VERSION                     # Single source of truth for version (read by both gem and npm)
├── ultimate_turbo_modal.gemspec
├── Gemfile                     # Gem dev dependencies (standard, standard-rails)
├── Rakefile                    # Default task: standard (Ruby linter)
├── CHANGELOG.md
├── lib/
│   ├── ultimate_turbo_modal.rb         # Entry point, factory method, flavor loading
│   ├── ultimate_turbo_modal/
│   │   ├── version.rb                  # Reads VERSION file
│   │   ├── configuration.rb            # Config class + UltimateTurboModal.configure
│   │   ├── base.rb                     # Core Phlex component (HTML rendering)
│   │   ├── railtie.rb                  # Rails integration (hooks helpers into AC/AV)
│   │   └── helpers/
│   │       ├── controller_helper.rb    # inside_modal? method
│   │       ├── view_helper.rb          # modal() and drawer() view helpers
│   │       └── stream_helper.rb        # turbo_stream.modal(:close) helper
│   ├── phlex/
│   │   └── deferred_render_with_main_content.rb  # Phlex mixin for deferred rendering
│   └── generators/ultimate_turbo_modal/
│       ├── base.rb                     # Shared generator logic (JS package detection)
│       ├── install_generator.rb        # `rails g ultimate_turbo_modal:install`
│       ├── update_generator.rb         # `rails g ultimate_turbo_modal:update`
│       └── templates/
│           ├── ultimate_turbo_modal.rb # Initializer template
│           └── flavors/
│               ├── tailwind.rb         # Tailwind v4+ classes (modal + drawer)
│               ├── vanilla.rb          # Vanilla CSS classes (modal + drawer)
│               └── custom.rb           # Empty template for user-defined styling
├── javascript/                 # npm package source
│   ├── package.json            # npm: "ultimate_turbo_modal"
│   ├── index.js                # Entry: Turbo stream actions, frame handlers, exports
│   ├── modal_controller.js     # Stimulus controller (modal + drawer behavior)
│   ├── rollup.config.js        # Build config (ESM output, terser, version replacement)
│   ├── styles/
│   │   └── vanilla.css         # Vanilla CSS flavor styles + animations
│   ├── scripts/
│   │   ├── release-npm.sh      # npm publish script
│   │   └── update-version.js   # Syncs VERSION → package.json version
│   └── dist/                   # Built output (committed, published to npm)
├── script/
│   └── build_and_release.sh    # Combined gem + npm release script
└── demo-app/                   # Rails 8 app for manual testing
    ├── Procfile.dev             # Run with overmind/foreman
    └── ...                     # Uses path gem + link:../javascript for local dev
```

## Architecture

### How the Pieces Fit Together

1. **Server-Side (Ruby Gem)**: The `modal()` or `drawer()` view helper instantiates `UltimateTurboModal.new(...)`, which resolves the configured flavor class (e.g., `UltimateTurboModal::Flavors::Tailwind`). This class inherits from `UltimateTurboModal::Base` (a Phlex component) and defines CSS class constants. The base class renders a `<dialog>` element with data attributes that configure the Stimulus controller, plus inline `<style>` for animations.

2. **Client-Side (npm Package)**: The Stimulus `modal` controller connects when the `<dialog>` appears in the DOM. It calls `showModal()`, manages CSS animations for enter/leave, handles scroll locking (via native dialog), browser history, and dismissal via ESC/click-outside/form-submission. No external animation or focus-trap libraries are needed.

3. **Communication**: Turbo Frames (`<turbo-frame id="modal">`) carry modal content. Turbo Streams can send `modal` stream actions to close modals from the server. Idiomorph is used for intelligent DOM morphing to prevent flicker when modal content updates.

### Flavor System

Flavors are Ruby classes that inherit from `UltimateTurboModal::Base` and define constants for CSS classes. They live in `config/initializers/` in the consuming Rails app (copied there by the install generator). Available flavors:

- **`tailwind`** — Tailwind CSS v4+ (default). Uses utility classes and `group-data-[*]` selectors.
- **`vanilla`** — Plain CSS with classes defined in `javascript/styles/vanilla.css`.
- **`custom`** — Empty template for users to define their own classes.

Each flavor defines **modal constants** and **drawer constants**:

Modal: `DIALOG_CLASSES`, `DIV_INNER_CLASSES`, `DIV_CONTENT_CLASSES`, `DIV_MAIN_CLASSES`, `DIV_HEADER_CLASSES`, `DIV_TITLE_CLASSES`, `DIV_TITLE_H_CLASSES`, `DIV_FOOTER_CLASSES`, `BUTTON_CLOSE_CLASSES`, `BUTTON_CLOSE_SR_ONLY_CLASSES`, `CLOSE_BUTTON_TAG_CLASSES`, `ICON_CLOSE_CLASSES`

Drawer: `DRAWER_DIALOG_CLASSES`, `DRAWER_WRAPPER_CLASSES`, `DRAWER_PANEL_CLASSES`, `DRAWER_CONTENT_CLASSES`, `DRAWER_HEADER_CLASSES`, `DRAWER_TITLE_CLASSES`, `DRAWER_TITLE_H_CLASSES`, `DRAWER_MAIN_CLASSES`, `DRAWER_FOOTER_CLASSES`, `DRAWER_CLOSE_CLASSES`, `DRAWER_CLOSE_BUTTON_CLASSES`, `DRAWER_CLOSE_SR_CLASSES`, `DRAWER_CLOSE_ICON_CLASSES`

### Modal HTML Structure

```
<dialog#modal-container> (data-controller="modal", data-* config)
  <style> (inline @keyframes animations)
  turbo-frame#modal-inner (only when turbo frame request)
    #modal-inner
      #modal-content (data-modal-target="content")
        #modal-header
          #modal-title / #modal-title-h
          #modal-close > button
        #modal-main (user content rendered here)
        #modal-footer (optional)
```

### Drawer HTML Structure

```
<dialog#modal-container> (data-controller="modal", data-drawer="right|left", data-* config)
  <style> (inline CSS transitions + --utmr-drawer-width variable)
  turbo-frame#modal-inner (only when turbo frame request)
    #drawer-wrapper
      #drawer-panel (data-modal-target="content")
        #modal-content
          #modal-header
            #modal-title / #modal-title-h
            #modal-close > button
          #modal-main (user content rendered here)
          #modal-footer (optional)
```

### Stimulus Controller Targets and Values

- **Targets**: `container`, `content`
- **Values**: `advanceUrl` (String), `allowedClickOutsideSelector` (String)

### Data Attributes on `<dialog#modal-container>`

Set by the Ruby side, used for conditional styling via CSS selectors:
- `data-padding`, `data-title`, `data-header`, `data-close-button`, `data-header-divider`, `data-footer-divider`
- `data-drawer` (position: "right" or "left", only present for drawers)
- `data-drawer-size`, `data-overlay` (drawer-specific)
- `data-enter-ready`, `data-entered` (drawer animation state, managed by JS)
- `data-closing` (closing animation state, managed by JS)
- `data-utmr-version` (dev/test only, for version mismatch warnings)

## Configuration Options

Options can be set at three levels (lowest wins):
1. **Global defaults** via `UltimateTurboModal.configure` block in an initializer
2. **Per-instance** via the `modal()` or `drawer()` view helpers
3. **Block content** via `m.title { }` and `m.footer { }` blocks

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `flavor` | Symbol/String | `:tailwind` | CSS framework flavor |
| `advance` | Boolean or String | `true` | Push URL to browser history; String for custom URL. Auto-disabled for drawers. |
| `close_button` | Boolean | `true` | Show close button |
| `padding` | Boolean or String | `true` | Add padding to modal content |
| `header` | Boolean | `true` | Show header section |
| `header_divider` | Boolean | `true` | Show divider below header. Auto-disabled for drawers. |
| `footer_divider` | Boolean | `true` | Show divider above footer |
| `title` | String | `nil` | Modal title text |
| `drawer` | `false`, `:right`, `:left` | `false` | Render as drawer instead of modal |
| `drawer_size` | Symbol or String | `:md` | Drawer width: `:sm`, `:md`, `:lg`, `:xl`, `:full`, or CSS string |
| `overlay` | Boolean | `true` | Show backdrop overlay. Drawers default to `false` via the `drawer()` helper. |
| `allowed_click_outside_selector` | Array | `[]` | CSS selectors for elements outside modal that won't dismiss it |
| `close_button_data_action` | String | `"modal#hideModal"` | Custom data-action for close button |
| `close_button_sr_label` | String | `"Close modal"` | Screen reader label for close button |
| `content_div_data` | Hash | `nil` | Additional data attributes on `#modal-content` |

### Adding New Configuration Options

When adding a new option:
1. Add to `Configuration` class with getter/setter (use `boolean_option` macro for booleans, custom setter for validated options)
2. Add to `UltimateTurboModal` delegators if it should be globally configurable
3. Add to `Base#initialize` parameters with default from configuration
4. Pass to JavaScript via data attributes in `Base#dialog_element` if needed by the controller
5. Add as Stimulus value in `modal_controller.js` if JavaScript needs to read it
6. Add corresponding CSS selectors in flavor files if styling depends on it (both modal and drawer constants)
7. Update README.md

## Modal Lifecycle

1. User clicks a link with `data-turbo-frame="modal"` (or submits a form targeting that frame)
2. Rails controller renders the view; the `modal()` helper wraps content in a `<turbo-frame id="modal">`
3. Turbo replaces the frame content; Stimulus `modal` controller `connect()` fires
4. Controller calls `dialog.showModal()`, which locks body scroll and traps focus natively
5. For modals: CSS `@keyframes` animate entry. For drawers: `data-enter-ready` then `data-entered` attributes trigger CSS transitions via `requestAnimationFrame` double-frame technique
6. If `advance` is enabled, pushes URL to browser history
7. User interacts; forms submit via Turbo within the modal
8. Dismissal triggers: ESC key (intercepted via `cancel` event), close button, outside click, successful form submission, `history.back()`, or programmatic `window.modal.hide()`
9. `modal:closing` event fires (cancelable — if `preventDefault()` is called, modal stays open)
10. `data-closing` attribute set on dialog, triggering leave animations
11. After animation/transition ends (or timeout fallback): `dialog.close()`, DOM cleanup, frame `src` removed, history restored
12. `modal:closed` event fires (not cancelable)

### Server-Side Dismissal

```ruby
turbo_stream.modal(:close)  # or :hide
```

### Detecting Modal Context

```ruby
if inside_modal?
  # Render modal-specific content
end
```
Checks for the `Turbo-Frame: modal` request header.

### Programmatic Access

The modal controller instance is available as `window.modal` while a modal is open:
- `window.modal.hide()` / `window.modal.close()` / `window.modal.hideModal()` — dismiss
- `window.modal.refreshPage()` — Turbo visit to refresh the current page

### JavaScript Events

- `modal:closing` (cancelable) — dispatched on the turbo-frame before hiding begins
- `modal:closed` (not cancelable) — dispatched on the turbo-frame after cleanup

## Development

### Prerequisites
- Ruby >= 3.0 (project uses `.ruby-version`)
- Node.js + npm
- Bundler

### Common Commands

```bash
# Ruby linting (default rake task)
bundle exec rake standard        # or just: bundle exec rake

# Build the gem
gem build ultimate_turbo_modal.gemspec

# JavaScript (from /javascript/)
cd javascript
npm install
npm run build                     # Rollup build → dist/
npm run build:watch               # Watch mode

# Demo app (from /demo-app/)
cd demo-app
bin/dev                           # Starts Rails + CSS + JS + lib watchers via Procfile.dev
# Runs on http://localhost:3000
# Showcase at /, testing pages at /testing/*

# Full release (gem + npm)
./script/build_and_release.sh     # Options: --skip-gem, --skip-js
```

### Demo App Details

The demo app is a Rails 8 app using:
- Propshaft (asset pipeline)
- jsbundling-rails (esbuild) + cssbundling-rails (PostCSS + Tailwind v4)
- SQLite3 + Faker for seed data
- Links the gem via `path: "../"` and the JS package via `link:../javascript`
- The `SetFlavor` concern dynamically switches flavors based on URL params/cookies
- `bin/dev` symlinks flavor files from the gem's `templates/flavors/` into `config/initializers/` before starting
- Showcase route at `/` with polished demo; testing pages under `/testing/*` namespace
- `Procfile.dev` runs 4 processes: web server, CSS watcher, JS watcher, and library JS watcher

### Version Management

The `VERSION` file at the repo root is the single source of truth:
- **Ruby gem**: `lib/ultimate_turbo_modal/version.rb` reads it via `File.read`
- **npm package**: `javascript/scripts/update-version.js` syncs it to `package.json`
- **Version check**: In dev/test, the gem passes its version as a data attribute; the JS controller uses `#normalizeVersion()` to compare gem format (`3.0.0.alpha`) against npm format (`3.0.0-alpha.0`) and warns on mismatch

### Release Process

1. Update `VERSION` file with new version
2. Update `CHANGELOG.md`
3. Commit changes
4. Run `./script/build_and_release.sh` which:
   - Builds JS package, updates demo app deps, commits lock files
   - Runs `bundle exec rake release` (builds gem, creates git tag, pushes to RubyGems)
   - Runs `javascript/scripts/release-npm.sh` (syncs version, builds, commits, publishes to npm)

### Build System

The JavaScript package uses Rollup with these plugins:
- `@rollup/plugin-node-resolve` — resolves node_modules
- `rollup-plugin-css-only` — extracts vanilla.css to `dist/vanilla.css`
- `@rollup/plugin-replace` — replaces `__PACKAGE_VERSION__` placeholder with actual version
- `rollup-plugin-terser` — minifies the `.min.js` output

Output: ESM format. `@hotwired/stimulus` is marked as external (not bundled).

### Linting

- **Ruby**: [Standard Ruby](https://github.com/standardrb/standard) with `standard-rails` plugin. Run `bundle exec rake` (default task). Config in `.standard.yml`. Standard enforces no semicolons, double quotes, and other opinionated rules — do not add RuboCop-style configurations that conflict.
- **JavaScript**: No linter currently configured.

## Key Dependencies

### Ruby Gem
- `phlex-rails` — Component-based HTML rendering
- `turbo-rails` — Turbo Frame/Stream helpers
- `stimulus-rails` — Stimulus integration
- `actionpack`, `activesupport`, `railties` — Minimal Rails dependencies

### npm Package
- `@hotwired/stimulus` (^3.2.2) — Stimulus controller framework (external, not bundled)
- `@hotwired/turbo-rails` (^8.0.0) — Turbo integration
- `idiomorph` (^0.7.3) — Intelligent DOM morphing


## Important Implementation Details

### Inline Styles and Animations

`Base#styles` injects a `<style>` tag inside the dialog with all animation CSS:
- **Base styles** (both modal and drawer): `html:has(dialog[open])` scroll lock, dialog positioning, `@keyframes` for backdrop fade
- **Modal styles**: `@keyframes` for dialog enter/leave (slide-up on mobile, scale on desktop)
- **Drawer styles**: CSS `translate` transitions controlled by `data-enter-ready`/`data-entered`/`data-closing` attributes, `--utmr-drawer-width` CSS variable with responsive sizing

Drawer width presets: `:sm` (24rem), `:md` (28rem), `:lg` (42rem), `:xl` (56rem), `:full` (100vw minus gutter). Custom CSS strings also accepted.

### Phlex Compatibility
- `raw_html()` helper in `Base` handles both Phlex 1 (`raw`) and Phlex 2 (`unsafe_raw`)
- `Phlex::DeferredRenderWithMainContent` is a custom mixin (in `lib/phlex/`) that captures the block content and passes it to the template, enabling the `m.title { }` / `m.footer { }` DSL

### Turbo Helper Inclusion
Turbo helpers (`Turbo::FramesHelper`, `Turbo::StreamsHelper`, etc.) are included at the class level via `self.include_turbo_helpers` with a `@turbo_helpers_included` guard. This is called from `initialize` but only runs once per class.

### `method_missing` / `respond_to_missing?`
`Base` implements these to delegate to included modules. This is needed because Phlex components use a different method resolution order than typical Rails views.

### History Management
Uses a `data-turbo-modal-history-advanced` attribute on `<body>` to track whether `history.pushState` was called. The popstate listener resets the modal when the user navigates back. History advance is auto-disabled for drawers.

### Outside Click Handling
`dialogClicked` handles clicks on the dialog element itself (which is full-screen). It dismisses if the click is outside `contentTarget` and not on an element matching `allowedClickOutsideSelectorValue`.

### Turbo Frame Integration (index.js)
- `turbo:frame-missing` handler: When a response redirects and the target is a modal frame, it escapes the modal and performs a full Turbo visit
- `turbo:before-frame-render` handler: Uses Idiomorph with `morphstyle: 'innerHTML'` for modal frames, preventing flicker and re-triggering of enter transitions
- Event listeners are added with a preceding `removeEventListener` to prevent duplicates on hot reload

### Turbo Cache Handling
The `turbo:before-cache` event listener removes the dialog from Turbo's page cache to prevent stale state when navigating back.

## Testing

- **No automated test suite** — Ruby has no test files; JavaScript has no test framework
- **Manual testing** via the demo app at `./demo-app`
- The demo app exercises: modals, drawers (left/right), photo modals (no header/padding), long scrolling content, form submission with server-side close, advance history, focus trapping
