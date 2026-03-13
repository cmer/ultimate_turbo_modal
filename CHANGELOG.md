## [3.0.0] - Unreleased

- **BREAKING**: Removed Tailwind v3 flavor. Use the `tailwind` flavor (Tailwind v4+) or `custom` to define your own classes.
- Fixed popstate event listener leak when modal connects/disconnects multiple times
- Fixed `modal:closed` event now fires after leave transition completes (was firing before)
- Fixed duplicate click handler on outside modal clicks
- Fixed `content_div_data` no longer duplicated on both `#modal-inner` and `#modal-content`
- Added `method_missing` to complement existing `respond_to_missing?`
- Refactored boolean config setters into a declarative `boolean_option` macro
- Extracted `transition_data` helper to DRY up overlay/dialog transition attributes
- Centralized Phlex `unsafe_raw`/`raw` compat into `raw_html` helper
- Moved Turbo helper module inclusion to class-level for thread safety and performance
- Removed redundant `rails_root_join` override in update generator
- Simplified `detect_flavor` and stream action handler
- Switched from Yarn to npm for building and publishing the npm package

## [2.2.2] - 2026-03-12

- Added `close` function on Stimulus Controller. Thanks @bendangelo
- Focus bug fix. Thanks @pasl
- Refactor generator and fix [bug #33](https://github.com/cmer/ultimate_turbo_modal/issues/33).

## [2.2.1] - 2025-08-08

- Added `rails generate ultimate_turbo_modal:update` for easy updates
- Exclude demo-app directory from gem package

## [2.2.0] - 2025-08-07

- BREAKING: Make sure to re-run the generator `rails generate ultimate_turbo_modal:install` after install.
- Fixed transistions that were sometimes not showing
- Improved demo app to make it easier to use for development

## [2.1.2] - 2025-08-06

- Fixed scroll lock

## [2.1.1] - 2025-08-05

- Reduce Rails dependency to only required components (actionpack, activesupport, railties) (#22)
- Added focus trap (#27)

## [2.1.0] - 2025-08-05
- Borked!

## [2.0.4] - 2025-06-19

- Fix modal closing when clicked element is removed from DOM (#24)

## [2.0.3] - 2025-04-11

- Warn if the NPM package and Ruby Gem versions don't match.

## [2.0.1] - 2025-04-11

- Properly call `raw` for Phlex 2, and `unsafe_raw` for Phlex 1. Thanks @cavenk!

## [2.0.0] - 2025-04-07 - Breaking changes!

- Much simplified installation with a Rails generator
- Support for Turbo 8
- Support for Phlex 2
- Support for Tailwind v4 (use the `tailwind3` flavor if you're still on Tailwind v3)

## [1.7.0] - 2024-12-28

- Fix Phlex deprecation warning

## [1.6.1] - 2024-01-10

- Added ability to specify data attributes for the content div within the modal. Useful to specify a Stimulus controller, for example.

## [1.6.0] - 2023-12-25

- Support for Ruby 3.3

## [1.5.0] - 2023-11-28

- Allow whitelisting out-of-modal CSS selectors to not dismiss modal when clicked

## [1.4.1] - 2023-11-26

- Make Tailwind transition smoother on pages with multiple z-index

## [1.4.0] - 2023-11-23

- Added ability to specify custom `data-action` for the close button.
- Code cleanup, deduplication

## [1.3.1] - 2023-11-23

- Bug fixes

## [1.3.0] - 2023-11-14

- Added ability to pass in a `title` block.

## [1.2.1] - 2023-11-11

- Fix footer divider not showing

## [1.2.0] - 2023-11-05

- Dark mode support
- Added header divider (configurable)
- Added footer section with divider (configurable)
- Tailwind flavor now uses data attributes to style elements
- Updated look and feel
- Simplified code a bit

## [1.1.3] - 2023-11-01

- Added configuration block

## [1.1.2] - 2023-10-31

- Bug fix

## [1.1.0] - 2023-10-31

- Added Vanilla CSS!

## [1.0.0] - 2023-10-31

- Initial release as a Ruby Gem
