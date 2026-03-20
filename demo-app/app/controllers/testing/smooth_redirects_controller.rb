class Testing::SmoothRedirectsController < ApplicationController
  def new
    @type = params[:type] || "modal"
  end

  def create
    if params[:redirect_to] == "different"
      redirect_to root_path, notice: "Redirected to a different page.", status: :see_other
    else
      redirect_to testing_root_path, notice: "Redirected back to the same page.", status: :see_other
    end
  end
end
