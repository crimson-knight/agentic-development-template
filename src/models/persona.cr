require "jennifer/model/authentication"

class Persona < Jennifer::Model::Base
  include Jennifer::Model::Authentication

  with_authentication

  mapping(
    id: Primary64,
    email: {type: String, default: ""},
    password_digest: {type: String, default: ""},
    password: Password,
    password_confirmation: {type: String?, virtual: true},
    last_login_at: {type: Time?, default: nil},
    type: {type: String, default: "User"}
  )
end
