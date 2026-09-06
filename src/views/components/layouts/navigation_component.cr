require "asset_pipeline/components/base/stateless_component"
require "./session_info_component"

module Components
  module Layouts
    # Top navigation bar component with logo, links, and session info
    #
    # Usage:
    #   nav = NavigationComponent.new(
    #     current_path: "/dashboard",
    #     logged_in: "true",
    #     user_email: "user@example.com"
    #   )
    #   nav.render
    #
    # Attributes:
    #   - current_path: Current request path for active link styling (required)
    #   - logged_in: Whether user is authenticated - "true" or "false" (default: "false")
    #   - user_email: User's email address (optional, only shown if logged in)
    #   - profile_href: Profile link URL (default: "/profile")
    #   - logout_href: Logout link URL (default: "/logout")
    #   - logo_src: Logo image source (default: "/img/logo.svg")
    #   - app_name: Application name (default: "AgentC")
    class NavigationComponent < StatelessComponent
      def render_content : String
        # Extract attributes
        current_path = @attributes["current_path"]? || "/"
        logged_in = @attributes["logged_in"]? == "true"
        user_email = @attributes["user_email"]?
        profile_href = @attributes["profile_href"]? || "/profile"
        logout_href = @attributes["logout_href"]? || "/logout"
        logo_src = @attributes["logo_src"]? || "/img/logo.svg"
        app_name = @attributes["app_name"]? || "AgentC"

        # Determine active state for Home link
        active_home = if current_path == "/"
                        "border-indigo-500 text-gray-900"
                      else
                        "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"
                      end

        # Build HTML
        String.build do |html|
          html << "<nav data-component=\"navigation\" class=\"bg-white shadow-sm border-b border-gray-200\">"
          html << "<div class=\"max-w-7xl mx-auto px-4 sm:px-6 lg:px-8\">"
          html << "<div class=\"flex justify-between h-16\">"

          # Left side: Logo and nav links
          html << "<div class=\"flex\">"

          # Logo
          html << "<div class=\"flex-shrink-0 flex items-center\">"
          html << "<a href=\"/\" class=\"flex items-center\">"
          html << "<img src=\"#{logo_src}\" class=\"h-8 w-auto\" alt=\"Logo\">"
          html << "<span class=\"ml-2 text-xl font-semibold text-gray-900\">#{app_name}</span>"
          html << "</a>"
          html << "</div>"

          # Navigation links (desktop)
          html << "<div class=\"hidden sm:ml-6 sm:flex sm:space-x-8\">"

          # Home link
          html << "<a href=\"/\" class=\"#{active_home} inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium transition-colors duration-200\">"
          html << "Home"
          html << "</a>"

          # Sign In link (only if not logged in)
          unless logged_in
            html << "<a href=\"/login\" class=\"border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium transition-colors duration-200\">"
            html << "Sign In"
            html << "</a>"
          end

          html << "</div>"
          html << "</div>"

          # Right side: Session info (desktop)
          html << "<div class=\"hidden sm:ml-6 sm:flex sm:items-center sm:space-x-4\">"

          if logged_in && user_email
            session_info = SessionInfoComponent.new(
              user_email: user_email,
              profile_href: profile_href,
              logout_href: logout_href
            )
            html << session_info.render
          end

          html << "</div>"

          # Mobile menu button
          html << "<div class=\"sm:hidden flex items-center\">"
          html << "<button type=\"button\" class=\"inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500\" aria-controls=\"mobile-menu\" aria-expanded=\"false\">"
          html << "<span class=\"sr-only\">Open main menu</span>"
          html << "<svg class=\"h-6 w-6\" xmlns=\"http://www.w3.org/2000/svg\" fill=\"none\" viewBox=\"0 0 24 24\" stroke=\"currentColor\">"
          html << "<path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M4 6h16M4 12h16M4 18h16\" />"
          html << "</svg>"
          html << "</button>"
          html << "</div>"

          html << "</div>"
          html << "</div>"
          html << "</nav>"
        end
      end

      def css_selector : String
        "nav.bg-white.shadow-sm"
      end
    end
  end
end
