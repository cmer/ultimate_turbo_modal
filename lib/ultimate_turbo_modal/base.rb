# frozen_string_literal: true

class UltimateTurboModal::Base < Phlex::HTML
  prepend Phlex::DeferredRenderWithMainContent

  attr_accessor :request, :allowed_click_outside_selector, :content_div_data
  CONFIRM_TEMPLATE_ID = "utmr-confirm-template"
  VALID_DRAWER_SIZES = %i[xs sm md lg xl 2xl full].freeze
  VALID_DRAWER_POSITIONS = %i[right left].freeze

  # @param advance [Boolean, String] Whether to update the browser history when opening and closing the modal or drawer
  # @param allowed_click_outside_selector [String] CSS selectors for elements that are allowed to be clicked outside of the modal without dismissing the modal
  # @param close_button [Boolean] Whether to show a close button
  # @param close_button_data_action [String] `data-action` attribute for the close button
  # @param close_button_sr_label [String] Close button label for screen readers
  # @param close_on_submit [Boolean] Whether to dismiss on a successful, non-redirecting form submission
  # @param confirm [Boolean] Internal: render the Turbo Confirm dialog template. Use the `modal_confirm_template` view helper instead.
  # @param drawer_position [Symbol, false] Internal: drawer position (:right, :left) or false for standard modal. Use the `drawer()` view helper instead.
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
    close_on_submit: nil,
    confirm: false,
    drawer_position: false,
    footer_divider: nil,
    header: nil,
    header_divider: nil,
    overlay: nil,
    padding: nil,
    size: nil,
    content_div_data: nil,
    accept_label: nil,
    cancel_label: nil,
    request: nil, title: nil
  )
    @drawer = drawer_position
    @confirm = confirm
    @request = request

    raise ArgumentError, "Cannot render a drawer into the drawer-modal frame (drawers cannot be opened from inside another drawer or modal)" if drawer? && stacked?

    if confirm?
      cfg = UltimateTurboModal.configuration.confirm_config
      @drawer_size = nil
      @accept_label = accept_label || cfg.accept_label
      @cancel_label = cancel_label || cfg.cancel_label
      title ||= cfg.title
    elsif drawer?
      cfg = UltimateTurboModal.configuration.drawer_config
      @drawer_size = self.class.validate_drawer_size!(size || cfg.size)
    else
      cfg = UltimateTurboModal.configuration.modal_config
      @drawer_size = nil
    end
    adv = advance.nil? ? cfg.advance : advance
    @advance = !!adv
    @advance_url = (adv.present? && adv.is_a?(String)) ? adv : nil
    @close_button = close_button.nil? ? cfg.close_button : close_button
    @close_on_submit = close_on_submit.nil? ? cfg.close_on_submit : close_on_submit
    @footer_divider = footer_divider.nil? ? cfg.footer_divider : footer_divider
    @header = header.nil? ? cfg.header : header
    @header_divider = header_divider.nil? ? cfg.header_divider : header_divider
    @overlay = overlay.nil? ? cfg.overlay : overlay
    @padding = padding.nil? ? cfg.padding : padding

    if stacked?
      @advance = false
      @advance_url = nil
    end

    @allowed_click_outside_selector = allowed_click_outside_selector
    @close_button_data_action = close_button_data_action
    @close_button_sr_label = close_button_sr_label
    @content_div_data = content_div_data
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
    if confirm?
      # Inert until the JS clones it, so it can live in the layout on every
      # page without a dialog (or its <style> tag) ever being active.
      template(id: CONFIRM_TEMPLATE_ID) { render_confirm }
    elsif turbo_frame?
      turbo_frame_tag(turbo_frame_name) do
        drawer? ? render_drawer(&block) : render_modal(&block)
      end
    else
      render block
    end
  end

  def turbo_frame_name
    stacked? ? "drawer-modal" : "modal"
  end

  # Both return nil so `<%= m.title do %>` writes nothing to the ERB buffer.
  # The assignment's own value is a Proc, and ERB would print it.
  def title(&block)
    @title_block = block
    nil
  end

  def footer(&block)
    @footer = block
    nil
  end

  class << self
    def validate_drawer_size!(value)
      return value if VALID_DRAWER_SIZES.include?(value.to_s.to_sym)
      return value if value.is_a?(String) && value.match?(/\A\d+(\.\d+)?\s*(rem|em|px|%|vw|vh|dvw|dvh|svw|svh|lvw|lvh|ch|ex|cm|mm|in|pt|pc)\z/)

      raise ArgumentError,
        "Invalid drawer size: #{value.inspect}. Must be one of #{VALID_DRAWER_SIZES.map(&:inspect).join(", ")} or a CSS length string (e.g., \"30rem\", \"500px\", \"50vw\")"
    end

    def validate_drawer_position!(value)
      return value if VALID_DRAWER_POSITIONS.include?(value.to_s.to_sym)

      raise ArgumentError,
        "Invalid drawer position: #{value.inspect}. Must be one of #{VALID_DRAWER_POSITIONS.map(&:inspect).join(", ")}"
    end
  end

  private

  def padding? = !!@padding

  def close_button? = !!@close_button

  def close_on_submit? = !!@close_on_submit

  def confirm? = !!@confirm

  def title_block? = !!@title_block

  def title? = !!@title

  def header? = !!@header

  # A confirm's footer holds its own buttons rather than a user block.
  def footer? = @footer.present? || confirm?

  def header_divider? = !!@header_divider && (@title_block.present? || title?)

  def footer_divider? = !!@footer_divider && footer?

  def turbo_stream? = !!request&.format&.turbo_stream?

  def turbo_frame? = !!request&.headers&.key?("Turbo-Frame")

  def turbo? = turbo_stream? || turbo_frame?

  def advance? = !!@advance && !!@advance_url

  def drawer? = !!@drawer

  # A request is "stacked" when it targets the stacked-modal frame directly
  # (`drawer-modal` — initial open from inside a drawer) or when it originates
  # from inside an already-rendered stacked modal (`modal-inner-stacked` —
  # validation re-renders, multi-step wizards, in-modal links). Both must
  # render with the stacked frame ids so Turbo can find the requesting frame.
  def stacked?
    frame = request&.headers&.[]("Turbo-Frame")
    frame == "drawer-modal" || frame == "modal-inner-stacked"
  end

  def dialog_id = scoped_id("modal-container")

  def inner_id = scoped_id("modal-inner")

  # Suffix inner ids so they don't collide with the drawer's ids when the
  # stacked modal is rendered inside the drawer's DOM, or with an open
  # modal's ids when the confirm dialog is layered over it.
  def scoped_id(name) = "#{name}#{id_suffix}"

  def id_suffix
    return "-confirm" if confirm?
    # A layout renders for Turbo Frame requests too, so this has to be checked
    # after confirm? -- otherwise a confirm template rendered during a stacked
    # request would claim the stacked modal's ids.
    stacked? ? "-stacked" : ""
  end

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
    self.class.included_modules.any? { |mod| mod.method_defined?(method) } || super
  end

  def method_missing(method, *, &block)
    mod = self.class.included_modules.find { |m| m.method_defined?(method) }
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
    return if css.blank?
    style { raw_html(css) }
  end

  def raw_html(str)
    raw(safe(str))
  end

  # Confirm dialogs render through the modal's markup, so every slot falls back
  # to its MODAL_* class unless the flavor defines a CONFIRM_* override.
  def classes_for(suffix)
    if confirm?
      override = confirm_classes_for(suffix)
      return override unless override.nil?
    end

    prefix = drawer? ? "DRAWER" : "MODAL"
    self.class.const_get("#{prefix}_#{suffix}")
  end

  # CONFIRM_* constants are optional. A flavor file written before confirm
  # support returns nil here, which means shared slots fall back to MODAL_* and
  # the confirm-only slots (body, actions, buttons) render unstyled rather than
  # raising. `warn_missing_confirm_classes` is what tells the developer why.
  def confirm_classes_for(suffix)
    const = :"CONFIRM_#{suffix}"
    self.class.const_defined?(const) ? self.class.const_get(const) : nil
  end

  # An unstyled confirm dialog looks like a bug in the gem rather than a stale
  # flavor file, so say which it is. Once per flavor class, in development only.
  def warn_missing_confirm_classes
    return unless defined?(Rails) && Rails.env.local?
    return if self.class.const_defined?(:CONFIRM_ACTIONS_CLASSES)
    return if self.class.instance_variable_get(:@utmr_confirm_classes_warned)

    self.class.instance_variable_set(:@utmr_confirm_classes_warned, true)
    Rails.logger&.warn(
      "[UltimateTurboModal] #{self.class.name} defines no CONFIRM_* classes, so the " \
      "confirm dialog will render unstyled. Run `rails g ultimate_turbo_modal:update` " \
      "to refresh your flavor file."
    )
  end

  def custom_drawer_size?
    @drawer_size.present? && !VALID_DRAWER_SIZES.include?(@drawer_size.to_s.to_sym)
  end

  def dialog_element(&block)
    data_attributes = {
      controller: "modal",
      modal_target: "container",
      action: dialog_actions,
      padding: padding?.to_s,
      title: title?.to_s,
      header: header?.to_s,
      close_button: close_button?.to_s,
      header_divider: header_divider?.to_s,
      footer_divider: footer_divider?.to_s,
      overlay: overlay?.to_s
    }

    role = nil
    aria_attributes = {labelledby: scoped_id("modal-title-h")}

    if confirm?
      # Everything the controller reads from those three values is driven by an
      # action a confirm doesn't bind, so they would only ever mislead a reader.
      data_attributes[:utmr_confirm] = ""
      role = "alertdialog"
      aria_attributes[:describedby] = scoped_id("modal-body")
    else
      data_attributes[:modal_advance_url_value] = advance_url
      data_attributes[:modal_allowed_click_outside_selector_value] = allowed_click_outside_selector
      data_attributes[:modal_close_on_submit_value] = close_on_submit?.to_s
    end

    if drawer?
      data_attributes[:drawer] = drawer_position.to_s
      data_attributes[:drawer_size] = (@drawer_size.presence || "md").to_s
    end

    if defined?(Rails) && Rails.env.local?
      data_attributes[:utmr_version] = UltimateTurboModal::VERSION
    end

    dialog_classes = ["utmr", classes_for("DIALOG_CLASSES")].compact_blank.join(" ")

    inline_style = nil
    if drawer? && custom_drawer_size?
      inline_style = "--utmr-w: #{@drawer_size}"
    end

    dialog(id: dialog_id,
      class: dialog_classes,
      style: inline_style,
      role: role,
      aria: aria_attributes,
      data: data_attributes, &block)
  end

  # A confirm is a decision, so a stray click on the backdrop must not answer it
  # for the user. Leaving the outside-click actions off is the whole of it --
  # Escape and the Cancel button still dismiss.
  def dialog_actions
    return "cancel->modal#cancelEvent" if confirm?

    ["turbo:submit-end->modal#submitEnd",
      "cancel->modal#cancelEvent",
      "mousedown->modal#dialogMousedown",
      "click->modal#dialogClicked"].join(" ")
  end

  ## Modal-specific elements

  def modal_inner(&block)
    maybe_turbo_frame(inner_id) do
      div(id: inner_id, class: self.class::MODAL_INNER_CLASSES,
        data: {modal_target: "transition"}, &block)
    end
  end

  def modal_content(&block)
    data = (content_div_data || {}).merge({modal_target: "content"})
    div(id: scoped_id("modal-content"), class: self.class::MODAL_CONTENT_CLASSES, data: data, &block)
  end

  def modal_main(&block) = render_main(&block)
  def modal_header = render_header
  def modal_title = render_title
  def modal_footer = render_footer
  def modal_close = render_close

  ## Drawer-specific elements

  def drawer_wrapper(&block)
    maybe_turbo_frame("modal-inner") do
      div(id: "drawer-wrapper", class: self.class::DRAWER_WRAPPER_CLASSES) do
        yield
        # Empty frame so links inside the drawer can target a stacked modal
        # via data-turbo-frame="drawer-modal". Always rendered.
        turbo_frame_tag("drawer-modal")
      end
    end
  end

  def drawer_panel(&block)
    div(id: "drawer-panel", class: self.class::DRAWER_PANEL_CLASSES,
      data: {modal_target: "content transition"}, &block)
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

  ## Confirm-specific elements

  def render_confirm
    warn_missing_confirm_classes
    # Unlike the modal and drawer templates, the styles go *inside* the dialog:
    # the JS clones this one node out of the <template>, and the scroll-lock
    # rule has to come along with it and leave with it.
    dialog_element do
      styles
      confirm_inner do
        confirm_content do
          render_header
          confirm_main
          confirm_footer
        end
      end
    end
  end

  def confirm_inner(&block)
    div(id: inner_id, class: classes_for("INNER_CLASSES"), data: {modal_target: "transition"}, &block)
  end

  def confirm_content(&block)
    div(id: scoped_id("modal-content"), class: classes_for("CONTENT_CLASSES"), data: {modal_target: "content"}, &block)
  end

  # Left empty: the JavaScript fills it from `data-turbo-confirm`.
  def confirm_main
    render_main do
      div(id: scoped_id("modal-body"), class: confirm_classes_for("BODY_CLASSES"))
    end
  end

  def confirm_footer
    div(id: scoped_id("modal-footer"), class: classes_for("FOOTER_CLASSES")) do
      div(class: confirm_classes_for("ACTIONS_CLASSES")) do
        button(type: "button", class: confirm_classes_for("CANCEL_CLASSES"),
          data: {utmr_confirm_action: "cancel"}) { @cancel_label }
        button(type: "button", class: confirm_classes_for("ACCEPT_CLASSES"),
          data: {utmr_confirm_action: "accept"}) { @accept_label }
      end
    end
  end

  ## Shared rendering

  def render_main(&block)
    div(id: scoped_id("modal-main"), class: classes_for("MAIN_CLASSES"), &block)
  end

  def render_header
    div(id: scoped_id("modal-header"), class: classes_for("HEADER_CLASSES")) do
      render_title
      render_header_close
    end
  end

  # Modals and drawers always render the close button and let the flavor hide it
  # through `data-close-button`. A confirm leaves it out of the markup entirely
  # instead, which keeps it out of the tab order and the accessibility tree --
  # it has its own Cancel button, so it is off by default.
  def render_header_close
    return if confirm? && !close_button?

    drawer? ? drawer_close : modal_close
  end

  def render_title
    div(id: scoped_id("modal-title"), class: classes_for("TITLE_CLASSES")) do
      if @title_block.present?
        render @title_block
      else
        h3(id: scoped_id("modal-title-h"), class: classes_for("TITLE_H_CLASSES")) { @title }
      end
    end
  end

  def render_footer
    div(id: scoped_id("modal-footer"), class: classes_for("FOOTER_CLASSES")) do
      render @footer
    end
  end

  def render_close
    div(id: scoped_id("modal-close"), class: classes_for("CLOSE_CLASSES")) do
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
