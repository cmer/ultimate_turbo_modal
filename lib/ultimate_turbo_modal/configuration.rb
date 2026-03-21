# frozen_string_literal: true

module UltimateTurboModal
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  delegate :flavor, :flavor=,
    :allowed_click_outside_selector, :allowed_click_outside_selector=, to: :configuration

  class Configuration
    attr_reader :flavor, :modal_config, :drawer_config
    attr_accessor :allowed_click_outside_selector

    def initialize
      @flavor = :tailwind
      @allowed_click_outside_selector = []
      @modal_config = ModalConfig.new
      @drawer_config = DrawerConfig.new
    end

    def modal
      yield(@modal_config) if block_given?
      @modal_config
    end

    def drawer
      yield(@drawer_config) if block_given?
      @drawer_config
    end

    def flavor=(flavor)
      raise ArgumentError, "Value must be a symbol." unless flavor.is_a?(Symbol) || flavor.is_a?(String)
      @flavor = flavor.to_sym
    end

    # Shared base for modal and drawer configuration
    class BaseConfig
      attr_reader :close_button, :header, :header_divider, :footer_divider, :padding, :overlay

      def self.boolean_option(name)
        define_method(:"#{name}=") do |value|
          raise ArgumentError, "Value must be a boolean." unless [true, false].include?(value)
          instance_variable_set(:"@#{name}", value)
        end
      end

      boolean_option :close_button
      boolean_option :header
      boolean_option :header_divider
      boolean_option :footer_divider
      boolean_option :overlay

      def padding=(padding)
        if [true, false].include?(padding) || padding.is_a?(String)
          @padding = padding
        else
          raise ArgumentError, "Value must be a boolean or a String."
        end
      end
    end

    class ModalConfig < BaseConfig
      attr_reader :advance

      def initialize
        @advance = false
        @close_button = true
        @header = true
        @header_divider = true
        @footer_divider = true
        @padding = true
        @overlay = true
      end

      boolean_option :advance
    end

    class DrawerConfig < BaseConfig
      attr_reader :size, :position

      def initialize
        @close_button = true
        @header = true
        @header_divider = false
        @footer_divider = true
        @padding = true
        @overlay = true
        @size = :md
        @position = :right
      end

      def size=(value)
        @size = UltimateTurboModal::Base.validate_drawer_size!(value)
      end

      def position=(value)
        @position = UltimateTurboModal::Base.validate_drawer_position!(value)
      end
    end
  end
end

# Make sure the configuration object is set up when the gem is loaded.
UltimateTurboModal.configure
