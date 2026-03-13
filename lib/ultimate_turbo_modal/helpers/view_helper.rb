# frozen_string_literal: true

module UltimateTurboModal::Helpers
  module ViewHelper
    def modal(**, &)
      render(UltimateTurboModal.new(request:, **), &)
    end

    def drawer(position: :right, overlay: false, size: UltimateTurboModal.configuration.drawer_size, **options, &block)
      modal(drawer: position, overlay: overlay, drawer_size: size, **options, &block)
    end
  end
end
