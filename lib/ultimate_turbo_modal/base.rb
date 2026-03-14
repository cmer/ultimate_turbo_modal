# frozen_string_literal: true

class UltimateTurboModal::Base < Phlex::HTML
  prepend Phlex::DeferredRenderWithMainContent
  # @param advance [Boolean, String] Whether to update the browser history when opening and closing the modal (modal-only, ignored for drawers)
  # @param allowed_click_outside_selector [String] CSS selectors for elements that are allowed to be clicked outside of the modal without dismissing the modal
  # @param close_button [Boolean] Whether to show a close button
  # @param close_button_data_action [String] `data-action` attribute for the close button
  # @param close_button_sr_label [String] Close button label for screen readers
  # @param _drawer_position [Symbol, false] Internal: drawer position (:right, :left) or false for standard modal. Use the `drawer()` view helper instead.
  # @param footer_divider [Boolean] Whether to show a divider between the main content and the footer
  # @param header [Boolean] Whether to show a modal header
  # @param header_divider [Boolean] Whether to show a divider between the header and the main content
  # @param overlay [Boolean] Whether to show a backdrop overlay
  # @param padding [Boolean] Whether to add padding around the modal content
  # @param request [ActionDispatch::Request] The current Rails request object
  # @param size [Symbol, String] Drawer width preset (:xs, :sm, :md, :lg, :xl, :"2xl", :full) or CSS string (drawer-only)
  # @param content_div_data [Hash] `data` attribute for the div where the modal content will be rendered
  # @param title [String] The title of the modal
  def initialize(
    advance: nil,
    allowed_click_outside_selector: UltimateTurboModal.configuration.allowed_click_outside_selector,
    close_button: nil,
    close_button_data_action: "modal#hideModal",
    close_button_sr_label: "Close modal",
    _drawer_position: false,
    footer_divider: nil,
    header: nil,
    header_divider: nil,
    overlay: nil,
    padding: nil,
    size: nil,
    content_div_data: nil,
    request: nil, title: nil
  )
    @drawer = _drawer_position

    if drawer?
      cfg = UltimateTurboModal.configuration.drawer_config
      @advance = false
      @advance_url = nil
      @close_button = close_button.nil? ? cfg.close_button : close_button
      @drawer_size = self.class.validate_drawer_size!(size || cfg.size)
      @footer_divider = footer_divider.nil? ? cfg.footer_divider : footer_divider
      @header = header.nil? ? cfg.header : header
      @header_divider = header_divider.nil? ? cfg.header_divider : header_divider
      @overlay = overlay.nil? ? cfg.overlay : overlay
      @padding = padding.nil? ? cfg.padding : padding
    else
      cfg = UltimateTurboModal.configuration.modal_config
      adv = advance.nil? ? cfg.advance : advance
      @advance = !!adv
      @advance_url = (adv.present? && adv.is_a?(String)) ? adv : nil
      @close_button = close_button.nil? ? cfg.close_button : close_button
      @drawer_size = nil
      @footer_divider = footer_divider.nil? ? cfg.footer_divider : footer_divider
      @header = header.nil? ? cfg.header : header
      @header_divider = header_divider.nil? ? cfg.header_divider : header_divider
      @overlay = overlay.nil? ? cfg.overlay : overlay
      @padding = padding.nil? ? cfg.padding : padding
    end

    @allowed_click_outside_selector = allowed_click_outside_selector
    @close_button_data_action = close_button_data_action
    @close_button_sr_label = close_button_sr_label
    @content_div_data = content_div_data
    @request = request
    @title = title

    self.class.include_turbo_helpers
  end

  def self.include_turbo_helpers
    return if @turbo_helpers_included

    include Turbo::FramesHelper
    include Turbo::StreamsHelper
    include Phlex::Rails::Helpers::ContentTag
    include Phlex::Rails::Helpers::Routes
    include Phlex::Rails::Helpers::Tag
    @turbo_helpers_included = true
  end

  def view_template(&block)
    if turbo_frame?
      turbo_frame_tag("modal") do
        drawer? ? render_drawer(&block) : render_modal(&block)
      end
    else
      render block
    end
  end

  def title(&block)
    @title_block = block
  end

  def footer(&block)
    @footer = block
  end

  private

  attr_accessor :request, :allowed_click_outside_selector, :content_div_data

  def padding? = !!@padding

  def close_button? = !!@close_button

  def title_block? = !!@title_block

  def title? = !!@title

  def header? = !!@header

  def footer? = @footer.present?

  def header_divider? = !!@header_divider && (@title_block.present? || title?)

  def footer_divider? = !!@footer_divider && footer?

  def turbo_stream? = !!request&.format&.turbo_stream?

  def turbo_frame? = !!request&.headers&.key?("Turbo-Frame")

  def turbo? = turbo_stream? || turbo_frame?

  def advance? = !!@advance && !!@advance_url

  def drawer? = !!@drawer

  def drawer_position = @drawer || :right

  def overlay? = !!@overlay

  def advance_url
    return nil unless !!@advance
    @advance_url || request&.original_url
  end

  # Wraps yielded content in a Turbo Frame if the current request originated from a Turbo Frame
  def maybe_turbo_frame(frame_id, &block)
    if turbo_frame?
      turbo_frame_tag(frame_id, &block)
    else
      yield
    end
  end

  def respond_to_missing?(method, include_private = false)
    self.class.included_modules.any? { |mod| mod.instance_methods.include?(method) } || super
  end

  def method_missing(method, *, &block)
    mod = self.class.included_modules.find { |m| m.instance_methods.include?(method) }
    if mod
      mod.instance_method(method).bind_call(self, *, &block)
    else
      super
    end
  end

  ## HTML components — Modal

  def render_modal(&block)
    styles
    dialog_element do
      modal_inner do
        modal_content do
          modal_header
          modal_main(&block)
          modal_footer if footer?
        end
      end
    end
  end

  ## HTML components — Drawer

  def render_drawer(&block)
    styles
    dialog_element do
      drawer_wrapper do
        drawer_panel do
          drawer_content do
            drawer_header
            drawer_main(&block)
            drawer_footer if footer?
          end
        end
      end
    end
  end

  ## Styles

  def styles
    return unless self.class.const_defined?(:STYLES)
    css = self.class::STYLES
    return if css.nil? || css.empty?
    style { raw_html(css) }
  end

  def raw_html(str)
    respond_to?(:unsafe_raw) ? unsafe_raw(str) : raw(str)
  end

  VALID_DRAWER_SIZES = %i[xs sm md lg xl 2xl full].freeze

  def self.validate_drawer_size!(value)
    return value if VALID_DRAWER_SIZES.include?(value.to_s.to_sym)
    return value if value.is_a?(String) && value.match?(/\A\d+(\.\d+)?\s*(rem|em|px|%|vw|vh|dvw|dvh|svw|svh|lvw|lvh|ch|ex|cm|mm|in|pt|pc)\z/)

    raise ArgumentError,
      "Invalid drawer size: #{value.inspect}. Must be one of #{VALID_DRAWER_SIZES.map(&:inspect).join(", ")} or a CSS length string (e.g., \"30rem\", \"500px\", \"50vw\")"
  end

  def classes_for(suffix)
    prefix = drawer? ? "DRAWER" : "MODAL"
    self.class.const_get("#{prefix}_#{suffix}")
  end

  def custom_drawer_size?
    @drawer_size.present? && !VALID_DRAWER_SIZES.include?(@drawer_size.to_s.to_sym)
  end

  def dialog_element(&block)
    data_attributes = {
      controller: "modal",
      modal_target: "container",
      modal_advance_url_value: advance_url,
      modal_allowed_click_outside_selector_value: allowed_click_outside_selector,
      action: "turbo:submit-end->modal#submitEnd cancel->modal#cancelEvent click->modal#dialogClicked",
      padding: padding?.to_s,
      title: title?.to_s,
      header: header?.to_s,
      close_button: close_button?.to_s,
      header_divider: header_divider?.to_s,
      footer_divider: footer_divider?.to_s
    }

    if drawer?
      data_attributes[:drawer] = drawer_position.to_s
      data_attributes[:drawer_size] = (@drawer_size.presence || "md").to_s
      data_attributes[:overlay] = overlay?.to_s
    else
      data_attributes[:overlay] = overlay?.to_s
    end

    if defined?(Rails) && (Rails.env.development? || Rails.env.test?)
      data_attributes[:utmr_version] = UltimateTurboModal::VERSION
    end

    dialog_classes = ["utmr", classes_for("DIALOG_CLASSES")].reject(&:blank?).join(" ")

    inline_style = nil
    if drawer? && custom_drawer_size?
      inline_style = "--utmr-w: #{@drawer_size}"
    end

    dialog(id: "modal-container",
      class: dialog_classes,
      style: inline_style,
      aria: {
        labelledby: "modal-title-h"
      },
      data: data_attributes, &block)
  end

  ## Modal-specific elements

  def modal_inner(&block)
    maybe_turbo_frame("modal-inner") do
      div(id: "modal-inner", class: self.class::MODAL_INNER_CLASSES, &block)
    end
  end

  def modal_content(&block)
    data = (content_div_data || {}).merge({modal_target: "content"})
    div(id: "modal-content", class: self.class::MODAL_CONTENT_CLASSES, data: data, &block)
  end

  def modal_main(&block) = render_main(&block)
  def modal_header = render_header
  def modal_title = render_title
  def modal_footer = render_footer
  def modal_close = render_close

  ## Drawer-specific elements

  def drawer_wrapper(&block)
    maybe_turbo_frame("modal-inner") do
      div(id: "drawer-wrapper", class: self.class::DRAWER_WRAPPER_CLASSES, &block)
    end
  end

  def drawer_panel(&block)
    div(id: "drawer-panel", class: self.class::DRAWER_PANEL_CLASSES, data: {modal_target: "content"}, &block)
  end

  def drawer_content(&block)
    div(id: "modal-content", class: self.class::DRAWER_CONTENT_CLASSES, data: content_div_data, &block)
  end

  def drawer_main(&block) = render_main(&block)
  def drawer_header = render_header
  def drawer_title = render_title
  def drawer_footer = render_footer

  def drawer_close
    render_close do
      span(class: self.class::DRAWER_CLOSE_HIT_AREA_CLASSES) if self.class.const_defined?(:DRAWER_CLOSE_HIT_AREA_CLASSES)
    end
  end

  ## Shared rendering

  def render_main(&block)
    div(id: "modal-main", class: classes_for("MAIN_CLASSES"), &block)
  end

  def render_header
    div(id: "modal-header", class: classes_for("HEADER_CLASSES")) do
      render_title
      drawer? ? drawer_close : modal_close
    end
  end

  def render_title
    div(id: "modal-title", class: classes_for("TITLE_CLASSES")) do
      if @title_block.present?
        render @title_block
      else
        h3(id: "modal-title-h", class: classes_for("TITLE_H_CLASSES")) { @title }
      end
    end
  end

  def render_footer
    div(id: "modal-footer", class: classes_for("FOOTER_CLASSES")) do
      render @footer
    end
  end

  def render_close
    div(id: "modal-close", class: classes_for("CLOSE_CLASSES")) do
      close_button_tag(classes_for("CLOSE_BUTTON_CLASSES")) do
        yield if block_given?
        close_icon_svg(classes_for("CLOSE_ICON_CLASSES"))
        span(class: classes_for("CLOSE_SR_CLASSES")) { @close_button_sr_label }
      end
    end
  end

  ## Shared elements

  def close_button_tag(classes, &block)
    button(type: "button",
      aria: {label: "close"},
      class: classes,
      data: {
        action: @close_button_data_action
      }, &block)
  end

  def close_icon_svg(classes)
    svg(class: classes, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "1.5", aria_hidden: "true") do |s|
      s.path(d: "M6 18 18 6M6 6l12 12", stroke_linecap: "round", stroke_linejoin: "round")
    end
  end

end
