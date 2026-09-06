require "./remote"

module App::Accounts
  # Only this bounded value is persisted, through protected Secrets. Account
  # data, passwords, form drafts and route history are deliberately not stored.
  record Credential, origin : String, token : String, expires_at : Int64 do
    def encode : String
      {origin: origin, token: token, expires_at: expires_at}.to_json
    end

    def self.decode(value : String, expected_origin : String) : Credential
      raise ArgumentError.new("Invalid protected session") unless value.bytesize <= 2048
      parser = Wire.parser(value.to_slice)
      origin = token = ""
      expires = 0_i64
      Wire.fields(parser, ["origin", "token", "expires_at"]) do |key|
        case key
        when "origin"     then origin = parser.read_string
        when "token"      then token = parser.read_string
        when "expires_at" then expires = parser.read_int
        end
      end
      unless parser.kind.eof? && origin == expected_origin && Wire.token?(token) && expires > 0
        raise ArgumentError.new("Invalid protected session")
      end
      new(origin, token, expires)
    end
  end

  # Retained, application-thread state. HTTP completions are generation-fenced.
  # Vault operations are serialized: sign-out waits for an in-flight write to
  # finish, then deletes. Cancelling a write is not treated as rolling it back.
  class SessionState
    enum Phase
      New
      Loading
      SignedOut
      SigningIn
      SavingSession
      OpeningAccount
      SignedIn
      Updating
      SigningOut
      Unavailable
      StorageFailure
      Stopped
    end

    SECRET_KEY = "account.session.v1"
    getter phase = Phase::New
    getter account : Profile?
    getter notice = "Opening protected session..."
    getter revision = 0_u64
    @epoch = 0_u64
    @credential : Credential?
    @http : Amber::Native::Operation?
    @vault : Amber::Native::Operation?
    @vault_busy = false
    @clear_pending = false
    @signout_requested = false
    @revocation_token : String?
    @cleanup_id = 0_u64
    @cleanup = {} of UInt64 => Amber::Native::Operation
    @signout_notice = "Signed out."

    def initialize(@remote : Remote, @secrets : Amber::Native::Secrets,
                   @clock : Proc(Int64) = -> { Time.utc.to_unix }, &changed : ->)
      @changed = changed
    end

    def signed_in? : Bool
      @phase.signed_in? || @phase.updating?
    end

    def busy? : Bool
      @phase.loading? || @phase.signing_in? || @phase.saving_session? ||
        @phase.opening_account? || @phase.updating? || @phase.signing_out?
    end

    def start : Nil
      return unless @phase.new?
      read_session
    end

    def login(email : String, password : String) : Nil
      return unless @phase.signed_out?
      epoch = transition(Phase::SigningIn, "Signing in...")
      begin
        @http = @remote.login(email, password) do |result|
          unless current?(epoch)
            cleanup_token(result.token) if result.is_a?(Session) && !@phase.stopped?
            next
          end
          @http = nil
          case result
          when Session
            if result.expires_at <= @clock.call || !result.account.valid?
              cleanup_token(result.token)
              transition(Phase::SignedOut, "The server returned an invalid session. Please try again.")
            else
              @credential = Credential.new(@remote.origin, result.token, result.expires_at)
              save_session(result.account)
            end
          when Failure
            transition(Phase::SignedOut, login_failure(result))
          end
          changed
        end
      rescue ArgumentError
        transition(Phase::SignedOut, "Enter an email and password within the supported size limits.")
      rescue Amber::Native::ServiceError
        transition(Phase::SignedOut, "Sign-in is unavailable. Please try again.")
      end
      changed
    end

    def rename(value : String) : Nil
      return unless @phase.signed_in?
      begin
        normalized = DisplayName.normalize(value)
      rescue ArgumentError
        @notice = "Use at most 64 characters without control characters."
        changed
        return
      end
      credential = @credential.not_nil!
      if credential.expires_at <= @clock.call
        sign_out("Your session expired. Please sign in again.")
        return
      end
      expected = @account.not_nil!
      epoch = transition(Phase::Updating, "Saving display name...")
      begin
        @http = @remote.rename(credential.token, normalized) do |result|
          next unless current?(epoch)
          @http = nil
          case result
          when Profile
            if result.valid? && result.id == expected.id && result.account_type == expected.account_type
              @account = result
              transition(Phase::SignedIn, "Display name saved.")
            else
              transition(Phase::SignedIn, "The server returned an invalid account. Your displayed data was not replaced.")
            end
          when Failure
            if result.unauthorized?
              sign_out("Your session expired. Please sign in again.")
              next
            end
            transition(Phase::SignedIn, result.invalid_name? ? "Use at most 64 characters without control characters." : "Could not confirm the update. Retry or refresh your account.")
          end
          changed
        end
      rescue Amber::Native::ServiceError | ArgumentError
        transition(Phase::SignedIn, "The account update is unavailable. Please try again.")
      end
      changed
    end

    def refresh : Nil
      return unless @phase.signed_in? || @phase.unavailable?
      open_account
    end

    def retry : Nil
      if @phase.unavailable?
        open_account
      elsif @phase.storage_failure?
        @signout_requested ? sign_out(@signout_notice) : read_session
      end
    end

    # No success is reported until the protected delete has completed. A kill
    # before that acknowledgment is an interrupted sign-out, not durable logout.
    def sign_out(message = "Signed out.") : Nil
      return if @phase.stopped? || @phase.signing_out? || @phase.new?
      @signout_requested = true
      @signout_notice = message
      @revocation_token ||= @credential.try(&.token)
      @credential = nil
      @account = nil
      transition(Phase::SigningOut, "Removing protected session...")
      @clear_pending = true
      clear_session unless @vault_busy
      changed
    end

    def stop : Nil
      return if @phase.stopped?
      transition(Phase::Stopped, "Session closed.")
      @account = nil
      @credential = nil
      @revocation_token = nil
      @clear_pending = false
      cancel(@vault)
      @cleanup.each_value { |operation| cancel(operation) }
      @cleanup.clear
      # Do not notify a UI whose terminal host is already closing.
    end

    private def read_session : Nil
      epoch = transition(Phase::Loading, "Opening protected session...")
      @vault_busy = true
      begin
        @vault = @secrets.read(SECRET_KEY) do |result|
          @vault = nil
          @vault_busy = false
          next if @phase.stopped?
          stored = decode_credential(result)
          if @clear_pending
            @revocation_token ||= stored.try(&.token)
            clear_session
            next
          end
          next unless current?(epoch)
          case result
          when Nil
            transition(Phase::SignedOut, "Sign in with your AgentC account.")
          when Amber::Native::ServiceError
            storage_failure
          when String
            if stored
              @credential = stored
              open_account
            else
              storage_failure
            end
          end
          changed
        end
      rescue Amber::Native::ServiceError
        @vault_busy = false
        storage_failure
      end
      changed
    end

    private def decode_credential(result) : Credential?
      return nil unless result.is_a?(String)
      Credential.decode(result, @remote.origin)
    rescue JSON::ParseException | ArgumentError | OverflowError
      nil
    end

    private def save_session(account : Profile) : Nil
      epoch = transition(Phase::SavingSession, "Protecting your session...")
      @vault_busy = true
      begin
        @vault = @secrets.write(SECRET_KEY, @credential.not_nil!.encode) do |result|
          @vault = nil
          @vault_busy = false
          next if @phase.stopped?
          if @clear_pending
            clear_session
            next
          end
          next unless current?(epoch)
          if result.is_a?(Amber::Native::ServiceError)
            sign_out("The session could not be saved. Please sign in again.")
          else
            @account = account
            transition(Phase::SignedIn, "Signed in securely.")
            changed
          end
        end
      rescue Amber::Native::ServiceError
        @vault_busy = false
        sign_out("The session could not be saved. Please sign in again.")
      end
    end

    private def open_account : Nil
      credential = @credential
      return unless credential
      if credential.expires_at <= @clock.call
        sign_out("Your session expired. Please sign in again.")
        return
      end
      epoch = transition(Phase::OpeningAccount, "Loading your account...")
      begin
        @http = @remote.account(credential.token) do |result|
          next unless current?(epoch)
          @http = nil
          case result
          when Profile
            if result.valid?
              @account = result
              transition(Phase::SignedIn, "Account is up to date.")
            else
              @account = nil
              transition(Phase::Unavailable, "The server returned an invalid account. Please retry.")
            end
          when Failure
            if result.unauthorized?
              sign_out("Your session expired. Please sign in again.")
              next
            end
            @account = nil
            transition(Phase::Unavailable, "Could not load your account. Retry when connected, or sign out.")
          end
          changed
        end
      rescue Amber::Native::ServiceError | ArgumentError
        @account = nil
        transition(Phase::Unavailable, "Could not load your account. Retry when connected, or sign out.")
      end
      changed
    end

    private def clear_session : Nil
      return if @vault_busy || @phase.stopped?
      @clear_pending = false
      @vault_busy = true
      epoch = @epoch
      begin
        @vault = @secrets.delete(SECRET_KEY) do |result|
          @vault = nil
          @vault_busy = false
          next unless current?(epoch)
          if result.is_a?(Amber::Native::ServiceError)
            cleanup_token(@revocation_token)
            storage_failure
            @notice = "Sign-out is incomplete: protected storage could not be cleared. Retry before using another account."
            changed
          else
            finish_signout
          end
        end
      rescue Amber::Native::ServiceError
        @vault_busy = false
        storage_failure
        @notice = "Sign-out is incomplete: protected storage could not be cleared. Please retry."
        changed
      end
    end

    private def finish_signout : Nil
      token = @revocation_token
      @revocation_token = nil
      unless token
        @signout_requested = false
        transition(Phase::SignedOut, @signout_notice)
        changed
        return
      end
      epoch = @epoch
      @notice = "Signing out from the server..."
      begin
        @http = @remote.logout(token) do |result|
          next unless current?(epoch)
          @http = nil
          @signout_requested = false
          message = result.nil? || result.try(&.unauthorized?) ? @signout_notice : "Signed out on this device. The unreachable server session will expire automatically."
          transition(Phase::SignedOut, message)
          changed
        end
      rescue Amber::Native::ServiceError | ArgumentError
        @signout_requested = false
        transition(Phase::SignedOut, "Signed out on this device. The unreachable server session will expire automatically.")
      end
      changed
    end

    private def cleanup_token(token : String?) : Nil
      return unless token && Wire.token?(token) && !@phase.stopped? && @cleanup.size < 16
      @cleanup_id += 1
      id = @cleanup_id
      @cleanup[id] = @remote.logout(token) { |_| @cleanup.delete(id); nil }
    rescue Amber::Native::ServiceError | ArgumentError
      # A token without a reachable server still has bounded server expiry.
    end

    private def transition(phase : Phase, notice : String) : UInt64
      @epoch += 1
      previous = @http
      @http = nil
      @phase = phase
      @notice = notice
      cancel(previous)
      @epoch
    end

    private def cancel(operation : Amber::Native::Operation?) : Nil
      operation.try(&.cancel)
    rescue Amber::Native::ServiceError
      # Generation fencing still prevents a cancelled operation from publishing.
    end

    private def current?(epoch) : Bool
      !@phase.stopped? && @epoch == epoch
    end

    private def storage_failure : Nil
      @account = nil
      transition(Phase::StorageFailure, "Protected session could not be opened. Retry or clear the stored session.")
    end

    private def login_failure(failure : Failure) : String
      case failure
      when .unauthorized? then "The email or password was not accepted."
      when .rate_limited? then "Too many sign-in attempts. Please wait a minute."
      when .cancelled?    then "Sign-in was cancelled."
      else                     "Sign-in is unavailable. Please try again."
      end
    end

    private def changed : Nil
      return if @phase.stopped?
      @revision += 1
      @changed.call
    end
  end
end
