require "../../platform/server/native_sessions"

class ApiControllers::NativeAccountsController < Amber::Controller::Base
  def create_session : Nil
    fields = context.native_fields.not_nil!
    if issued = App::Server::NativeSessions.login(fields["email"], fields["password"])
      response.status_code = 201
      response.print({token: issued.token, expires_at: issued.expires_at.to_unix, account: issued.profile}.to_json)
    else
      unauthorized
    end
  end

  def account : Nil
    if session = authenticated
      response.print({account: App::Server::AccountService.profile(session.user)}.to_json)
    else
      unauthorized
    end
  end

  def update_account : Nil
    if session = authenticated
      begin
        profile = App::Server::AccountService.rename(session.user, context.native_fields.not_nil!["display_name"])
        response.print({account: profile}.to_json)
      rescue ArgumentError
        response.status_code = 422
        response.print({error: "invalid_display_name"}.to_json)
      end
    else
      unauthorized
    end
  end

  def destroy_session : Nil
    if session = authenticated
      App::Server::NativeSessions.revoke_digest(session.digest)
      response.status_code = 204
    else
      unauthorized
    end
  end

  private def authenticated : App::Server::NativeSessions::Authenticated?
    values = request.headers.get?("Authorization")
    return nil unless values && values.size == 1
    header = values.first
    return nil unless header.starts_with?("Bearer ")
    App::Server::NativeSessions.authenticate(header.byte_slice(7))
  end

  private def unauthorized
    response.status_code = 401
    response.headers["WWW-Authenticate"] = "Bearer realm=\"agentc-native\""
    response.print({error: "unauthorized"}.to_json)
  end
end
