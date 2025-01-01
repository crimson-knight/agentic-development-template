class LoginController < ApplicationController
  getter persona = Persona.new

  def new
    persona = Persona.new
    render("new.ecr")
  end

  def create
    user_authed_successfully = User.find_by({ :email => params["email"] }).try(&.authenticate(params["password"]))

    if user_authed_successfully && persona.is_a?(User)
      session[:persona_id] = user_authed_successfully.id
      flash[:info] = "Successfully logged in!"
      redirect_to "/"
    else
      flash[:danger] = "Invalid email or password"
      render("new.ecr")
    end
  end

  def destroy
    session.delete(:persona_id)
    flash[:info] = "Logged out. See ya later!"
    redirect_to "/"
  end
end
