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

  private def establish_session(user : User)
    session.delete("id")
    session.delete("csrf.token")
    session[:user_id] = user.id
    session[:session_version] = user.session_version
    context.current_user = user
  end

  private def html_escape(value) : String
    HTML.escape(value.to_s)
  end
end
