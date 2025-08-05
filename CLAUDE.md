# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Ultimate Turbo Modal (UTMR) is a full-featured modal implementation for Rails applications using Turbo, Stimulus, and Hotwire. It consists of both a Ruby gem and an npm package that work together.

## Project Structure

- **Ruby Gem**: Main gem code in `/lib/ultimate_turbo_modal/`
  - `base.rb`: Core modal component (Phlex-based)
  - `configuration.rb`: Global configuration management
  - `helpers/`: Rails helpers for views and controllers
  - Generators in `/lib/generators/` for installation
  
- **JavaScript Package**: Located in `/javascript/`
  - `modal_controller.js`: Stimulus controller for modal behavior
  - `index.js`: Main entry point
  - Distributed files built to `/javascript/dist/`

## Common Development Commands

### JavaScript Development (run from `/javascript/` directory)
```bash
# Install dependencies
yarn install

# Build the JavaScript package
yarn build

# Release to npm (updates version and publishes)
yarn release
```

### Ruby Gem Development (run from root)
```bash
# Run tests
bundle exec rake test

# Build gem
gem build ultimate_turbo_modal.gemspec

# Release process (Ruby + JS)
./script/build_and_release.sh
```

## Architecture & Key Concepts

### Modal Options System
Options can be set at three levels:
1. **Global defaults** via `UltimateTurboModal.configure` in configuration.rb
2. **Instance options** passed to the `modal` helper
3. **Runtime values** via blocks (for title/footer)

Current options: `advance`, `close_button`, `header`, `header_divider`, `padding`, `title`, `focus_trap` (to be added)

### Stimulus Controller Values
The modal controller uses Stimulus values to receive configuration:
- `advanceUrl`: URL for browser history manipulation
- `allowedClickOutsideSelector`: CSS selectors that won't dismiss modal when clicked

### Modal Lifecycle
1. Link clicked with `data-turbo-frame="modal"`
2. Turbo loads content into the modal frame
3. Stimulus controller connects and shows modal
4. Modal can be dismissed via: ESC key, close button, clicking outside, or programmatically

### Adding New Configuration Options
When adding a new option (like `focus_trap`):
1. Add to `Configuration` class with getter/setter methods
2. Add to `UltimateTurboModal` delegators
3. Add to `Base#initialize` parameters with default from configuration
4. Pass to JavaScript via data attributes in `Base#div_dialog`
5. Add as Stimulus value in `modal_controller.js`
6. Update README.md options table

## Testing Approach
- JavaScript: No test framework currently set up
- Ruby: Use standard Rails testing practices
- Manual testing via the demo app: https://github.com/cmer/ultimate_turbo_modal-demo