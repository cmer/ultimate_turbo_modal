# Sometimes it might be desirable to close the modal from the backend.
# This can be done with Turbo Stream as such:
#
#   <%= turbo_stream.modal(:hide) %>
#
# This controller is an example of how to do that.
class HideFromBackendsController < ApplicationController
  def new
    # Show form
  end

  def create
    form_is_valid? ? close_modal : render(:new, status: :unprocessable_entity)
  end

  private

  def close_modal
    if inside_modal?
      # `create.turbo_stream.erb` will be rendered.
      # A message will appear in the browser, and the backend
      # will trigger a modal close via turbo stream.
    else
      # if not inside a modal, simply redirect
      redirect_to("/")
    end
  end

  def form_is_valid?
    return true if request.params[:action] == 'new'
    params[:email].present?
  end
  helper_method :form_is_valid?
end
