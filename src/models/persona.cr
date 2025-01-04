require "jennifer/model/authentication"

class Persona < Jennifer::Model::Base
  include Jennifer::Model::Authentication

  with_authentication
  with_timestamps

  mapping(
    id: Primary64,
    email: {type: String, default: ""},
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
end
