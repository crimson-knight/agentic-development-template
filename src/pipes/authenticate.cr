# This adds the `current_user` property to the HTTP::Server::Context from the Crystal standard library
class HTTP::Server::Context
  property current_user : User?
end

# This pipe sets the `current_user` property on the HTTP::Server::Context
class CurrentUserPipe < Amber::Pipe::Base
  def call(context)
    user_id = context.session["user_id"]?
    if user = User.find user_id
      context.current_user = user
    end
    call_next(context)
  end
end

# This pipe checks if the user is authenticated or not. If not, it redirects to the login page.
class AuthenticateUser < Amber::Pipe::Base
  def call(context)
    if context.current_user
      call_next(context)
    else
      context.flash[:warning] = "Please Sign In"
      context.response.headers.add "Location", "/login"
      context.response.status_code = 302
    end
  end
end
