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
    attr_reader :flavor, :modal_config, :drawer_config, :confirm_config
    attr_accessor :allowed_click_outside_selector

    def initialize
      @flavor = :tailwind
      @allowed_click_outside_selector = []
      @modal_config = ModalConfig.new
      @drawer_config = DrawerConfig.new
      @confirm_config = ConfirmConfig.new
    end

    def modal
      yield(@modal_config) if block_given?
      @modal_config
    end

    def drawer
      yield(@drawer_config) if block_given?
      @drawer_config
    end

    def confirm
      yield(@confirm_config) if block_given?
      @confirm_config
    end

    def flavor=(flavor)
      raise ArgumentError, "Value must be a symbol." unless flavor.is_a?(Symbol) || flavor.is_a?(String)
      @flavor = flavor.to_sym
    end

    # Shared base for modal and drawer configuration
    class BaseConfig
      attr_reader :advance, :close_button, :close_on_submit, :header, :header_divider, :footer_divider, :padding, :overlay

      def self.boolean_option(name)
        define_method(:"#{name}=") do |value|
          raise ArgumentError, "Value must be a boolean." unless [true, false].include?(value)
          instance_variable_set(:"@#{name}", value)
        end
      end

      boolean_option :close_button
      boolean_option :close_on_submit
      boolean_option :header
      boolean_option :header_divider
      boolean_option :footer_divider
      boolean_option :overlay

      def advance=(value)
        if [true, false].include?(value) || value.is_a?(String)
          @advance = value
        else
          raise ArgumentError, "Value must be a boolean or a String."
        end
      end

      def padding=(padding)
        if [true, false].include?(padding) || padding.is_a?(String)
          @padding = padding
        else
          raise ArgumentError, "Value must be a boolean or a String."
        end
      end
    end

    class ModalConfig < BaseConfig
      def initialize
        @advance = false
        @close_button = true
        @close_on_submit = true
        @header = true
        @header_divider = true
        @footer_divider = true
        @padding = true
        @overlay = true
      end
    end

    # Defaults for the Turbo Confirm dialog. Every value here is a fallback:
    # anything supplied per-element through `data-turbo-confirm` wins.
    class ConfirmConfig < BaseConfig
      attr_accessor :title, :accept_label, :cancel_label
      attr_reader :enabled

      boolean_option :enabled

      # `advance` and `close_on_submit` are left unset: a confirm never pushes a
      # URL and holds no form, and the dialog binds neither behavior.
      def initialize
        @enabled = true
        # A confirm has its own Cancel button, and dividers chop up what is
        # only ever a line or two of text.
        @close_button = false
        @header = true
        @header_divider = false
        @footer_divider = false
        @padding = true
        @overlay = true
        @title = "Are you sure?"
        @accept_label = "OK"
        @cancel_label = "Cancel"
      end
    end

    class DrawerConfig < BaseConfig
      attr_reader :size, :position

      def initialize
        @advance = false
        @close_button = true
        @close_on_submit = true
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
