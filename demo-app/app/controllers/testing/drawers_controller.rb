class Testing::DrawersController < ApplicationController
  def index
  end

  def show
  end

  def nested_modal
    # Renders the modal that opens inside the drawer.
    render :nested_modal
  end

  def nested_modal_same_page
    # Redirects back to wherever the drawer was opened from. With the drawer
    # still open, this triggers the smooth same-page-with-sibling path: only
    # the inner modal closes.
    redirect_to(request.referer.presence || testing_drawers_path)
  end

  def nested_modal_other_page
    redirect_to testing_modal_index_path
  end

  # Stacked modal hosting a form. Submit with a blank name to trigger
  # validation errors that must re-render inside the stacked modal.
  def nested_form
    @errors = []
    @name = nil
  end

  def submit_nested_form
    @name = params[:name].to_s
    @errors = []
    @errors << "Name can't be blank" if @name.strip.empty?
    @errors << "Name must be at least 3 characters" if @name.strip.length.between?(1, 2)

    if @errors.any?
      render :nested_form, status: :unprocessable_entity
    elsif params[:wizard] == "1"
      redirect_to nested_form_step_two_testing_drawers_path(name: @name)
    else
      redirect_to testing_drawers_path, notice: "Saved!"
    end
  end

  def nested_form_step_two
    @name = params[:name].to_s
  end
end
