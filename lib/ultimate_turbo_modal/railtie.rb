require "rails"
require "rails/railtie"
require "phlex-rails"
require "turbo-rails"
require "ultimate_turbo_modal/helpers/controller_helper"
require "ultimate_turbo_modal/helpers/view_helper"
require "ultimate_turbo_modal/helpers/stream_helper"

module UltimateTurboModal
  class Railtie < Rails::Railtie
    # Absolute path to the stylesheets shipped with the gem. Exposed so that
    # apps and tooling can locate `ultimate_turbo_modal.css` without guessing.
    def self.stylesheets_path
      File.expand_path("../../app/assets/stylesheets", __dir__)
    end

    # Make `ultimate_turbo_modal.css` available to the asset pipeline so that
    # `stylesheet_link_tag "ultimate_turbo_modal"` works under Propshaft and
    # Sprockets alike, regardless of whether the app uses importmaps or a
    # JavaScript bundler.
    initializer "ultimate_turbo_modal.assets" do |app|
      next unless app.config.respond_to?(:assets)
      next unless app.config.assets.respond_to?(:paths)

      app.config.assets.paths << UltimateTurboModal::Railtie.stylesheets_path

      # Sprockets only precompiles what it is told about; Propshaft compiles
      # everything on its load path and ignores this list.
      if defined?(Sprockets) && app.config.assets.respond_to?(:precompile)
        app.config.assets.precompile << "ultimate_turbo_modal.css"
      end
    end

    initializer "ultimate_turbo_modal.action_controller" do
      ActiveSupport.on_load(:action_controller_base) do
        include UltimateTurboModal::Helpers::ControllerHelper
      end
    end

    initializer "ultimate_turbo_modal.action_view" do
      ActiveSupport.on_load(:action_view) do
        include UltimateTurboModal::Helpers::ViewHelper
      end
      Turbo::Streams::TagBuilder.include(UltimateTurboModal::Helpers::StreamHelper)
    end
  end
end
