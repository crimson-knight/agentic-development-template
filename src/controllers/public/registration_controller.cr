require "html"
require "../../views/components/layouts/application_layout"
require "../../mailers/user_mailer"

# Public sign-up. GET /signup renders the form; POST /signup validates,
# creates a Users::Regular, sends a (best-effort) welcome email, logs the
# user in, and redirects to the dashboard.
class Public::RegistrationController < ApplicationController
  def new
    render_form
  end

  def create
    email = (params["email"]? || "").strip
    password = params["password"]? || ""
    confirmation = params["password_confirmation"]? || ""

    if err = client_validate(email, password, confirmation)
      flash[:danger] = err
      return render_form(email, err)
    end

    user = Users::Regular.new
    user.email = email
    user.password = password

    if user.save
      send_welcome_email(user)
      session[:user_id] = user.id
      session[:user_type] = "regular"
      flash[:success] = "Welcome! Your account has been created."
      redirect_to "/dashboard"
    else
      msg = user.errors.map(&.message).join(", ")
      flash[:danger] = "Could not create account: #{msg}"
      render_form(email, msg)
    end
  rescue ex
    Log.error { "signup error: #{ex.message}" }
    flash[:danger] = "Something went wrong. Please try again."
    redirect_to "/signup"
  end

  # --- helpers --------------------------------------------------------------

  private def client_validate(email, password, confirmation) : String?
    return "Email is required" if email.empty?
    return "Please enter a valid email address" unless email =~ /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
    return "Password must be at least 8 characters" if password.size < 8
    return "Passwords do not match" if password != confirmation
    nil
  end

  private def send_welcome_email(user)
    mailer = UserMailer.new.welcome_email(user.email, user.email)
    mailer.deliver unless ENV["AMBER_ENV"]? == "test"
  rescue ex
    Log.warn { "welcome email not sent: #{ex.message}" }
  end

  private def render_form(email_value : String? = nil, error : String? = nil)
    layout = Components::Layouts::ApplicationLayout.new(
      title: "Sign Up - AgentC",
      content: form_html(csrf_token, email_value, error),
      current_path: request.path,
      logged_in: "false",
      flash_error: flash[:danger]?,
      flash_info: flash[:info]?
    )
    context.response.content_type = "text/html"
    context.response.print layout.render
  end

  private def form_html(token : String, email_value : String?, error : String?) : String
    String.build do |html|
      html << "<div data-component=\"signup-form\" class=\"min-h-full flex items-center justify-center py-12 px-4\">"
      html << "<div class=\"max-w-md w-full space-y-8\">"
      html << "<div><h2 class=\"mt-6 text-center text-3xl font-extrabold text-gray-900\">Create your account</h2>"
      html << "<p class=\"mt-2 text-center text-sm text-gray-600\">Already have an account? <a href=\"/login\" class=\"font-medium text-indigo-600 hover:text-indigo-500\">Sign in</a></p></div>"
      if err = error
        html << "<div class=\"rounded-md bg-red-50 p-4\" role=\"alert\"><p class=\"text-sm font-medium text-red-800\">#{HTML.escape(err)}</p></div>"
      end
      html << "<form class=\"mt-8 space-y-6\" action=\"/signup\" method=\"POST\">"
      html << "<input type=\"hidden\" name=\"_csrf\" value=\"#{token}\">"
      html << "<div class=\"rounded-md shadow-sm space-y-2\">"
      html << field("email", "email", "Email address", HTML.escape(email_value || ""), "email")
      html << field("password", "password", "Password (min 8 characters)", "", "new-password")
      html << field("password_confirmation", "password", "Confirm password", "", "new-password")
      html << "</div>"
      html << "<button type=\"submit\" class=\"group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700\">Create account</button>"
      html << "</form></div></div>"
    end
  end

  private def field(name : String, type : String, placeholder : String, value : String, autocomplete : String) : String
    "<div><label for=\"#{name}\" class=\"sr-only\">#{placeholder}</label>" \
    "<input id=\"#{name}\" name=\"#{name}\" type=\"#{type}\" autocomplete=\"#{autocomplete}\" required " \
    "value=\"#{value}\" placeholder=\"#{placeholder}\" " \
    "class=\"appearance-none rounded relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm\"></div>"
  end
end
