require "crypto/bcrypt/password"
require "grant"

module Users
  class Regular < Grant::Base
    connection pg
    table regular_users

    column id : Int64, primary: true
    column email : String = ""
    column password_digest : String = ""
    column last_login_at : Time?
    timestamps

    # Virtual attributes for password handling
    property password : String?
    property password_confirmation : String?

    # Validations
    validate :email, "is required", ->(user : Regular) do
      !user.email.nil? && user.email.not_nil!.size > 0
    end

    validate :email, "must be unique", ->(user : Regular) do
      existing = Regular.find_by(email: user.email)
      existing.nil? || existing.id == user.id
    end

    # Callbacks
    before_save :hash_password

    # Authentication methods
    def authenticate(password : String) : Regular?
      return nil if password_digest.empty?

      if Crypto::Bcrypt::Password.new(password_digest).verify(password)
        self
      else
        nil
      end
    end

    # Password setter
    def password=(new_password : String?)
      @password = new_password
    end

    # Password confirmation setter
    def password_confirmation=(value : String?)
      @password_confirmation = value
    end

    private def hash_password
      if password = @password
        self.password_digest = Crypto::Bcrypt::Password.create(password).to_s
      end
    end

    # Class methods for authentication
    def self.find_by_email(email : String)
      find_by(email: email)
    end

    def self.authenticate(email : String, password : String) : Regular?
      user = find_by_email(email)
      return nil unless user
      user.authenticate(password)
    end
  end
end
