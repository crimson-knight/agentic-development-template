# Union type for different user types
alias CurrentUser = Users::Regular | Users::Admin

# This adds the `current_user` property to the HTTP::Server::Context from the Crystal standard library
class HTTP::Server::Context
  property current_user : CurrentUser?
  property user_type : String?
end

# This pipe sets the `current_user` property on the HTTP::Server::Context
class CurrentUserPipe < Amber::Pipe::Base
  def call(context)
    user_id = context.session["user_id"]?
    user_type = context.session["user_type"]?

    if user_id && user_type
      case user_type
      when "regular"
        if user = Users::Regular.find user_id
          context.current_user = user
          context.user_type = "regular"
        end
      when "admin"
        if user = Users::Admin.find user_id
          context.current_user = user
          context.user_type = "admin"
        end
      end
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
