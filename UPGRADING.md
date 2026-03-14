# Upgrading

## Updating between minor versions

To upgrade within the same major version (for example 3.0 → 3.1):

1. Change the UTMR gem version in your `Gemfile`:

   ```ruby
   gem "ultimate_turbo_modal", "~> 3.0"
   ```

2. Install updated dependencies:

   ```sh
   bundle install
   ```

3. Run the update generator:

   ```sh
   bundle exec rails g ultimate_turbo_modal:update
   ```

## Upgrading from 2.x to 3.0

v3.0 includes a few breaking changes:

- **Native `<dialog>` element**: The modal now uses the native HTML `<dialog>` element instead of custom `<div>`-based markup. This provides native focus trapping and improved accessibility, removing the need for the `el-transition` and `focus-trap` JavaScript dependencies.
- **Simplified HTML structure**: The modal markup has been reduced from 6 nested containers to 3 (`dialog` + `inner` + `content`).
- **Tailwind v3 flavor removed**: Only Tailwind v4+ is supported via the `tailwind` flavor. Use `custom` if you need to define your own classes.
- **Custom flavor update required**: The flavor constants `DIV_MODAL_CONTAINER_CLASSES`, `DIV_OVERLAY_CLASSES`, `DIV_DIALOG_CLASSES`, and `TRANSITIONS` have been replaced by `DIALOG_CLASSES`. If you have a custom flavor, you must update it to use the new constants.
- **Configuration restructured**: Configuration options are now split between `config.modal` and `config.drawer` blocks instead of being flat on the config object. This allows modals and drawers to have different defaults (e.g., `header_divider` defaults to `true` for modals but `false` for drawers). See below for migration details.

### Configuration migration

The old flat configuration:

```ruby
UltimateTurboModal.configure do |config|
  config.flavor = :tailwind
  config.advance = true
  config.close_button = true
  config.header = true
  config.header_divider = true
  config.footer_divider = true
  config.padding = true
  config.overlay = true
  config.drawer_size = :md
  config.allowed_click_outside_selector = []
end
```

Should be updated to:

```ruby
UltimateTurboModal.configure do |config|
  config.flavor = :tailwind
  config.allowed_click_outside_selector = []

  config.modal do |m|
    m.advance = true
    m.close_button = true
    m.header = true
    m.header_divider = true
    m.footer_divider = true
    m.padding = true
    m.overlay = true
  end

  config.drawer do |d|
    d.position = :right
    d.close_button = true
    d.header = true
    d.header_divider = false
    d.footer_divider = true
    d.padding = true
    d.overlay = true
    d.size = :md
  end
end
```

Global options (`flavor`, `allowed_click_outside_selector`) remain on the top-level config. All other options are now set within `config.modal` or `config.drawer` blocks. The defaults shown above are the built-in defaults, so you only need to set the options you want to change.

But upgrading is easy! To upgrade:

1. Update your `Gemfile`:

   ```ruby
   gem "ultimate_turbo_modal", "~> 3.0"
   ```

2. Install updated dependencies:

   ```sh
   bundle install
   ```

3. Re-run the install generator to get the updated flavor file and JavaScript package:

   ```sh
   bundle exec rails g ultimate_turbo_modal:install
   ```


## Upgrading from 1.x to 2.x (LEGACY VERSIONS)

Version 2.0 of Ultimate Turbo Modal introduced some significant changes to simplify the setup and usage. Follow these steps to upgrade from a 1.x version.

### 1. Gem and Package Update

1.  Update the gem in your `Gemfile`:
    ```ruby
    gem 'ultimate_turbo_modal', '~> 2.0'
    ```
2.  Update the npm package in your `package.json`:
    ```json
    "ultimate-turbo-modal": "^2.0"
    ```
3.  Run `bundle install` and `yarn install` (or `npm install`).

### 2. JavaScript Changes

The biggest change in v2 was the removal of the `setupUltimateTurboModal` initializer. The modal controller now handles everything automatically.

#### Remove Initializer

- Remove the two `setupUltimateTurboModal`-related lines from `app/javascript/controllers/index.js`.

Your `index.js` should no longer import `setupUltimateTurboModal` or call it. The Stimulus controller will be automatically loaded.

#### Remove Idiomorph Tweaks (if you used them)

If you were using the optional Idiomorph tweaks for better morphing, you can remove them as this is now handled differently.

- Remove `<script src="https://unpkg.com/idiomorph"></script>` from your application layout.
- Remove the `turbo:before-frame-render` event listener from your `application.js`.

### 3. Tailwind CSS Changes

- Remove any `ultimate_turbo_modal` specific paths from your `tailwind.config.js`. The modal's classes are now self-contained and don't require scanning the gem's view files.

A typical `tailwind.config.js` in a Rails app should have its `content` array look something like this, without mentioning the gem:

```js
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ]
}
```
