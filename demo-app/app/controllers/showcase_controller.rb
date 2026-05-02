class ShowcaseController < ApplicationController
  layout -> { turbo_frame_request? ? false : "showcase" }

  def index
  end

  def show
    @contact = Contact.new
  end

  def save_project
    redirect_to root_path, notice: "Project saved successfully!"
  end

  def save_preferences
    redirect_to root_path, notice: "Notification preferences saved!"
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

  def submit_contact
    @contact = Contact.new(contact_params)

    if @contact.valid?
      redirect_to root_path,
        notice: "Message sent successfully!",
        status: :see_other
    else
      params[:id] = "form_modal"
      render :show, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :message)
  end

  def form_is_valid?
    action_name == "show" || params[:email].present?
  end
  helper_method :form_is_valid?
end
