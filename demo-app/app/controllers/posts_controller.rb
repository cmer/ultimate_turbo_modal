class PostsController < ApplicationController
  before_action :set_post, only: %i[show edit update destroy]
  before_action :set_modal_properties

  # GET /posts
  def index
    @posts = Post.all
  end

  # GET /posts/1
  def show
    @modal_title = @post.title
  end

  # GET /posts/new
  def new
    @post = Post.new
    @modal_title = "New Post"
  end

  # GET /posts/1/edit
  def edit
    @modal_title = "Edit Post"
  end

  # POST /posts
  def create
    @post = Post.new(post_params)
    @modal_title = "New Post"

    if @post.save
      redirect_to "/",
                  notice: "Post was successfully created.",
                  status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /posts/1
  def update
    if @post.update(post_params)
      redirect_to "/",
                  notice: "Post was successfully updated.",
                  status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /posts/1
  def destroy
    redirect_to "/",
                notice: "Post was successfully destroyed. (but not really)",
                status: :see_other
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_post
    @post = Post.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def post_params
    params.require(:post).permit(:title, :body)
  end
end
