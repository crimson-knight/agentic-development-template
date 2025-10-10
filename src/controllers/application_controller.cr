require "jasper_helpers"

class ApplicationController < Amber::Controller::Base
  include JasperHelpers
  LAYOUT = "application.ecr"

  # Returns the current user (Users::Regular or Users::Admin)
  def get_current_user : CurrentUser?
    context.current_user
  end

  def logged_in?
    !get_current_user.nil?
  end
end
