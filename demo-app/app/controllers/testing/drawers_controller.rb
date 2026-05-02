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
    # Redirects back to the page the drawer was opened from (the testing
    # drawers index). With my drawer still open, this triggers the smooth
    # same-page-with-sibling path: only the inner modal closes.
    redirect_to testing_drawers_path
  end

  def nested_modal_other_page
    redirect_to testing_modal_index_path
  end
end
