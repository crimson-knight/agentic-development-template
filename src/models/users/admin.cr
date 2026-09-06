require "crypto/bcrypt/password"
require "grant"

module Users
  class Admin < Grant::Base
    connection pg
    table admin_users

    column id : Int64, primary: true
    column email : String = ""
    column password_digest : String = ""
    column display_name : String = ""
    column api_key : String?
    column api_secret : String?
    column last_login_at : Time?
    timestamps

    # Virtual attributes for password handling
    property password : String?
    property password_confirmation : String?

    # Validations
    validate :email, "is required", ->(admin : Admin) do
      !admin.email.nil? && admin.email.not_nil!.size > 0
    end

    validate :email, "must be unique", ->(admin : Admin) do
      existing = Admin.find_by(email: admin.email)
      existing.nil? || existing.id == admin.id
    end

    # Callbacks
    before_save :hash_password
    before_save :generate_api_credentials_if_needed

    # Authentication methods
    def authenticate(password : String) : Admin?
      return nil if password_digest.empty?

      if Crypto::Bcrypt::Password.new(password_digest).verify(password)
        self
      else
        nil
      end
    end

    # API key authentication
    def self.authenticate_by_api_key(api_key : String, api_secret : String) : Admin?
      admin = find_by(api_key: api_key)
      return nil unless admin
      return nil unless admin.api_secret == api_secret
      admin
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

    private def generate_api_credentials_if_needed
      if new_record? && api_key.nil?
        self.api_key = Random::Secure.urlsafe_base64(32)
        self.api_secret = Random::Secure.urlsafe_base64(32)
      end
    end

    # Class methods for authentication
    def self.find_by_email(email : String)
      find_by(email: email)
    end

    def self.authenticate(email : String, password : String) : Admin?
      admin = find_by_email(email)
      return nil unless admin
      admin.authenticate(password)
    end
  end
end
