class Authenticated::BaseAuthenticatedController < ApplicationController
  property current_user : User = User.new

  before_action do
    only [:all] { set_current_user }
  end

  private def set_current_user
    @current_user = context.current_user || raise "No current user found"
  end
end
