# frozen_string_literal: true

module UltimateTurboModal
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  delegate :flavor, :flavor=, :close_button, :close_button=,
    :advance, :advance=, :padding, :padding=,
    :allowed_click_outside_selector, :allowed_click_outside_selector=, to: :configuration

  class Configuration
    attr_reader :flavor, :close_button, :advance, :padding, :header, :header_divider, :footer_divider
    attr_accessor :allowed_click_outside_selector

    def self.boolean_option(name)
      define_method(:"#{name}=") do |value|
        raise ArgumentError, "Value must be a boolean." unless [true, false].include?(value)
        instance_variable_set(:"@#{name}", value)
      end
    end

    boolean_option :close_button
    boolean_option :advance
    boolean_option :header
    boolean_option :header_divider
    boolean_option :footer_divider

    def initialize
      @flavor = :tailwind
      @close_button = true
      @advance = true
      @padding = true
      @header = true
      @header_divider = true
      @footer_divider = true
      @allowed_click_outside_selector = []
    end

    def flavor=(flavor)
      raise ArgumentError, "Value must be a symbol." unless flavor.is_a?(Symbol) || flavor.is_a?(String)
      @flavor = flavor.to_sym
    end

    def padding=(padding)
      if [true, false].include?(padding) || padding.is_a?(String)
        @padding = padding
      else
        raise ArgumentError, "Value must be a boolean or a String."
      end
    end
  end
end

# Make sure the configuration object is set up when the gem is loaded.
UltimateTurboModal.configure
