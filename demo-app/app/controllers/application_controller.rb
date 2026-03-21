class ApplicationController < ActionController::Base
  include SetFlavor

  def set_modal_properties
    %i[padding advance close_button].each do |prop|
      instance_variable_set("@#{prop}", params[prop] == "1" || params[prop].nil?)
    end
    @override_url = "/custom-advance-history-url" if @advance
  end
end
