require "log"

class LoginController < ApplicationController
  getter persona = Persona.new
  property valid_email : String = ""
  property valid_password : String = ""

  before_action do
    only [:create] { validate_params }
  end

  def new
    persona = Persona.new
    render("new.ecr")
  end

  def create
    raise "Email param is required" if @valid_email.nil?
    raise "Password param is required" if @valid_password.nil?

    user_authed_successfully = User.find_by!({:email => @valid_email}).try(&.authenticate(@valid_password))

    if user_authed_successfully
      session[:user_id] = user_authed_successfully.id
      
      flash[:info] = "Successfully logged in!"
      respond_with do
        html { redirect_to "/dashboard" }
        json { %({"redirect_url": "/dashboard"}) }
      end

    else
      flash[:danger] = "There was a problem with the email or password. Please try again."
      respond_with do
        html { redirect_to "/login" }
        json { %({"redirect_url": "/login"}) }
      end
    end

  # The user was not found, this catches the error and handles the error message
  rescue e
    flash[:danger] = "There was an error while trying to log in. Please try again."
    Log.error { e.message }
    respond_with do
      json { %({"redirect_url": "/login"})}
    end
  end

  def destroy
    session.delete(:persona_id)
    flash[:info] = "Logged out. See ya later!"
    redirect_to "/"
  end

  private def validate_params
    if email = params["email"]
      # Add additional validation here, ie: email format, allowed domains, etc.
      @valid_email = email
    end

    if password = params["password"]
      # Add additional validation here, ie: password length, complexity, etc.
      @valid_password = password
    end
  end
end

