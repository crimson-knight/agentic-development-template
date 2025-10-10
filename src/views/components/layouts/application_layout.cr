require "../../../../lib/asset_pipeline/src/components/base/stateless_component"
require "./navigation_component"
require "../shared/flash_message_component"

module Components
  module Layouts
    # Complete HTML document layout component
    #
    # Usage:
    #   layout = ApplicationLayout.new(
    #     title: "Dashboard",
    #     content: page_component.render,
    #     current_path: request.path,
    #     logged_in: logged_in?.to_s,
    #     user_email: current_user.try(&.email),
    #     flash_success: "Operation completed!",
    #     flash_error: nil
    #   )
    #   layout.render
    #
    # Attributes:
    #   - title: Page title (default: "AgentC App Template")
    #   - content: Main page content HTML (required)
    #   - current_path: Current request path (default: "/")
    #   - logged_in: Authentication state - "true" or "false" (default: "false")
    #   - user_email: User's email address (optional)
    #   - flash_success: Success flash message (optional)
    #   - flash_error: Error flash message (optional)
    #   - flash_info: Info flash message (optional)
    #   - flash_warning: Warning flash message (optional)
    #   - import_map_html: Asset Pipeline import map HTML (optional)
    #   - auto_reload: Enable auto-reload script - "true" or "false" (default: "false")
    class ApplicationLayout < StatelessComponent
      def render_content : String
        # Extract attributes
        title = @attributes["title"]? || "AgentC App Template"
        content = @attributes["content"]? || ""
        current_path = @attributes["current_path"]? || "/"
        logged_in = @attributes["logged_in"]? || "false"
        user_email = @attributes["user_email"]?
        flash_success = @attributes["flash_success"]?
        flash_error = @attributes["flash_error"]?
        flash_info = @attributes["flash_info"]?
        flash_warning = @attributes["flash_warning"]?
        import_map_html = @attributes["import_map_html"]? || ""
        auto_reload = @attributes["auto_reload"]? == "true"

        # Build navigation
        nav = NavigationComponent.new(
          current_path: current_path,
          logged_in: logged_in,
          user_email: user_email
        )

        # Build flash messages
        flash_html = String.build do |html|
          if flash_success
            flash_msg = Shared::FlashMessageComponent.new(
              type: "success",
              message: flash_success
            )
            html << flash_msg.render
          end

          if flash_error
            flash_msg = Shared::FlashMessageComponent.new(
              type: "error",
              message: flash_error
            )
            html << flash_msg.render
          end

          if flash_info
            flash_msg = Shared::FlashMessageComponent.new(
              type: "info",
              message: flash_info
            )
            html << flash_msg.render
          end

          if flash_warning
            flash_msg = Shared::FlashMessageComponent.new(
              type: "warning",
              message: flash_warning
            )
            html << flash_msg.render
          end
        end

        # Build complete HTML document
        String.build do |html|
          html << "<!doctype html>\n"
          html << "<html class=\"h-full bg-gray-50\">\n"
          html << "  <head>\n"
          html << "    <title>#{title}</title>\n"
          html << "    <meta charset=\"utf-8\" />\n"
          html << "    <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\" />\n"
          html << "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />\n"
          html << "    <script src=\"https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4\"></script>\n"
          html << "    <link rel=\"stylesheet\" href=\"/css/main.css\" />\n"
          html << "    <link rel=\"apple-touch-icon\" href=\"/favicon.png\">\n"
          html << "    <link rel=\"icon\" href=\"/favicon.png\">\n"
          html << "    <link rel=\"icon\" type=\"image/x-icon\" href=\"/favicon.ico\">\n"

          # Asset Pipeline import map
          if !import_map_html.empty?
            html << "\n    <!-- Links to the import map for Stimulus controllers -->\n"
            html << "    #{import_map_html}\n"
          end

          # Stimulus setup
          html << "    <script type=\"module\">\n"
          html << "      import { Application, Controller } from \"@hotwired/stimulus\"\n"
          html << "      \n"
          html << "      // Import each controller below here using the syntax: import ControllerName from \"ControllerName\"\n"
          html << "      import LoginController from \"login_controller\"\n"
          html << "      // End new controller imports\n"
          html << "\n"
          html << "      // Start the Stimulus application\n"
          html << "      window.Stimulus = Application.start()\n"
          html << "\n"
          html << "      // Register each controller below here using the syntax: Stimulus.register(\"controller-name\", ControllerName)\n"
          html << "      Stimulus.register(\"login\", LoginController)\n"
          html << "      // End new controller registrations\n"
          html << "\n"
          html << "      // -- Initialize any other JavaScript below here --\n"
          html << "    </script>\n"
          html << "  </head>\n"

          html << "  <body class=\"h-full\">\n"
          html << "    <div class=\"min-h-full\">\n"

          # Navigation
          html << "      #{nav.render}\n"

          # Flash messages
          if !flash_html.empty?
            html << "      <div class=\"max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-4\">\n"
            html << "        #{flash_html}\n"
            html << "      </div>\n"
          end

          # Main content
          html << "      <main class=\"max-w-7xl mx-auto py-6 sm:px-6 lg:px-8\">\n"
          html << "        #{content}\n"
          html << "      </main>\n"

          html << "    </div>\n"

          # Scripts
          html << "    <script type=\"module\" src=\"/js/amber.js\"></script>\n"
          if auto_reload
            html << "    <script src=\"/js/client_reload.js\"></script>\n"
          end

          html << "  </body>\n"
          html << "</html>\n"
        end
      end

      def css_selector : String
        "html.h-full.bg-gray-50"
      end
    end
  end
end
