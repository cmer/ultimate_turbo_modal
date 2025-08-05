module SetFlavor
  extend ActiveSupport::Concern

  included do
    before_action do
      UltimateTurboModal.flavor = request.params[:flavor] || cookies[:flavor] || "tailwind"
      cookies.permanent[:flavor] = UltimateTurboModal.flavor
    end
  end
end
