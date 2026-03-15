  # Upgrading a Ruby on Rails application from Ultimate Turbo Modal (UTMR) version 2 to version 3.

  ## Minimum requirements

  - Ruby 3.2 and above.
  - Rails 7 and above.
  - If the application uses Tailwind CSS, version 4 is now required. Tailwind 3 is deprecated. (breaking change)
  - `ultimate_turbo_modal` should be present in the host application's Gemfile. Otherwise, it hasn't been installed yet. User should follow installation steps instead.

  ## Important notes

  - Before starting with the upgrade, run `bundle exec rails runner "puts UltimateTurboModal.flavor"` to detect which flavor the host application is using. `tailwind3` is now deprecated. If the host application is using `tailwind3`, inform the user that it is no longer supported, and that the host application should upgrade to TailwindCSS 4 first.
  - If the flavor is different from the built-in `tailwind` or `vanilla`, they should be informed that they will need to reapply their custom styling changes manually since the HTML markup for UTMR has changed significantly.
  - If the application is using the `tailwind` or `vanilla`, no manual styling changes are required. The upgrade will be seamless.

  ## Steps to follow

  1. Change the version number for `ultimate_turbo_modal` in Gemfile to `~> 3.0`.
  2. If the application uses a Javascript package manager (npm, yarn, bun), change the version number for `ultimate_turbo_modal` in package.json to `^3.0.0`. Otherwise, if the application uses importmaps, update the `pin "ultimate_turbo_modal"` entry in `config/importmap.rb` to reference version `^3.0.0` (or run `bin/importmap pin ultimate_turbo_modal@^3.0.0`).
  3. Run `bundle install`.
  4. Run `bundle exec rails generate ultimate_turbo_modal:update` to align the npm package version with the Rubygem, and to copy the flavor file over. Note: this copies the flavor file (e.g. `config/initializers/ultimate_turbo_modal_tailwind.rb`) which defines CSS classes. It does **not** modify the configuration initializer (`config/initializers/ultimate_turbo_modal.rb`) which contains the `UltimateTurboModal.configure` block — that file must be migrated manually in step 6.
  5. Run `yarn install` or `npm install` or `bun install` if using a Javascript package manager.
  6. Migrate the configuration block in `config/initializers/ultimate_turbo_modal.rb` (this is the file with the `UltimateTurboModal.configure` block, not the flavor file). If this file does not exist, skip this step — the user was using defaults and no migration is needed. The objective is to replicate the same behavior the user had in v2, using the new v3 syntax. To do this:

    a. Read the user's existing `config/initializers/ultimate_turbo_modal.rb` and note any options that differ from the v3 defaults. The v3 modal defaults are: `advance: true`, `close_button: true`, `header: true`, `header_divider: true`, `footer_divider: true`, `padding: true`, `overlay: true`. If all the user's v2 options match these defaults, overwrite the file with just the template (step b) and skip to step d.

    b. Retrieve the v3 configuration template by running: `cat $(bundle info ultimate_turbo_modal --path)/lib/generators/ultimate_turbo_modal/templates/ultimate_turbo_modal.rb`. This template contains the new v3 format with all options commented out at their defaults. Note: the template contains a `FLAVOR` placeholder on the `config.flavor` line — replace it with the flavor symbol from the user's v2 file (e.g. `:tailwind`).

    c. Use the template as the base for the new file. Uncomment and set only the options that differ from the v3 defaults. The mapping is:
      - `config.flavor` and `config.allowed_click_outside_selector` remain top-level (unchanged).
      - `config.advance` → `m.advance` inside `config.modal` block (advance only applies to modals, not drawers).
      - `config.close_button`, `config.header`, `config.header_divider`, `config.footer_divider`, `config.padding` → `m.<option>` inside `config.modal` block.
      - Leave the `config.drawer` block commented out (use defaults) since drawers is a new feature and was never previously configured.
      - Setting old-style flat options directly on `config` (e.g. `config.close_button = false`) will raise a `NoMethodError` in v3.

    d. Overwrite `config/initializers/ultimate_turbo_modal.rb` with the result.

  7. Instruct the user to restart their Rails application server for the changes to be picked up.
