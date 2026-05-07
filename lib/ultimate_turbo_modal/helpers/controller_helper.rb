# frozen_string_literal: true

module UltimateTurboModal::Helpers
  module ControllerHelper
    extend ActiveSupport::Concern

    MODAL_FRAME_IDS = %w[modal modal-inner drawer-modal modal-inner-stacked].freeze

    def inside_modal?
      MODAL_FRAME_IDS.include?(request.headers["Turbo-Frame"])
    end

    included do
      helper_method :inside_modal?
    end
  end
end
