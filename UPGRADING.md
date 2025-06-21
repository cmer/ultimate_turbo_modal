# Upgrading from 1.x to 2.x

Version 2.0 of Ultimate Turbo Modal introduces some significant changes to simplify the setup and usage. Follow these steps to upgrade from a 1.x version.

## 1. Gem and Package Update

1.  Update the gem in your `Gemfile`:
    ```ruby
    gem 'ultimate_turbo_modal', '~> 2.0'
    ```
2.  Update the npm package in your `package.json`:
    ```json
    "ultimate-turbo-modal": "^2.0"
    ```
3.  Run `bundle install` and `yarn install` (or `npm install`).

## 2. JavaScript Changes

The biggest change in v2 is the removal of the `setupUltimateTurboModal` initializer. The modal controller now handles everything automatically.

### Remove Initializer

- Remove the two `setupUltimateTurboModal`-related lines from `app/javascript/controllers/index.js`.

Your `index.js` should no longer import `setupUltimateTurboModal` or call it. The Stimulus controller will be automatically loaded.

### Remove Idiomorph Tweaks (if you used them)

If you were using the optional Idiomorph tweaks for better morphing, you can remove them as this is now handled differently.

- Remove `<script src="https://unpkg.com/idiomorph"></script>` from your application layout.
- Remove the `turbo:before-frame-render` event listener from your `application.js`.

## 3. Tailwind CSS Changes

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

## 4. Review Usage

Version 2.0 aims for backward compatibility in how you render modals from your Rails views and controllers. However, it's always a good idea to test your modals after upgrading to ensure they behave as expected.

That's it! You should now be running on version 2.0.
