class Authenticated::SessionController < ApplicationController
  def destroy
    session.delete(:persona_id)
    flash[:info] = "Logged out. See ya later!"
    redirect_to "/"
  end
end
