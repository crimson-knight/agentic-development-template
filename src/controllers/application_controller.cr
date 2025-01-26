require "jasper_helpers"

class ApplicationController < Amber::Controller::Base
  include JasperHelpers
  LAYOUT = "application.ecr"

  # Scoped down to regular `User`, you must use a conditional assignment to remove the `Nil` from the type union if you need to use the `current_user` in the controller.
  def get_current_user : User | Nil
    context.current_user
  end

  def logged_in?
    get_current_user.present?
  end
end
