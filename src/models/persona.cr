require "jennifer/model/authentication"

class Persona < BaseModel
  include Jennifer::Model::Authentication

  with_authentication(skip_validation: true)
  with_timestamps

  mapping(
    id: Primary64,
    email: {type: String, default: ""},
    display_name: {type: String, default: ""},
    session_version: {type: String, default: ""},
    password_digest: {type: String, default: ""},
    password: Password,
    password_confirmation: {type: String?, virtual: true},
    api_key: String?,
    api_secret: String?,
    last_login_at: {type: Time?, default: nil},
    type: {type: String, default: "User"},
    created_at: Time?,
    updated_at: Time?
  )

  validates_length :display_name, maximum: 100, allow_blank: true
  validates_length :password, minimum: 8, maximum: 71, allow_blank: true
  validates_confirmation :password
  validates_with_method :validate_password_presence
  validates_with_method :validate_password_bytes

  # The pinned bcrypt string API includes a trailing NUL in its 72-byte input.
  # Enforce its real 71-byte password limit before hashing, including Unicode.
  def password=(value : String)
    @password = value
    return if value.empty? || value.bytesize > 71
    self.password_digest = Crypto::Bcrypt::Password.create(value, cost: self.class.password_digest_cost).to_s
  end

  private def validate_password_bytes
    errors.add(:password, "must fit within 71 bytes") if (password.try(&.bytesize) || 0) > 71
  end
end
