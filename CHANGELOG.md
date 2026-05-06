## [Unreleased]

- Fixed drawers closing abruptly when pressing Escape after dismissing a modal opened from inside the drawer.
- Links and forms inside a drawer can now use `data-turbo-frame="modal"` to open a stacked modal — the same partial works inside or outside a drawer with no changes.
- Fixed scroll-lock not releasing after a same-page morph reconnected the modal controller, which could leave the page padded and right-anchored fixed elements offset until refresh.

## [3.1.2] - 2026-05-01

- Fixed page content shifting right when a modal or drawer opens.

## [3.1.1] - 2026-05-01

- Fixed validation errors and multi-step forms inside a stacked modal closing the modal instead of updating in place.

## [3.1.0] - 2026-05-01

- Tweaked vertically centering of modals on desktop (≥640px) with a slight optical-center bias, instead of anchoring them near the top.
- Added support for opening a modal from inside a drawer. See [docs/modal-from-drawer.md](docs/modal-from-drawer.md).
- Fixed a race in `closeAllDialogs` when a stacked modal redirected off-page, which could leave a dialog open or animations in a bad state.

## [3.0.5] - 2026-04-22

- Fixed modal being dismissed when a body-appended widget (e.g. flatpickr, Select2, Tippy) opens over its trigger between mousedown and mouseup. The browser fires `click` on the dialog (common ancestor), which was treated as a backdrop dismissal. The dialog now tracks mousedown origin and skips dismissal when the press started inside content.

## [3.0.4] - 2026-04-08

- Fixed form fields not being auto-focused inside modals due to an unnecessary `invisible` class on the modal inner container.

## [3.0.3] - 2026-03-23

- Switched importmap CDN from JSPM to jsdelivr for more reliable package resolution.

## [3.0.2] - 2026-03-22

- Fixed npm package not being found on JSPM, which prevented `bin/importmap pin` from working ([#46](https://github.com/cmer/ultimate_turbo_modal/issues/46)).

## [3.0.1] - 2026-03-21

- Fixed missing bottom padding on vanilla flavor drawer header when header divider is enabled.

## [3.0.0] - 2026-03-21

Upgrading is easy! See [UPGRADING.md](UPGRADING.md)

- **BREAKING**: Replaced div-based modal with native HTML `<dialog>` element. 
- **BREAKING**: If you customized the look and feel of a flavor, you'll need to reapply your customizations since the underlying markup has changed.
- **BREAKING**: Removed Tailwind v3 flavor. Use the `tailwind` flavor (Tailwind v4+) or `custom` to define your own classes.
- **BREAKING**: Configuration options are now split between `config.modal` and `config.drawer` blocks instead of flat on the config object. See UPGRADING.md for migration details.
- **BREAKING**: Rails 8+ now required.
- Added support for slide-out drawers with separate default configuration.
- Smooth redirect behavior: same-page redirects morph content behind modal/drawer before closing; different-page redirects close modal/drawer with animation before navigating.
- Removed `el-transition` and `focus-trap` npm dependencies.
- ... plus a million tweaks, optimizations, refactors, etc.

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
