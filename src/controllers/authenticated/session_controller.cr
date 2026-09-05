class Authenticated::SessionController < ApplicationController
  def new
    render("new.ecr")
  end

  def destroy
    session.delete(:user_id)
    session.delete(:session_version)
    session.delete("id")
    session.delete("csrf.token")
    context.current_user = nil
    flash[:info] = "Logged out. See ya later!"
    redirect_to "/"
  end
end
