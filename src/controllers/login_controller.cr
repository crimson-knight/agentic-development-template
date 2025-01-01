class LoginController < ApplicationController
  def new
    render("new.ecr")
  end

  def create
    user_authed_successfully = Persona.all.where { _email == params["email"] }.limit(1).first.try(&.authenticate(params["password"]))
    
    if user_authed_successfully
      render("create.ecr")
    else
      render("new.ecr")
    end
  end

  def destroy
    render("destroy.ecr")
  end
end
