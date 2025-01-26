class Authenticated::BaseAuthenticatedController < ApplicationController
  property current_user : User = User.new

  before_action do
    set_current_user
  end

  private def set_current_user
    @current_user = get_current_user
  end
end
