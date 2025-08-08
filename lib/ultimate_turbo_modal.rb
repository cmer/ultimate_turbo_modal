# frozen_string_literal: true

require_relative "ultimate_turbo_modal/version"
require "phlex/deferred_render_with_main_content"
require "ultimate_turbo_modal/configuration"
require "ultimate_turbo_modal/railtie"
require "ultimate_turbo_modal/base"
require "generators/ultimate_turbo_modal/base"
require "generators/ultimate_turbo_modal/install_generator"
require "generators/ultimate_turbo_modal/update_generator"

module UltimateTurboModal
  extend self

  def new(**)
    modal_class.new(**)
  end

  def modal_class
    "UltimateTurboModal::Flavors::#{flavor.to_s.classify}".constantize
  rescue NameError
    raise Error, "Flavor `#{flavor.downcase}` not found. Please check your initializer file at `config/initializers/ultimate_turbo_modal.rb` and make sure to run `rails generate ultimate_turbo_modal:install`."
  end

  class Error < StandardError; end
end
