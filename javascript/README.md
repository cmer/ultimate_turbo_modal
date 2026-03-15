# Ultimate Turbo Modal for Rails (UTMR)

This is the JavaScript companion package for the [ultimate_turbo_modal](https://github.com/cmer/ultimate_turbo_modal) Ruby gem. It provides the Stimulus controller and Turbo integrations that power the modal behavior.

**You need the Ruby gem to use this package.** This npm package is not useful on its own.

## Installation

1. Add the Ruby gem to your Rails app:

   ```
   bundle add ultimate_turbo_modal
   ```

2. Run the install generator (this also sets up the npm package):

   ```
   bundle exec rails g ultimate_turbo_modal:install
   ```

For full documentation, configuration options, and usage examples, see the [GitHub repository](https://github.com/cmer/ultimate_turbo_modal).

## Features

- Smooth enter/leave animations
- Focus trapping for accessibility
- Scroll locking
- Browser history management (pushState)
- Click outside to dismiss
- Keyboard control (ESC to dismiss)
- Intelligent DOM morphing via Idiomorph (prevents flicker)
- Turbo Frame and Turbo Stream support

## License

MIT
