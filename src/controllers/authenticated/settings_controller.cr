class Authenticated::SettingsController < ApplicationController
  def index
    render_settings
  end

  def profile
    user = get_current_user || raise Amber::Exceptions::Forbidden.new("Sign-in required")
    name = params["display_name"]?.to_s.strip.gsub(/\s+/, " ")
    return render_settings("Use 100 characters or fewer for your name.", name) if name.size > 100

    user.display_name = name
    return render_settings("Your name could not be saved. Please try again.", name) unless user.save
    flash[:success] = "Your profile has been saved."
    redirect_to "/settings#profile"
  end

  def password
    user = get_current_user || raise Amber::Exceptions::Forbidden.new("Sign-in required")
    current = params["current_password"]?.to_s
    replacement = params["password"]?.to_s
    confirmation = params["password_confirmation"]?.to_s
    return render_settings("Enter your current password correctly.") unless current.bytesize <= 71 && user.authenticate(current)
    return render_settings("Use at least 8 characters and no more than 71 bytes.") unless replacement.size >= 8 && replacement.bytesize <= 71
    return render_settings("Your new passwords must match.") unless replacement == confirmation
    return render_settings("Choose a password different from your current password.") if user.authenticate(replacement)

    user.password = replacement
    user.password_confirmation = confirmation
    user.session_version = Random::Secure.hex(32)
    return render_settings("Your password could not be saved. Please try again.") unless user.save
    establish_session(user)
    flash[:success] = "Your password has been changed. Other sessions have been signed out."
    redirect_to "/settings#security"
  end

  def sessions
    user = get_current_user || raise Amber::Exceptions::Forbidden.new("Sign-in required")
    current = params["current_password"]?.to_s
    return render_settings("Enter your current password correctly.") unless current.bytesize <= 71 && user.authenticate(current)
    user.session_version = Random::Secure.hex(32)
    return render_settings("Other sessions could not be signed out. Please try again.") unless user.save
    establish_session(user)
    flash[:success] = "Other sessions have been signed out. You are still signed in here."
    redirect_to "/settings#security"
  end

  private def render_settings(error : String? = nil, submitted_name : String? = nil)
    account = get_current_user || raise Amber::Exceptions::Forbidden.new("Sign-in required")
    # Passed to the compiled ECR settings template.
    display_name = submitted_name || account.display_name # ameba:disable Lint/UselessAssign
    context.response.status_code = 422 if error
    render("index.ecr")
  end
end
