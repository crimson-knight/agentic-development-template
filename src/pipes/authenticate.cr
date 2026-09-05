# This adds the `current_user` property to the HTTP::Server::Context from the Crystal standard library
class HTTP::Server::Context
  property current_user : User?
end

# This pipe sets the `current_user` property on the HTTP::Server::Context
class CurrentUserPipe < Amber::Pipe::Base
  def call(context)
    context.current_user = nil
    if user_id = context.session["user_id"]?.try(&.to_i64?)
      if user = User.find(user_id)
        version = context.session["session_version"]?
        context.current_user = user if !user.session_version.empty? && version == user.session_version
      end
      unless context.current_user
        context.session.delete("user_id")
        context.session.delete("session_version")
      end
    end
    call_next(context)
  end
end

# This pipe checks if the user is authenticated or not. If not, it redirects to the login page.
class AuthenticateUser < Amber::Pipe::Base
  def call(context)
    if context.current_user
      context.response.headers["Cache-Control"] = "private, no-store"
      call_next(context)
    else
      context.flash[:warning] = "Please Sign In"
      context.response.headers.add "Location", "/login"
      context.response.status_code = 302
    end
  end
end
