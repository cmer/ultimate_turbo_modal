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
      raise ArgumentError.new("Value must be a symbol.") unless flavor.is_a?(Symbol) || flavor.is_a?(String)
      @flavor = flavor.to_sym
    end

    def close_button=(close_button)
      raise ArgumentError.new("Value must be a boolean.") unless [true, false].include?(close_button)
      @close_button = close_button
    end

    def advance=(advance)
      raise ArgumentError.new("Value must be a boolean.") unless [true, false].include?(advance)
      @advance = advance
    end

    def padding=(padding)
      if [true, false].include?(padding) || padding.is_a?(String)
        @padding = padding
      else
        raise ArgumentError.new("Value must be a boolean or a String.")
      end
    end

    def header=(header)
      raise ArgumentError.new("Value must be a boolean.") unless [true, false].include?(header)
      @header = header
    end

    def header_divider=(header_divider)
      raise ArgumentError.new("Value must be a boolean.") unless [true, false].include?(header_divider)
      @header_divider = header_divider
    end

    def footer_divider=(footer_divider)
      raise ArgumentError.new("Value must be a boolean.") unless [true, false].include?(footer_divider)
      @footer_divider = footer_divider
    end

  end
end

# Make sure the configuration object is set up when the gem is loaded.
UltimateTurboModal.configure
