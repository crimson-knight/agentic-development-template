require "amber/support/server_only"
require "../../app/accounts/profile"

module App::Server::AccountService
  def self.profile(user : CurrentUser) : App::Accounts::Profile
    App::Accounts::Profile.new(user.id.not_nil!, user.email,
      user.is_a?(Users::Admin) ? "admin" : "regular", user.display_name)
  end

  # The same operation is called by authenticated web settings and mobile API.
  # Neither entrypoint accepts another account ID or any other mutable fields.
  def self.rename(user : CurrentUser, value : String) : App::Accounts::Profile
    user.display_name = App::Accounts::DisplayName.normalize(value)
    # Grant's save macro needs a concrete model (the union's common ancestor
    # deliberately has no table/primary key).
    saved = case user
            when Users::Regular then user.save
            when Users::Admin   then user.save
            end
    raise "Account update failed" unless saved
    profile(user)
  end
end
