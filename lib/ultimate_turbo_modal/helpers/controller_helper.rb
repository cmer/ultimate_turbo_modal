# frozen_string_literal: true

module UltimateTurboModal::Helpers
  module ControllerHelper
    extend ActiveSupport::Concern

     def inside_modal?
      turbo_frame = request.headers["Turbo-Frame"]
      turbo_frame.present? && turbo_frame.start_with?("modal")
    end

    included do
      helper_method :inside_modal?
    end
  end
end
