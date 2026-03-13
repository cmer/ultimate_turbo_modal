# frozen_string_literal: true

class UltimateTurboModal::Base < Phlex::HTML
  prepend Phlex::DeferredRenderWithMainContent
  # @param advance [Boolean] Whether to update the browser history when opening and closing the modal
  # @param allowed_click_outside_selector [String] CSS selectors for elements that are allowed to be clicked outside of the modal without dismissing the modal
  # @param close_button [Boolean] Whether to show a close button
  # @param close_button_data_action [String] `data-action` attribute for the close button
  # @param close_button_sr_label [String] Close button label for screen readers
  # @param drawer [Symbol, false] Drawer position (:right, :left) or false for standard modal
  # @param drawer_size [Symbol, String] Drawer width preset (:sm, :md, :lg, :xl, :full) or CSS string
  # @param footer_divider [Boolean] Whether to show a divider between the main content and the footer
  # @param header_divider [Boolean] Whether to show a divider between the header and the main content
  # @param overlay [Boolean] Whether to show a backdrop overlay (drawers default to false, modals always true)
  # @param padding [Boolean] Whether to add padding around the modal content
  # @param request [ActionDispatch::Request] The current Rails request object
  # @param content_div_data [Hash] `data` attribute for the div where the modal content will be rendered
  # @param title [String] The title of the modal
  def initialize(
    advance: UltimateTurboModal.configuration.advance,
    allowed_click_outside_selector: UltimateTurboModal.configuration.allowed_click_outside_selector,
    close_button: UltimateTurboModal.configuration.close_button,
    close_button_data_action: "modal#hideModal",
    close_button_sr_label: "Close modal",
    drawer: UltimateTurboModal.configuration.drawer,
    drawer_size: UltimateTurboModal.configuration.drawer_size,
    footer_divider: UltimateTurboModal.configuration.footer_divider,
    header: UltimateTurboModal.configuration.header,
    header_divider: UltimateTurboModal.configuration.header_divider,
    overlay: UltimateTurboModal.configuration.overlay,
    padding: UltimateTurboModal.configuration.padding,
    content_div_data: nil,
    request: nil, title: nil
  )
    @drawer = drawer
    @advance = drawer ? false : !!advance
    @advance_url = (!drawer && advance.present? && advance.is_a?(String)) ? advance : nil
    @allowed_click_outside_selector = allowed_click_outside_selector
    @close_button = close_button
    @close_button_data_action = close_button_data_action
    @close_button_sr_label = close_button_sr_label
    @drawer_size = drawer_size
    @footer_divider = footer_divider
    @header = header
    @header_divider = drawer ? false : header_divider
    @overlay = overlay
    @padding = padding
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
        drawer? ? drawer(&block) : modal(&block)
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

  def modal(&block)
    styles
    dialog_element do
      div_inner do
        div_content do
          div_header
          div_main(&block)
          div_footer if footer?
        end
      end
    end
  end

  ## HTML components — Drawer

  def drawer(&block)
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
    style do
      raw_html(drawer? ? drawer_styles : modal_styles)
    end
  end

  def base_styles
    <<~CSS.squish
      html:has(dialog[open]) { overflow: hidden; scrollbar-gutter: stable; }
      dialog#modal-container { position: fixed; inset: 0; padding: 0; margin: 0; border: none; background: transparent;
        max-width: 100vw; max-height: 100dvh; width: 100%; height: 100%; overflow-y: auto; }
      @keyframes utmr-backdrop-in { from { opacity: 0 } to { opacity: 1 } }
      @keyframes utmr-backdrop-out { from { opacity: 1 } to { opacity: 0 } }
      dialog#modal-container[open]::backdrop { animation: utmr-backdrop-in 300ms ease-out forwards; }
      dialog#modal-container[data-closing]::backdrop { animation: utmr-backdrop-out 200ms ease-in forwards; }
    CSS
  end

  def modal_styles
    <<~CSS.squish
      #{base_styles}
      @keyframes utmr-dialog-in-mobile { from { opacity: 0; transform: translateY(1rem) } to { opacity: 1; transform: translateY(0) } }
      @keyframes utmr-dialog-in-desktop { from { opacity: 0; transform: scale(0.95) } to { opacity: 1; transform: scale(1) } }
      @keyframes utmr-dialog-out-mobile { from { opacity: 1; transform: translateY(0) } to { opacity: 0; transform: translateY(1rem) } }
      @keyframes utmr-dialog-out-desktop { from { opacity: 1; transform: scale(1) } to { opacity: 0; transform: scale(0.95) } }
      dialog#modal-container[open] #modal-inner {
        animation: utmr-dialog-in-mobile 300ms ease-out forwards; }
      @media (min-width: 640px) {
        dialog#modal-container[open] #modal-inner {
          animation: utmr-dialog-in-desktop 300ms ease-out forwards; } }
      dialog#modal-container[data-closing] #modal-inner {
        animation: utmr-dialog-out-mobile 200ms ease-in forwards; }
      @media (min-width: 640px) {
        dialog#modal-container[data-closing] #modal-inner {
          animation: utmr-dialog-out-desktop 200ms ease-in forwards; } }
    CSS
  end

  def drawer_styles
    drawer_edge = drawer_position == :left ? "left" : "right"
    hidden_translate = drawer_position == :left ? "-100% 0" : "100% 0"

    <<~CSS.squish
      #{base_styles}
      dialog#modal-container[data-overlay="false"]::backdrop { background: transparent !important; }
      dialog#modal-container { --utmr-drawer-width: #{drawer_width_css("2.5rem")}; }
      dialog#modal-container #drawer-panel {
        width: var(--utmr-drawer-width);
        #{drawer_edge}: 0;
        translate: #{hidden_translate};
        transition: translate 500ms ease-in-out;
        will-change: translate;
      }
      @media (min-width: 640px) {
        dialog#modal-container { --utmr-drawer-width: #{drawer_width_css("4rem")}; }
        dialog#modal-container #drawer-panel { transition-duration: 700ms; }
      }
      dialog#modal-container:not([data-enter-ready]):not([data-entered]) #drawer-panel { visibility: hidden; }
      dialog#modal-container[data-entered] #drawer-panel { translate: 0; }
      dialog#modal-container[data-closing] #drawer-panel { translate: #{hidden_translate}; }
    CSS
  end

  def drawer_width_css(gutter)
    available_width = "calc(100vw - #{gutter})"

    case @drawer_size.to_s
    when "", "md" then "min(28rem, #{available_width})"
    when "sm" then "min(24rem, #{available_width})"
    when "lg" then "min(42rem, #{available_width})"
    when "xl" then "min(56rem, #{available_width})"
    when "full" then available_width
    else "min(#{@drawer_size}, #{available_width})"
    end
  end

  def raw_html(str)
    respond_to?(:unsafe_raw) ? unsafe_raw(str) : raw(str)
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
      data_attributes[:drawer_size] = @drawer_size.to_s
      data_attributes[:overlay] = overlay?.to_s
    end

    if defined?(Rails) && (Rails.env.development? || Rails.env.test?)
      data_attributes[:utmr_version] = UltimateTurboModal::VERSION
    end

    dialog_classes = drawer? ? self.class::DRAWER_DIALOG_CLASSES : self.class::DIALOG_CLASSES

    dialog(id: "modal-container",
      class: dialog_classes,
      aria: {
        labelledby: "modal-title-h"
      },
      data: data_attributes, &block)
  end

  ## Modal-specific elements

  def div_inner(&block)
    maybe_turbo_frame("modal-inner") do
      div(id: "modal-inner", class: self.class::DIV_INNER_CLASSES, &block)
    end
  end

  def div_content(&block)
    data = (content_div_data || {}).merge({modal_target: "content"})
    div(id: "modal-content", class: self.class::DIV_CONTENT_CLASSES, data: data, &block)
  end

  def div_main(&block)
    div(id: "modal-main", class: self.class::DIV_MAIN_CLASSES, &block)
  end

  def div_header(&block)
    div(id: "modal-header", class: self.class::DIV_HEADER_CLASSES) do
      div_title
      button_close
    end
  end

  def div_title
    div(id: "modal-title", class: self.class::DIV_TITLE_CLASSES) do
      if @title_block.present?
        render @title_block
      else
        h3(id: "modal-title-h", class: self.class::DIV_TITLE_H_CLASSES) { @title }
      end
    end
  end

  def div_footer
    div(id: "modal-footer", class: self.class::DIV_FOOTER_CLASSES) do
      render @footer
    end
  end

  def button_close
    div(id: "modal-close", class: self.class::BUTTON_CLOSE_CLASSES) do
      close_button_tag(self.class::CLOSE_BUTTON_TAG_CLASSES) do
        close_icon_svg(self.class::ICON_CLOSE_CLASSES)
        span(class: self.class::BUTTON_CLOSE_SR_ONLY_CLASSES) { @close_button_sr_label }
      end
    end
  end

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

  def drawer_main(&block)
    div(id: "modal-main", class: self.class::DRAWER_MAIN_CLASSES, &block)
  end

  def drawer_header(&block)
    div(id: "modal-header", class: self.class::DRAWER_HEADER_CLASSES) do
      drawer_title
      drawer_button_close
    end
  end

  def drawer_title
    div(id: "modal-title", class: self.class::DRAWER_TITLE_CLASSES) do
      if @title_block.present?
        render @title_block
      else
        h3(id: "modal-title-h", class: self.class::DRAWER_TITLE_H_CLASSES) { @title }
      end
    end
  end

  def drawer_footer
    div(id: "modal-footer", class: self.class::DRAWER_FOOTER_CLASSES) do
      render @footer
    end
  end

  def drawer_button_close
    div(id: "modal-close", class: self.class::DRAWER_CLOSE_CLASSES) do
      close_button_tag(self.class::DRAWER_CLOSE_BUTTON_CLASSES) do
        span(class: self.class::DRAWER_CLOSE_HIT_AREA_CLASSES) if self.class.const_defined?(:DRAWER_CLOSE_HIT_AREA_CLASSES)
        close_icon_svg(self.class::DRAWER_CLOSE_ICON_CLASSES)
        span(class: self.class::DRAWER_CLOSE_SR_CLASSES) { @close_button_sr_label }
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
