require "jasper_helpers"

class ApplicationController < Amber::Controller::Base
  include JasperHelpers
  LAYOUT = "application.ecr"

  # Scoped down to regular `User`, use `Persona`
  def current_user : User | Nil
    context.current_user
  end

  def logged_in?
    current_user.present?
  end
end
