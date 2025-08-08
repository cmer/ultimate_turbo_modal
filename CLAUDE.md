# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Ultimate Turbo Modal (UTMR) is a full-featured modal implementation for Rails applications using Turbo, Stimulus, and Hotwire. It consists of both a Ruby gem and an npm package that work together to provide seamless modal functionality with proper focus management, history manipulation, and customizable styling.

## Architecture

### High-Level Design

The system follows a separation of concerns between server-side rendering (Ruby/Rails) and client-side behavior (JavaScript/Stimulus):

1. **Server-Side (Ruby Gem)**: Handles HTML generation, configuration management, and Rails integration
2. **Client-Side (JavaScript Package)**: Manages modal behavior, focus trapping, scroll locking, and Turbo interactions
3. **Communication Layer**: Uses Turbo Frames, Turbo Streams, and data attributes to coordinate between server and client

### Core Components

#### Ruby Gem Architecture

- **Module Structure**: `UltimateTurboModal` is the main module that delegates to configuration and instantiates modal classes
- **Base Class**: `UltimateTurboModal::Base` extends `Phlex::HTML` for component-based HTML generation
- **Configuration System**: Centralized configuration with validation and type checking
- **Flavor System**: CSS framework-specific implementations (Tailwind, Vanilla, Custom) that define styling classes
- **Rails Integration**: Via Railtie that injects helpers into ActionController and ActionView

#### JavaScript Architecture

- **Stimulus Controller**: `modal_controller.js` handles all modal interactions
- **Dependencies**:
  - `el-transition`: For smooth enter/leave animations
  - `focus-trap`: For accessibility-compliant focus management
  - `idiomorph`: For intelligent DOM morphing to prevent flicker
- **Global Registration**: Modal instance exposed as `window.modal` for programmatic access
- **Turbo Integration**: Custom stream actions and frame handling

## Detailed Implementation

### Ruby Components

#### `UltimateTurboModal` Module (`lib/ultimate_turbo_modal.rb`)
- Entry point for the gem
- Factory method `new` creates modal instances
- `modal_class` method dynamically loads flavor classes based on configuration
- Extends self for module-level methods

#### `Base` Class (`lib/ultimate_turbo_modal/base.rb`)
- **Inheritance**: `Phlex::HTML` for HTML generation with Ruby DSL
- **Mixins**:
  - `Phlex::DeferredRenderWithMainContent` for content block handling
  - Dynamic inclusion of Turbo helpers (FramesHelper, StreamsHelper)
- **Key Methods**:
  - `initialize`: Accepts configuration options with defaults from global config
  - `view_template`: Main rendering method that wraps content in appropriate Turbo tags
  - `modal`: Orchestrates HTML structure generation
  - `div_*` methods: Generate specific HTML elements with proper classes and attributes
- **Data Attributes**: Passes configuration to JavaScript via data attributes on the container div

#### `Configuration` Class (`lib/ultimate_turbo_modal/configuration.rb`)
- **Options with Validation**:
  - `flavor`: Symbol/String for CSS framework (default: `:tailwind`)
  - `close_button`: Boolean for showing close button
  - `advance`: Boolean for browser history manipulation
  - `padding`: Boolean or String for content padding
  - `header`, `header_divider`, `footer_divider`: Boolean display options
  - `allowed_click_outside_selector`: Array of CSS selectors that won't dismiss modal
- **Type Safety**: Each setter validates input types and raises `ArgumentError` on invalid values

#### Rails Helpers

##### `ViewHelper` (`helpers/view_helper.rb`)
- `modal` method: Renders modal component with current request context
- Instantiates `UltimateTurboModal` with passed options

##### `ControllerHelper` (`helpers/controller_helper.rb`)
- `inside_modal?` method: Detects if request is within modal context
- Uses `Turbo-Frame` header to determine modal context
- Exposed as helper method to views

##### `StreamHelper` (`helpers/stream_helper.rb`)
- `modal` method: Generates Turbo Stream actions for modal control
- Supports `:close` and `:hide` messages
- Creates custom `modal` stream action with message attribute

#### Flavor System
- Located in generator templates (`lib/generators/ultimate_turbo_modal/templates/flavors/`)
- Each flavor defines CSS class constants for modal elements:
  - `DIV_DIALOG_CLASSES`, `DIV_OVERLAY_CLASSES`, `DIV_OUTER_CLASSES`, etc.
- Flavors inherit from `Base` and override class constants
- Supports Tailwind (v3 and v4), Vanilla CSS, and Custom implementations

### JavaScript Components

#### Modal Controller (`javascript/modal_controller.js`)

##### Stimulus Configuration
- **Targets**: `container`, `content`
- **Values**: `advanceUrl`, `allowedClickOutsideSelector`
- **Actions**: Responds to keyboard, click, and Turbo events

##### Lifecycle Methods
- **`connect()`**:
  - Initializes focus trap and scroll lock variables
  - Shows modal immediately
  - Sets up popstate listener for browser back button
  - Exposes controller as `window.modal`
- **`disconnect()`**: Cleans up focus trap and global reference

##### Core Functionality

###### Modal Display
- **`showModal()`**:
  - Locks body scroll
  - Triggers enter transition
  - Activates focus trap after transition
  - Pushes history state if `advance` is enabled
- **`hideModal()`**:
  - Prevents double-hiding with `hidingModal` flag
  - Dispatches cancelable `modal:closing` event
  - Deactivates focus trap
  - Triggers leave transition
  - Cleans up DOM and history
  - Dispatches `modal:closed` event

###### Focus Management (`#activateFocusTrap()`, `#deactivateFocusTrap()`)
- Creates focus trap with sensible defaults
- Finds first focusable element or focuses modal itself
- Handles errors gracefully without breaking modal
- Respects modal's own keyboard/click handlers

###### Scroll Locking (`#lockBodyScroll()`, `#unlockBodyScroll()`)
- Stores current scroll position
- Sets body to `position: fixed` to prevent scroll
- Restores original overflow and scroll position on unlock
- Prevents layout shift during modal display

###### History Management
- Uses data attribute on body to track history state
- `#hasHistoryAdvanced()`, `#setHistoryAdvanced()`, `#resetHistoryAdvanced()`
- Coordinates with browser back button via popstate listener

###### Event Handlers
- **`submitEnd()`**: Closes modal on successful form submission
- **`closeWithKeyboard()`**: ESC key handler
- **`outsideModalClicked()`**: Dismisses modal on outside clicks unless allowed selector matches

###### Version Checking
- `#checkVersions()`: Warns about gem/npm version mismatches in development
- Helps developers keep packages in sync

#### Main Package Entry (`javascript/index.js`)

##### Turbo Stream Actions
- Registers custom `modal` stream action
- Handles `hide` and `close` messages via `window.modal` reference

##### Turbo Frame Integration
- **`handleTurboFrameMissing`**: Escapes modal on redirects
- **`handleTurboBeforeFrameRender`**: Uses Idiomorph for intelligent morphing
  - Prevents flicker and unwanted animations
  - Morphs only innerHTML to preserve modal container

### Modal Lifecycle Flow

1. **Trigger**: Link/form targets `data-turbo-frame="modal"`
2. **Request**: Rails controller renders modal content
3. **Response**:
   - If Turbo Frame request: Wrapped in `<turbo-frame id="modal">`
   - If Turbo Stream: Wrapped in stream action targeting modal
4. **Client Processing**:
   - Turbo updates modal frame content
   - Stimulus controller connects and shows modal
   - Focus trap activates, scroll locks
   - History state pushed (if enabled)
5. **Interaction**:
   - User interacts with modal content
   - Form submissions handled via Turbo
   - ESC key, close button, or outside clicks trigger hiding
6. **Dismissal**:
   - `modal:closing` event fired (cancelable)
   - Focus trap deactivates
   - Leave transition plays
   - DOM cleaned up
   - History restored
   - `modal:closed` event fired

## Project Structure

- **Ruby Gem**: Main gem code in `/lib/ultimate_turbo_modal/`
  - `base.rb`: Core modal component (Phlex-based)
  - `configuration.rb`: Global configuration management
  - `helpers/`: Rails helpers for views and controllers
  - `railtie.rb`: Rails integration setup
  - Generators in `/lib/generators/` for installation

- **JavaScript Package**: Located in `/javascript/`
  - `modal_controller.js`: Stimulus controller for modal behavior
  - `index.js`: Main entry point with Turbo integration
  - `styles/`: CSS files for vanilla styling
  - Distributed files built to `/javascript/dist/`

- **Demo Application**: Located in `/demo-app/`
  - `Procfile.dev`: Development process file for overmind/foreman
  - `bin/dev`: Development script for starting the demo app

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

Current options: `advance`, `close_button`, `header`, `header_divider`, `padding`, `title`

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
When adding a new option:

1. Add to `Configuration` class with getter/setter methods
2. Add to `UltimateTurboModal` delegators
3. Add to `Base#initialize` parameters with default from configuration
4. Pass to JavaScript via data attributes in `Base#div_dialog`
5. Add as Stimulus value in `modal_controller.js`
6. Update README.md options table

## Testing Approach
- JavaScript: No test framework currently set up
- Ruby: Use standard Rails testing practices
- Manual testing via the demo app (located in `./demo-app`)
