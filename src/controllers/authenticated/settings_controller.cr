require "html"
require "../../views/components/layouts/application_layout"
require "../../platform/server/account_service"

# Authenticated account settings. Shows the current user's own information.
class Authenticated::SettingsController < Authenticated::BaseAuthenticatedController
  def index
    user = current_user.not_nil!
    account_type = user.is_a?(Users::Admin) ? "Admin" : "Regular"

    content = String.build do |html|
      html << "<div data-component=\"settings\" class=\"max-w-2xl mx-auto\">"
      html << "<h1 class=\"text-2xl font-bold text-gray-900 mb-6\">Account Settings</h1>"
      html << "<dl class=\"divide-y divide-gray-200 bg-white shadow rounded-lg px-6\">"
      html << setting_row("Email", HTML.escape(user.email))
      html << setting_row("Account type", account_type)
      html << setting_row("Display name", HTML.escape(user.display_name))
      html << "</dl>"
      html << "<form method=\"POST\" action=\"/settings\" data-component=\"account-name-form\" class=\"mt-6 space-y-4\">"
      html << "<input type=\"hidden\" name=\"_csrf\" value=\"#{HTML.escape(csrf_token)}\">"
      html << "<label for=\"display-name\" class=\"block text-sm font-medium text-gray-700\">Display name</label>"
      html << "<input id=\"display-name\" name=\"display_name\" maxlength=\"64\" autocomplete=\"nickname\" value=\"#{HTML.escape(user.display_name)}\" class=\"block w-full rounded-md border border-gray-300 p-2\">"
      html << "<button type=\"submit\" class=\"rounded-md bg-indigo-600 px-4 py-2 text-white\">Save display name</button></form>"
      html << "</div>"
    end

    layout = Components::Layouts::ApplicationLayout.new(
      title: "Settings - AgentC",
      content: content,
      current_path: request.path,
      logged_in: "true",
      user_email: user.email,
      flash_success: flash[:success]?,
      flash_error: flash[:danger]?
    )
    context.response.content_type = "text/html"
    context.response.print layout.render
  end

  def update
    App::Server::AccountService.rename(current_user.not_nil!, params["display_name"]? || "")
    flash[:success] = "Display name saved."
    redirect_to "/settings"
  rescue error : ArgumentError
    flash[:danger] = error.message || "Display name is invalid"
    redirect_to "/settings"
  rescue
    Log.error { "Account settings update failed" }
    flash[:danger] = "Could not update your account. Please try again."
    redirect_to "/settings"
  end

  private def setting_row(label : String, value : String) : String
    "<div class=\"py-4 flex justify-between text-sm\">" \
    "<dt class=\"font-medium text-gray-500\">#{label}</dt>" \
    "<dd class=\"text-gray-900\" data-field=\"#{label.downcase}\">#{value}</dd></div>"
  end
end
