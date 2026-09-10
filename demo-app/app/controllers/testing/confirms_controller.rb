class Testing::ConfirmsController < ApplicationController
  before_action :set_modal_properties, only: [:in_modal, :in_drawer]

  def index
    @performed = session[:confirm_actions].to_i
  end

  # Every confirmed action lands here, so the counter on the index page is
  # proof that Cancel really did nothing.
  def act
    session[:confirm_actions] = session[:confirm_actions].to_i + 1
    redirect_to testing_confirms_path, notice: "Action performed (#{params[:label] || "unlabelled"})"
  end

  def in_modal
  end

  def in_drawer
  end
end
