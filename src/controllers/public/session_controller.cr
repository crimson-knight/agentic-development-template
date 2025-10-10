require "../../components/forms/login_form_component"
require "../../components/layouts/application_layout"

class Public::SessionController < ApplicationController
  property valid_email : String = ""
  property valid_password : String = ""

  before_action do
    only [:create] { validate_params }
  end

  def new
    # Build login form component
    form = Components::Forms::LoginFormComponent.new(
      csrf_token: csrf_token,
      email_value: params["email"]?,
      error_message: flash[:danger]?
    )

    # Wrap in layout
    layout = Components::Layouts::ApplicationLayout.new(
      title: "Sign In - AgentC",
      content: form.render,
      current_path: request.path,
      logged_in: "false",
      flash_success: flash[:success]?,
      flash_error: flash[:danger]?,
      flash_info: flash[:info]?
    )

    context.response.content_type = "text/html"
    context.response.print layout.render
  end

  def create
    raise "Email param is required" if @valid_email.nil?
    raise "Password param is required" if @valid_password.nil?

    # Try to authenticate as regular user first
    authenticated_user = Users::Regular.authenticate(@valid_email, @valid_password)
    user_type = "regular"

    # If not found, try admin user
    if authenticated_user.nil?
      authenticated_user = Users::Admin.authenticate(@valid_email, @valid_password)
      user_type = "admin"
    end

    if authenticated_user
      session[:user_id] = authenticated_user.id
      session[:user_type] = user_type

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
      json { %({"redirect_url": "/login"}) }
    end
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
