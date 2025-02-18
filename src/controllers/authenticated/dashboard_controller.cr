class Authenticated::DashboardController < ApplicationController
  def index
    render("index.ecr")
  end
end
