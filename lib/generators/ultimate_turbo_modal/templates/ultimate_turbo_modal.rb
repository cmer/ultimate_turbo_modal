# frozen_string_literal: true

UltimateTurboModal.configure do |config|
  config.flavor = FLAVOR
  # config.allowed_click_outside_selector = []

  # config.modal do |m|
  #   m.advance = false
  #   m.close_button = true
  #   m.close_on_submit = true
  #   m.header = true
  #   m.header_divider = true
  #   m.footer_divider = true
  #   m.padding = true
  #   m.overlay = true
  # end

  # config.drawer do |d|
  #   d.position = :right
  #   d.advance = false
  #   d.close_button = true
  #   d.close_on_submit = true
  #   d.header = true
  #   d.header_divider = false
  #   d.footer_divider = true
  #   d.padding = true
  #   d.overlay = true
  #   d.size = :md
  # end

  # Turbo Confirm support. Enable it by adding `<%= modal_confirm_template %>`
  # to your layout; these are the dialog's defaults.
  # config.confirm do |c|
  #   c.enabled = true
  #   c.title = "Are you sure?"
  #   c.accept_label = "OK"
  #   c.cancel_label = "Cancel"
  #   c.close_button = false
  #   c.header = true
  #   c.header_divider = false
  #   c.footer_divider = false
  #   c.padding = true
  #   c.overlay = true
  # end
end
