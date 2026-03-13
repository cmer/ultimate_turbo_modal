# frozen_string_literal: true

class UltimateTurboModal::Base < Phlex::HTML
  prepend Phlex::DeferredRenderWithMainContent
  # @param advance [Boolean] Whether to update the browser history when opening and closing the modal
  # @param allowed_click_outside_selector [String] CSS selectors for elements that are allowed to be clicked outside of the modal without dismissing the modal
  # @param close_button [Boolean] Whether to show a close button
  # @param close_button_data_action [String] `data-action` attribute for the close button
  # @param close_button_sr_label [String] Close button label for screen readers
  # @param footer_divider [Boolean] Whether to show a divider between the main content and the footer
  # @param header_divider [Boolean] Whether to show a divider between the header and the main content
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
    footer_divider: UltimateTurboModal.configuration.footer_divider,
    header: UltimateTurboModal.configuration.header,
    header_divider: UltimateTurboModal.configuration.header_divider,
    padding: UltimateTurboModal.configuration.padding,
    content_div_data: nil,
    request: nil, title: nil
  )
    @advance = !!advance
    @advance_url = advance if advance.present? && advance.is_a?(String)
    @allowed_click_outside_selector = allowed_click_outside_selector
    @close_button = close_button
    @close_button_data_action = close_button_data_action
    @close_button_sr_label = close_button_sr_label
    @footer_divider = footer_divider
    @header = header
    @header_divider = header_divider
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
        modal(&block)
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

  ## HTML components

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

  def styles
    style do
      raw_html <<~CSS.squish
        html:has(dialog[open]) { overflow: hidden; scrollbar-gutter: stable; }
        dialog#modal-container { padding: 0; margin: 0; border: none; background: transparent;
          max-width: 100vw; max-height: 100dvh; width: 100%; height: 100%; overflow-y: auto; }
        @keyframes utmr-backdrop-in { from { opacity: 0 } to { opacity: 1 } }
        @keyframes utmr-backdrop-out { from { opacity: 1 } to { opacity: 0 } }
        @keyframes utmr-dialog-in-mobile { from { opacity: 0; transform: translateY(1rem) } to { opacity: 1; transform: translateY(0) } }
        @keyframes utmr-dialog-in-desktop { from { opacity: 0; transform: scale(0.95) } to { opacity: 1; transform: scale(1) } }
        @keyframes utmr-dialog-out-mobile { from { opacity: 1; transform: translateY(0) } to { opacity: 0; transform: translateY(1rem) } }
        @keyframes utmr-dialog-out-desktop { from { opacity: 1; transform: scale(1) } to { opacity: 0; transform: scale(0.95) } }
        dialog#modal-container[open]::backdrop { animation: utmr-backdrop-in 300ms ease-out forwards; }
        dialog#modal-container[open] #modal-inner {
          animation: utmr-dialog-in-mobile 300ms ease-out forwards; }
        @media (min-width: 640px) {
          dialog#modal-container[open] #modal-inner {
            animation: utmr-dialog-in-desktop 300ms ease-out forwards; } }
        dialog#modal-container[data-closing]::backdrop { animation: utmr-backdrop-out 200ms ease-in forwards; }
        dialog#modal-container[data-closing] #modal-inner {
          animation: utmr-dialog-out-mobile 200ms ease-in forwards; }
        @media (min-width: 640px) {
          dialog#modal-container[data-closing] #modal-inner {
            animation: utmr-dialog-out-desktop 200ms ease-in forwards; } }
      CSS
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

    if defined?(Rails) && (Rails.env.development? || Rails.env.test?)
      data_attributes[:utmr_version] = UltimateTurboModal::VERSION
    end

    dialog(id: "modal-container",
      class: self.class::DIALOG_CLASSES,
      aria: {
        labelledby: "modal-title-h"
      },
      data: data_attributes, &block)
  end

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
      close_button_tag do
        icon_close
        span(class: self.class::BUTTON_CLOSE_SR_ONLY_CLASSES) { @close_button_sr_label }
      end
    end
  end

  def close_button_tag(&block)
    button(type: "button",
      aria: {label: "close"},
      class: self.class::CLOSE_BUTTON_TAG_CLASSES,
      data: {
        action: @close_button_data_action
      }, &block)
  end

  def icon_close
    svg(class: self.class::ICON_CLOSE_CLASSES, fill: "currentColor", viewBox: "0 0 20 20") do |s|
      s.path(
        fill_rule: "evenodd",
        d: "M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z",
        clip_rule: "evenodd"
      )
    end
  end
end
