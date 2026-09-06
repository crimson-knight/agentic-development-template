require "amber/support/server_only"
require "digest/sha256"
require "random/secure"
require "crypto/bcrypt/password"
require "./account_service"

module App::Server::NativeSessions
  ABSOLUTE_LIFETIME = 8.hours
  IDLE_LIFETIME     = 30.minutes

  record Issued, token : String, expires_at : Time, profile : App::Accounts::Profile
  record Authenticated, digest : String, user : CurrentUser

  DUMMY_DIGEST = Crypto::Bcrypt::Password.create(Random::Secure.urlsafe_base64(32)).to_s

  def self.login(email : String, password : String, now : Time = Time.utc) : Issued?
    return nil unless email.valid_encoding? && password.valid_encoding? && 1 <= email.bytesize <= 255 && 1 <= password.bytesize <= 1024
    regular = Users::Regular.find_by(email: email.strip)
    admin = Users::Admin.find_by(email: email.strip)
    regular_valid = verify_password(regular, password)
    admin_valid = verify_password(admin, password)
    user = regular_valid ? regular : (admin_valid ? admin : nil)
    user ? issue(user, now) : nil
  end

  private def self.verify_password(user : CurrentUser?, password : String) : Bool
    supplied = user.try(&.password_digest)
    usable = supplied && !supplied.empty?
    hash = begin
      Crypto::Bcrypt::Password.new(usable ? supplied.not_nil! : DUMMY_DIGEST)
    rescue ArgumentError
      usable = false
      Crypto::Bcrypt::Password.new(DUMMY_DIGEST)
    end
    valid = hash.verify(password)
    !!usable && valid
  rescue ArgumentError
    false
  end

  def self.token?(value : String) : Bool
    value.bytesize == 43 && value.matches?(/\A[A-Za-z0-9_-]{43}\z/)
  end

  def self.writer : Grant::Adapter::Base
    connection = Grant::Connections["pg"] || raise "Account database unavailable"
    connection[:writer]
  end

  def self.issue(user : CurrentUser, now : Time = Time.utc) : Issued
    token = Random::Secure.urlsafe_base64(32, padding: false)
    expires = now + ABSOLUTE_LIFETIME
    account_type = user.is_a?(Users::Admin) ? "admin" : "regular"
    writer.open do |database|
      # Expired rows carry no valid token and can be removed without changing
      # another active session. Real authorization still checks expiry on every use.
      database.exec("DELETE FROM native_account_sessions WHERE expires_at <= $1 OR last_seen_at <= $2", now, now - IDLE_LIFETIME)
      database.exec("INSERT INTO native_account_sessions (token_digest, user_type, user_id, credential_fingerprint, created_at, last_seen_at, expires_at) VALUES ($1, $2, $3, $4, $5, $5, $6)",
        Digest::SHA256.hexdigest(token), account_type, user.id.not_nil!, Digest::SHA256.hexdigest(user.password_digest), now, expires)
    end
    Issued.new(token, expires, AccountService.profile(user))
  end

  def self.authenticate(token : String, now : Time = Time.utc) : Authenticated?
    return nil unless token?(token)
    digest = Digest::SHA256.hexdigest(token)
    row = writer.open do |database|
      database.query_one?("SELECT user_type, user_id, credential_fingerprint FROM native_account_sessions WHERE token_digest = $1 AND expires_at > $2 AND last_seen_at > $3",
        digest, now, now - IDLE_LIFETIME, as: {String, Int64, String})
    end
    return nil unless row
    account_type, user_id, fingerprint = row
    user = case account_type
           when "regular" then Users::Regular.find(user_id)
           when "admin"   then Users::Admin.find(user_id)
           end
    unless user && Digest::SHA256.hexdigest(user.password_digest) == fingerprint
      revoke_digest(digest)
      return nil
    end
    touched = writer.open do |database|
      database.exec("UPDATE native_account_sessions SET last_seen_at = $2 WHERE token_digest = $1 AND expires_at > $2 AND last_seen_at > $3",
        digest, now, now - IDLE_LIFETIME).rows_affected
    end
    return nil unless touched == 1
    Authenticated.new(digest, user)
  end

  def self.revoke_digest(digest : String) : Nil
    writer.open { |database| database.exec("DELETE FROM native_account_sessions WHERE token_digest = $1", digest) }
  end
end
