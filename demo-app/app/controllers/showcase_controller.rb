class ShowcaseController < ApplicationController
  layout -> { turbo_frame_request? ? false : "showcase" }

  def index
  end

  def show
  end

  def save_project
    redirect_to root_path, notice: "Project saved successfully!"
  end

  def submit
    if params[:email].present?
      if inside_modal?
        respond_to do |format|
          format.turbo_stream
        end
      else
        redirect_to root_path
      end
    else
      params[:id] = "server_close"
      render :show, status: :unprocessable_entity
    end
  end

  private

  def form_is_valid?
    action_name == "show" || params[:email].present?
  end
  helper_method :form_is_valid?
end
