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
