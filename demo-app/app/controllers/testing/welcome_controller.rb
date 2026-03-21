class Testing::WelcomeController < ApplicationController
  def index
    @post = Post.first
  end
end
