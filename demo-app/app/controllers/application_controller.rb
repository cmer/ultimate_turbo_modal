class ApplicationController < ActionController::Base
  include SetFlavor

  def set_modal_properties
    %i[padding advance close_button].each do |it|
      instance_variable_set("@#{it}", params[it] == "1")
    end
    @override_url = "/custom-advance-history-url" if @advance
  end
end
