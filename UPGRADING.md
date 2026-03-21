# Upgrading

## Upgrading from 2.x to 3.0

**Tell your favorite LLM agent to upgrade UTMR for you!** Use this prompt:

```
Retrieve and follow the instructions at https://raw.githubusercontent.com/cmer/ultimate_turbo_modal/main/LLM/UPGRADE-TO-VERSION-3.md to upgrade this application's "Ultimate Turbo Modal" dependency from v2 to v3. 
```

v3.0 includes a few breaking changes. See [CHANGELOG.md](CHANGELOG.md) for a complete list of changes.

- **Native `<dialog>` element**: The modal now uses the native HTML `<dialog>` element instead of custom `<div>`-based markup. This provides native focus trapping and improved accessibility, removing the need for the `el-transition` and `focus-trap` JavaScript dependencies.
- **Simplified HTML structure**: The modal markup has been reduced from 6 nested containers to 3 (`dialog` + `inner` + `content`).
- **Tailwind v3 flavor removed**: Only Tailwind v4+ is supported via the `tailwind` flavor. Use `custom` if you need to define your own classes.
- **Custom flavor update required**: The flavor constants `DIV_MODAL_CONTAINER_CLASSES`, `DIV_OVERLAY_CLASSES`, `DIV_DIALOG_CLASSES`, and `TRANSITIONS` have been replaced by `DIALOG_CLASSES`. If you have a custom flavor, you must update it to use the new constants.
- **Configuration restructured**: Configuration options are now split between `config.modal` and `config.drawer` blocks instead of being flat on the config object. This allows modals and drawers to have different defaults.

### Upgrading like a cavemen

If you're old school and prefer to upgrade manually, without an LLM, it's pretty easy. Just follow the instructions at [LLM/UPGRADE-TO-VERSION-3.md](LLM/UPGRADE-TO-VERSION-3.md).


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
