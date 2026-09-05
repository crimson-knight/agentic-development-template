class Public::SessionController < ApplicationController
  def new
    render("new.ecr")
  end

  def create
    email = params["email"]?.to_s.strip.downcase
    password = params["password"]?.to_s
    user = User.find_by({:email => email})
    destination = "/login"
    if user && !password.empty? && password.bytesize <= 71 && user.authenticate(password)
      if user.session_version.empty?
        user.session_version = Random::Secure.hex(32)
        user.save!
      end
      establish_session(user)
      flash[:info] = "Successfully signed in."
      destination = "/dashboard"
    else
      flash[:danger] = "There was a problem with the email or password. Please try again."
    end
    respond_with do
      html { redirect_to destination }
      json { {redirect_url: destination}.to_json }
    end
  end
end
