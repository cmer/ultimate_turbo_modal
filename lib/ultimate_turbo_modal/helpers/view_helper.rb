# frozen_string_literal: true

module UltimateTurboModal::Helpers
  module ViewHelper
    def modal(**, &)
      render(UltimateTurboModal.new(request:, **), &)
    end

    def drawer(position: :right, overlay: true, size: UltimateTurboModal.configuration.drawer_size, **options, &block)
      UltimateTurboModal::Base.validate_drawer_size!(size)
      modal(drawer: position, overlay: overlay, drawer_size: size, **options, &block)
    end
  end
end
