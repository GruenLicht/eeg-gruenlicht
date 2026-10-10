class BlogController < ApplicationController
  def index
    @posts = BlogPost.all
  end

  def show
    @post = BlogPost.find(params[:slug])
    @more_posts = BlogPost.all.reject { |post| post.slug == @post.slug }.first(3)
  end
end
