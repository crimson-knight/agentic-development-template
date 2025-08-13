require "crypto/bcrypt/password"
require "granite/adapter/pg"

class Persona < Granite::Base
  connection pg
  table personas
  
  column id : Int64, primary: true
  column email : String
  column password_digest : String
  column type : String = "User"
  column api_key : String?
  column api_secret : String?
  column last_login_at : Time?
  timestamps
  
  # Virtual attributes
  property password : String?
  property password_confirmation : String?
  
  # Validations
  validate :email, "is required", ->(persona : Persona) { !persona.email.nil? && persona.email.not_nil!.size > 0 }
  validate :email, "must be unique", ->(persona : Persona) do
    existing = Persona.find_by(email: persona.email)
    existing.nil? || existing.id == persona.id
  end
  
  # Callbacks
  before_save :hash_password
  
  # Authentication methods
  def authenticate(password : String) : Persona?
    return nil if password_digest.nil?
    
    if Crypto::Bcrypt::Password.new(password_digest.not_nil!) == password
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
end