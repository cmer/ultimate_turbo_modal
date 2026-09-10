# frozen_string_literal: true

module UltimateTurboModal::Helpers
  module ViewHelper
    def modal(**, &)
      render(UltimateTurboModal.new(request:, **), &)
    end

    def drawer(position: nil, size: nil, **options, &block)
      cfg = UltimateTurboModal.configuration.drawer_config
      position = UltimateTurboModal::Base.validate_drawer_position!(position || cfg.position)
      size = UltimateTurboModal::Base.validate_drawer_size!(size || cfg.size)
      modal(drawer_position: position, size: size, **options, &block)
    end

    # Renders the inert <template> the Turbo Confirm dialog is cloned from.
    # Place it once in your layout: its presence is what enables the feature.
    # Renders nothing when `config.confirm.enabled` is false, which turns the
    # feature off without touching the layout.
    def modal_confirm_template(**options)
      return unless UltimateTurboModal.configuration.confirm_config.enabled

      render(UltimateTurboModal.confirm(request:, **options))
    end

    # Builds the `data` attributes for an element that should prompt before
    # acting. The options are JSON-encoded into `data-turbo-confirm` because
    # Turbo rewrites a link with `data-turbo-method` into a synthetic form and
    # copies only a fixed set of attributes across -- sibling
    # `data-turbo-confirm-*` attributes on a link would be dropped.
    #
    #   link_to "Delete", post_path(post), data: modal_confirm(
    #     "This can't be undone.", title: "Delete post?", accept: "Delete",
    #     variant: :danger, turbo_method: :delete)
    #
    # `native: true` opts this one confirmation back out to `window.confirm`.
    # On a link that is the only way to say it, since Turbo drops sibling
    # `data-turbo-confirm-native` along with everything else.
    def modal_confirm(body = nil, title: nil, accept: nil, cancel: nil, variant: nil, native: nil, **data)
      payload = {title: title, body: body, accept: accept, cancel: cancel,
                 variant: variant, native: native&.to_s}.compact
      raise ArgumentError, "modal_confirm requires a body or at least one option" if payload.empty?

      {turbo_confirm: payload.to_json}.merge(data)
    end
  end
end
