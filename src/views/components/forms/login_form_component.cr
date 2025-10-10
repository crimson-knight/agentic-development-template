require "../../../../lib/asset_pipeline/src/components/base/stateful_component"
require "../shared/icon_component"

module Components
  module Forms
    # Stateful login form component with validation
    #
    # Usage:
    #   form = LoginFormComponent.new(
    #     csrf_token: csrf_token,
    #     email_value: params["email"]?,
    #     error_message: "Invalid credentials"
    #   )
    #   form.render
    #
    # Attributes:
    #   - csrf_token: CSRF token from controller (required)
    #   - email_value: Pre-filled email value (optional)
    #   - error_message: Error message to display (optional)
    #   - action: Form action URL (default: "/login")
    #
    # State:
    #   - email: Current email input value
    #   - password: Current password input value
    #   - errors: Hash of field errors
    #   - submitting: Whether form is being submitted
    class LoginFormComponent < StatefulComponent
      protected def initialize_state
        # Initialize form state
        set_state("email", @attributes["email_value"]? || "")
        set_state("password", "")
        set_state("errors", Hash(String, JSON::Any).new)
        set_state("submitting", false)
        set_state("error_message", @attributes["error_message"]? || "")
      end

      # Validate email format
      def validate_email(email : String) : Bool
        !!(email =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      end

      # Validate form inputs
      def validate : Hash(String, JSON::Any)
        errors = Hash(String, JSON::Any).new

        email = get_state("email").try(&.as_s?) || ""
        password = get_state("password").try(&.as_s?) || ""

        if email.empty?
          errors["email"] = JSON::Any.new("Email is required")
        elsif !validate_email(email)
          errors["email"] = JSON::Any.new("Invalid email format")
        end

        if password.empty?
          errors["password"] = JSON::Any.new("Password is required")
        elsif password.size < 6
          errors["password"] = JSON::Any.new("Password must be at least 6 characters")
        end

        errors
      end

      # Set email value and validate
      def set_email(email : String)
        set_state("email", email)
        errors = validate
        set_state("errors", errors)
      end

      # Set password value and validate
      def set_password(password : String)
        set_state("password", password)
        errors = validate
        set_state("errors", errors)
      end

      # Check if form is valid
      def valid? : Bool
        validate.empty?
      end

      # Set submitting state
      def set_submitting(submitting : Bool)
        set_state("submitting", submitting)
      end

      # Set error message from server
      def set_error_message(message : String)
        set_state("error_message", message)
      end

      def render_content : String
        # Extract attributes
        csrf_token = @attributes["csrf_token"]? || ""
        action = @attributes["action"]? || "/login"

        # Get state
        email = get_state("email").try(&.as_s?) || ""
        password = get_state("password").try(&.as_s?) || ""
        errors = get_state("errors").try(&.as_h?) || Hash(String, JSON::Any).new
        submitting = get_state("submitting").try(&.as_bool?) || false
        error_message = get_state("error_message").try(&.as_s?) || ""

        # Build user icon
        user_icon = Shared::IconComponent.new(
          path: "M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z",
          size: "h-6 w-6",
          color: "text-indigo-600"
        )

        # Build lock icon
        lock_icon = Shared::IconComponent.new(
          path: "M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z",
          size: "h-5 w-5",
          color: "text-indigo-500 group-hover:text-indigo-400"
        )

        # Determine error classes
        email_error_class = errors.has_key?("email") ? "border-red-300 focus:ring-red-500 focus:border-red-500" : "border-gray-300 focus:ring-indigo-500 focus:border-indigo-500"
        password_error_class = errors.has_key?("password") ? "border-red-300 focus:ring-red-500 focus:border-red-500" : "border-gray-300 focus:ring-indigo-500 focus:border-indigo-500"

        # Build HTML
        String.build do |html|
          html << "<div class=\"min-h-full flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8\">"
          html << "<div class=\"max-w-md w-full space-y-8\">"

          # Header
          html << "<div>"
          html << "<div class=\"mx-auto h-12 w-12 flex items-center justify-center rounded-full bg-indigo-100\">"
          html << user_icon.render
          html << "</div>"
          html << "<h2 class=\"mt-6 text-center text-3xl font-extrabold text-gray-900\">Sign in to your account</h2>"
          html << "<p class=\"mt-2 text-center text-sm text-gray-600\">Welcome back! Please enter your credentials to continue.</p>"
          html << "</div>"

          # Error message from server
          if !error_message.empty?
            html << "<div class=\"rounded-md bg-red-50 p-4\" role=\"alert\">"
            html << "<div class=\"flex\">"
            html << "<div class=\"flex-shrink-0\">"
            html << "<svg class=\"h-5 w-5 text-red-400\" viewBox=\"0 0 20 20\" fill=\"currentColor\">"
            html << "<path fill-rule=\"evenodd\" d=\"M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z\" clip-rule=\"evenodd\" />"
            html << "</svg>"
            html << "</div>"
            html << "<div class=\"ml-3\">"
            html << "<p class=\"text-sm font-medium text-red-800\">#{error_message}</p>"
            html << "</div>"
            html << "</div>"
            html << "</div>"
          end

          # Form
          html << "<form class=\"mt-8 space-y-6\" action=\"#{action}\" method=\"POST\" data-controller=\"login\" data-action=\"submit->login#handleSubmit\">"

          # CSRF token
          html << "<input type=\"hidden\" name=\"authenticity_token\" value=\"#{csrf_token}\">"
          html << "<input type=\"hidden\" name=\"remember\" value=\"true\">"

          # Form fields
          html << "<div class=\"rounded-md shadow-sm -space-y-px\">"

          # Email field
          html << "<div>"
          html << "<label for=\"email\" class=\"sr-only\">Email address</label>"
          html << "<input id=\"email\" name=\"email\" type=\"email\" autocomplete=\"email\" required "
          html << "class=\"appearance-none rounded-none relative block w-full px-3 py-2 border #{email_error_class} placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:z-10 sm:text-sm\" "
          html << "placeholder=\"Email address\" "
          html << "value=\"#{email}\" "
          html << "data-login-target=\"email\" data-action=\"input->login#handleInput\">"
          if errors.has_key?("email")
            html << "<p class=\"mt-1 text-sm text-red-600\">#{errors["email"].as_s}</p>"
          end
          html << "</div>"

          # Password field
          html << "<div>"
          html << "<label for=\"password\" class=\"sr-only\">Password</label>"
          html << "<input id=\"password\" name=\"password\" type=\"password\" autocomplete=\"current-password\" required "
          html << "class=\"appearance-none rounded-none relative block w-full px-3 py-2 border #{password_error_class} placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:z-10 sm:text-sm\" "
          html << "placeholder=\"Password\" "
          html << "data-login-target=\"password\" data-action=\"input->login#handleInput\">"
          if errors.has_key?("password")
            html << "<p class=\"mt-1 text-sm text-red-600\">#{errors["password"].as_s}</p>"
          end
          html << "</div>"

          html << "</div>"

          # Remember me and forgot password
          html << "<div class=\"flex items-center justify-between\">"
          html << "<div class=\"flex items-center\">"
          html << "<input id=\"remember-me\" name=\"remember-me\" type=\"checkbox\" class=\"h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded\">"
          html << "<label for=\"remember-me\" class=\"ml-2 block text-sm text-gray-900\">Remember me</label>"
          html << "</div>"
          html << "<div class=\"text-sm\">"
          html << "<a href=\"#\" class=\"font-medium text-indigo-600 hover:text-indigo-500\">Forgot your password?</a>"
          html << "</div>"
          html << "</div>"

          # Submit button
          html << "<div>"
          disabled_attr = submitting ? "disabled" : ""
          html << "<button type=\"submit\" #{disabled_attr} "
          html << "class=\"group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200\" "
          html << "data-login-target=\"submitButton\">"
          html << "<span class=\"absolute left-0 inset-y-0 flex items-center pl-3\">"
          html << lock_icon.render
          html << "</span>"
          html << (submitting ? "Signing in..." : "Sign in")
          html << "</button>"
          html << "</div>"

          # Sign up link
          html << "<div class=\"text-center\">"
          html << "<p class=\"text-sm text-gray-600\">"
          html << "Don't have an account? "
          html << "<a href=\"#\" class=\"font-medium text-indigo-600 hover:text-indigo-500\">Sign up here</a>"
          html << "</p>"
          html << "</div>"

          html << "</form>"
          html << "</div>"
          html << "</div>"
        end
      end

      def css_selector : String
        ".min-h-full.flex.items-center.justify-center"
      end
    end
  end
end
