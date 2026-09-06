require "asset_pipeline/ui/android/application"
require "amber/native/android_http"
require "amber/native/android_secrets"
require "../../app/accounts/session_state"
require "./configuration"
require "./api_origin"

module App::Android
  class RootScreen < UI::View
    def initialize
      self.state_key = "account-root"
    end

    def accept(visitor : UI::PlatformVisitor)
      App::Android.root_screen.accept(visitor)
    end
  end

  class SettingsScreen < UI::View
    def initialize
      self.state_key = "account-settings"
    end

    def accept(visitor : UI::PlatformVisitor)
      App::Android.settings_screen.accept(visitor)
    end
  end

  class SessionProcess < Amber::Native::ProcessManager
    def start : Nil
      App::Android.state.start
    end

    def background : Nil
      App::Android.clear_password
    end

    def stop : Nil
      App::Android.clear_password
      App::Android.state.stop
    end
  end

  @@state : App::Accounts::SessionState = App::Accounts::SessionState.new(
    App::Accounts::HTTPRemote.new(Amber::Native::Android::HTTPClient.new, API_ORIGIN),
    Amber::Native::Android::Secrets.new) { App::Android.state_changed }
  @@lifecycle = Amber::Native::Lifecycle.new([SessionProcess.new])
  @@email = ""
  @@password = ""
  @@name = ""
  @@owner : {Int64, String}? = nil
  @@last_saved_name = ""
  @@session_scope = 0_u64
  @@navigation : UI::NavigationStack = UI::NavigationStack.new(RootScreen.new, DISPLAY_NAME).tap { |view| view.state_key = "account-navigation" }

  def self.state
    @@state
  end

  def self.clear_password : Nil
    @@password = ""
  end

  def self.state_changed : Nil
    if account = @@state.account
      owner = {account.id, account.account_type}
      if owner != @@owner
        @@owner = owner
        @@session_scope += 1
        @@name = @@last_saved_name = account.display_name
        @@navigation.pop_to_root
      elsif account.display_name != @@last_saved_name
        @@name = @@last_saved_name = account.display_name
      end
    elsif @@state.phase.signed_out? || @@state.phase.signing_out? || @@state.phase.storage_failure?
      @@owner = nil
      @@name = @@last_saved_name = ""
      @@password = ""
      @@session_scope += 1
      @@navigation.pop_to_root
    end
    UI::Android::Application.invalidate
  end

  def self.lifecycle(event : UI::Android::Application::LifecycleEvent) : Nil
    case event
    in .foreground? then @@lifecycle.activate
    in .background? then @@lifecycle.background
    in .stop?       then @@lifecycle.stop
    end
  end

  def self.screen : UI::View
    @@navigation
  end

  private def self.stack(key : String) : UI::VStack
    UI::VStack.new(16.0, UI::Alignment::Leading).tap do |view|
      view.state_key = key
      view.padding = UI::EdgeInsets.new(top: 24.0, trailing: 24.0, bottom: 24.0, leading: 24.0)
    end
  end

  private def self.heading(text : String, id : String) : UI::Label
    UI::Label.new(text).tap do |view|
      view.font = UI::Font.new(size: 28.0, weight: :bold)
      view.test_id = id
      view.accessibility_role = :header
    end
  end

  private def self.label(text : String, id : String) : UI::Label
    UI::Label.new(text).tap { |view| view.test_id = id }
  end

  private def self.button(text : String, id : String, enabled = true, &action : ->) : UI::Button
    UI::Button.new(text, &action).tap do |view|
      view.test_id = id
      view.minimum_height = 48.0
      view.disabled = !enabled
    end
  end

  private def self.input(title : String, value : String, id : String, key : String, &change : String ->) : UI::TextField
    UI::TextField.new(title, text: value, &change).tap do |view|
      view.test_id = id
      view.accessibility_label = title
      view.state_key = key
      view.minimum_height = 48.0
      view.grow!
    end
  end

  def self.root_screen : UI::View
    return dashboard_screen if @@state.signed_in?
    return signin_screen if @@state.phase.signed_out?
    view = stack("account-status")
    view << heading(DISPLAY_NAME, "account-status-title")
    view << label(@@state.notice, "account-notice")
    if @@state.phase.unavailable? || @@state.phase.storage_failure?
      view << button("Retry", "account-retry") { @@state.retry }
      view << button("Clear stored session", "account-clear-session") { @@state.sign_out }
    elsif !@@state.phase.signing_out?
      view << button("Cancel and sign out", "account-cancel") { @@state.sign_out }
    end
    view
  end

  private def self.signin_screen : UI::View
    view = stack("account-signin-#{@@session_scope}")
    mark = UI::Image.new("app_mark")
    mark.minimum_width = mark.maximum_width = 48.0
    mark.minimum_height = mark.maximum_height = 48.0
    mark.accessibility_label = "AgentC app mark"
    view << mark
    view << heading("Welcome to AgentC", "account-signin-title")
    view << label("Use the same account as your web application.", "account-signin-description")
    unless API_CONFIGURED
      view << label("Configure AGENTC_ANDROID_API_ORIGIN with your HTTPS server before building this app.", "account-configuration-required")
    end
    email = input("Email", @@email, "account-email", "account-email") { |value| @@email = value; nil }
    email.keyboard_type = UI::KeyboardType::EmailAddress
    view << email
    password = input("Password", @@password, "account-password", "account-password") { |value| @@password = value; nil }
    password.secure_entry = true
    view << password
    view << button("Sign in", "account-signin", API_CONFIGURED) do
      value = @@password
      @@password = ""
      @@state.login(@@email, value)
    end
    view << label(@@state.notice, "account-notice")
    view
  end

  private def self.dashboard_screen : UI::View
    account = @@state.account.not_nil!
    view = stack("account-dashboard-#{@@session_scope}")
    view << heading("Your account", "account-dashboard-title")
    view << label(account.title, "account-display-name")
    view << label("Email: #{account.email}", "account-email-value")
    view << label("Account type: #{account.account_type}", "account-type-value")
    view << label("Your profile is shared with the web app. Changes here are saved to your account.", "account-dashboard-description")
    view << button("Account settings", "account-open-settings", !@@state.busy?) do
      if @@state.signed_in? && !@@state.busy?
        @@name = account.display_name
        @@navigation.push(SettingsScreen.new)
      end
      nil
    end
    view << button("Refresh account", "account-refresh", !@@state.busy?) { @@state.refresh }
    view << button("Sign out", "account-signout") { @@state.sign_out }
    view << label(@@state.notice, "account-notice")
    view
  end

  def self.settings_screen : UI::View
    return root_screen unless @@state.signed_in?
    view = stack("account-settings-#{@@session_scope}")
    view << heading("Account settings", "account-settings-title")
    view << label("Display name", "account-name-label")
    if @@state.busy?
      view << label(@@name, "account-name-saving")
    else
      view << input("Display name", @@name, "account-name", "account-name-#{@@session_scope}") { |value| @@name = value; nil }
    end
    view << label("Up to 64 characters. Leave it empty to use your email instead.", "account-name-help")
    view << button("Save display name", "account-save-name", !@@state.busy?) { @@state.rename(@@name) }
    view << label(@@state.notice, "account-notice")
    view << button("Sign out", "account-signout") { @@state.sign_out }
    view
  end
end

UI::Android::Application.on_lifecycle { |event| App::Android.lifecycle(event) }
UI::Android::Application.configure { |_route| App::Android.screen }
