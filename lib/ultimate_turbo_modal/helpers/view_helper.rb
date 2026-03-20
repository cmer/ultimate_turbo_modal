# frozen_string_literal: true

module UltimateTurboModal::Helpers
  module ViewHelper
    def modal(**, &)
      render(UltimateTurboModal.new(request:, **), &)
    end

    def drawer(position: nil, size: nil, **options, &block)
      cfg = UltimateTurboModal.configuration.drawer_config
      pos = position || cfg.position
      valid = %i[right left]
      raise ArgumentError, "Drawer position must be :right or :left, got #{pos.inspect}" unless valid.include?(pos)
      modal(_drawer_position: pos, size: size, **options, &block)
    end
  end
end
