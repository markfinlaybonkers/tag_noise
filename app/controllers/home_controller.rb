class HomeController < ApplicationController
  def index
    @tag = Tag.new
  end
end
