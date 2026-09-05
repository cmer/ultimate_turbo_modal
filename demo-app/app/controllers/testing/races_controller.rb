class Testing::RacesController < ApplicationController
  def index
  end

  def morph_preserves_dialog
    @step = params[:step].presence || "one"
  end

  def supersede_close
    @kind = params[:kind].presence || "first"
  end
end
