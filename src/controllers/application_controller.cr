require "jasper_helpers"

class ApplicationController < Amber::Controller::Base
  include JasperHelpers
  LAYOUT = "application.ecr"

  def current_user : Persona | Nil
    Persona.find(session["user_id"])
  end

  def logged_in?
    current_user.present?
  end
end
