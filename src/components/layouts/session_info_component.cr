require "../../../lib/asset_pipeline/src/components/base/stateless_component"
require "../shared/button_component"

module Components
  module Layouts
    # Session information component for displaying logged-in user details
    #
    # Usage:
    #   session_info = SessionInfoComponent.new(
    #     user_email: "user@example.com",
    #     profile_href: "/profile",
    #     logout_href: "/logout"
    #   )
    #   session_info.render
    #
    # Attributes:
    #   - user_email: User's email address (required)
    #   - profile_href: URL for profile link (default: "/profile")
    #   - logout_href: URL for logout link (default: "/logout")
    class SessionInfoComponent < StatelessComponent
      def render_content : String
        # Extract attributes
        user_email = @attributes["user_email"]? || "Guest"
        profile_href = @attributes["profile_href"]? || "/profile"
        logout_href = @attributes["logout_href"]? || "/logout"

        # Build logout button
        logout_button = Shared::ButtonComponent.new(
          label: "Logout",
          href: logout_href,
          variant: "secondary",
          size: "small"
        )

        # Build HTML
        String.build do |html|
          html << "<div class=\"flex items-center space-x-4\">"

          # User email
          html << "<span class=\"text-sm text-gray-700\">#{user_email}</span>"

          # Profile link
          html << "<a href=\"#{profile_href}\" class=\"text-sm text-indigo-600 hover:text-indigo-700\">Profile</a>"

          # Logout button
          html << logout_button.render

          html << "</div>"
        end
      end

      def css_selector : String
        ".flex.items-center.space-x-4"
      end
    end
  end
end
