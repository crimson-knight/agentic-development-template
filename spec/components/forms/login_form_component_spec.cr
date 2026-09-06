require "../component_spec_helper"
require "../../../src/views/components/forms/login_form_component"

describe Components::Forms::LoginFormComponent do
  describe "initialization" do
    it "initializes with empty state" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")

      form.get_state("email").try(&.as_s?).should eq("")
      form.get_state("password").try(&.as_s?).should eq("")
      form.get_state("submitting").try(&.as_bool?).should eq(false)
    end

    it "initializes with pre-filled email" do
      form = Components::Forms::LoginFormComponent.new(
        csrf_token: "test-token",
        email_value: "user@example.com"
      )

      form.get_state("email").try(&.as_s?).should eq("user@example.com")
    end

    it "initializes with error message" do
      form = Components::Forms::LoginFormComponent.new(
        csrf_token: "test-token",
        error_message: "Invalid credentials"
      )

      form.get_state("error_message").try(&.as_s?).should eq("Invalid credentials")
    end
  end

  describe "rendering" do
    it "renders login form" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")
      rendered = form.render

      rendered.should contain("Sign in to your account")
      rendered.should contain("Email address")
      rendered.should contain("Password")
      rendered.should contain("Sign in")
    end

    it "includes CSRF token" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "abc123")
      rendered = form.render

      # Both installed and current Amber V2 CSRF pipes read PARAM_KEY=_csrf.
      rendered.should contain("name=\"_csrf\"")
      rendered.should_not contain("name=\"authenticity_token\"")
      rendered.should contain("value=\"abc123\"")
    end

    it "includes Stimulus controller" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")
      rendered = form.render

      rendered.should contain("data-controller=\"login\"")
      rendered.should contain("data-action=\"submit->login#handleSubmit\"")
    end

    it "pre-fills email when provided" do
      form = Components::Forms::LoginFormComponent.new(
        csrf_token: "test-token",
        email_value: "test@example.com"
      )
      rendered = form.render

      rendered.should contain("value=\"test@example.com\"")
    end

    it "displays error message from server" do
      form = Components::Forms::LoginFormComponent.new(
        csrf_token: "test-token",
        error_message: "Invalid email or password"
      )
      rendered = form.render

      rendered.should contain("Invalid email or password")
      rendered.should contain("bg-red-50")
    end

    it "does not display error when no message" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")
      rendered = form.render

      rendered.should_not contain("bg-red-50")
    end

    it "renders remember me checkbox" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")
      rendered = form.render

      rendered.should contain("remember-me")
      rendered.should contain("Remember me")
    end

    it "renders forgot password link" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")
      rendered = form.render

      rendered.should contain("Forgot your password?")
    end

    it "renders sign up link" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")
      rendered = form.render

      rendered.should contain("Don't have an account?")
      rendered.should contain("Sign up here")
    end

    it "shows submitting state" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")
      form.set_submitting(true)
      rendered = form.render

      rendered.should contain("Signing in...")
      rendered.should contain("disabled")
    end
  end

  describe "validation" do
    it "validates empty email" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")
      form.set_email("")

      form.valid?.should eq(false)
      errors = form.validate
      errors.has_key?("email").should eq(true)
      errors["email"].as_s.should eq("Email is required")
    end

    it "validates invalid email format" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")
      form.set_email("invalid-email")

      form.valid?.should eq(false)
      errors = form.validate
      errors.has_key?("email").should eq(true)
      errors["email"].as_s.should eq("Invalid email format")
    end

    it "validates empty password" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")
      form.set_email("user@example.com")
      form.set_password("")

      form.valid?.should eq(false)
      errors = form.validate
      errors.has_key?("password").should eq(true)
      errors["password"].as_s.should eq("Password is required")
    end

    it "validates short password" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")
      form.set_email("user@example.com")
      form.set_password("12345")

      form.valid?.should eq(false)
      errors = form.validate
      errors.has_key?("password").should eq(true)
      errors["password"].as_s.should eq("Password must be at least 6 characters")
    end

    it "validates valid credentials" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")
      form.set_email("user@example.com")
      form.set_password("password123")

      form.valid?.should eq(true)
      form.validate.should be_empty
    end

    it "displays email validation errors" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")
      form.set_email("invalid")
      rendered = form.render

      rendered.should contain("Invalid email format")
      rendered.should contain("text-red-600")
      rendered.should contain("border-red-300")
    end

    it "displays password validation errors" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")
      form.set_email("user@example.com")
      form.set_password("123")
      rendered = form.render

      rendered.should contain("Password must be at least 6 characters")
      rendered.should contain("text-red-600")
    end
  end

  describe "state management" do
    it "updates email state" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")

      form.set_email("test@example.com")
      form.get_state("email").try(&.as_s?).should eq("test@example.com")
      form.changed?.should eq(true)
    end

    it "updates password state" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")

      form.set_password("secret123")
      form.get_state("password").try(&.as_s?).should eq("secret123")
      form.changed?.should eq(true)
    end

    it "updates submitting state" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")

      form.set_submitting(true)
      form.get_state("submitting").try(&.as_bool?).should eq(true)
      form.changed?.should eq(true)
    end

    it "updates error message" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")

      form.set_error_message("Login failed")
      form.get_state("error_message").try(&.as_s?).should eq("Login failed")
      form.changed?.should eq(true)
    end

    it "tracks multiple state changes" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")

      form.set_email("user@example.com")
      form.set_password("password123")
      form.set_submitting(true)

      form.get_state("email").try(&.as_s?).should eq("user@example.com")
      form.get_state("password").try(&.as_s?).should eq("password123")
      form.get_state("submitting").try(&.as_bool?).should eq(true)
      form.changed?.should eq(true)
    end
  end

  describe "email validation method" do
    it "validates correct email formats" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")

      form.validate_email("user@example.com").should eq(true)
      form.validate_email("test.user@example.co.uk").should eq(true)
      form.validate_email("user+tag@example.com").should eq(true)
    end

    it "rejects invalid email formats" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")

      form.validate_email("invalid").should eq(false)
      form.validate_email("@example.com").should eq(false)
      form.validate_email("user@").should eq(false)
      form.validate_email("user @example.com").should eq(false)
    end
  end

  describe "user flow scenarios" do
    it "simulates successful login attempt" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")

      # User enters email
      form.set_email("user@example.com")
      form.valid?.should eq(false) # Password not entered yet

      # User enters password
      form.set_password("password123")
      form.valid?.should eq(true) # Now valid

      # User submits form
      form.set_submitting(true)
      rendered = form.render
      rendered.should contain("Signing in...")
      rendered.should contain("disabled")
    end

    it "simulates failed login with invalid credentials" do
      form = Components::Forms::LoginFormComponent.new(
        csrf_token: "test-token",
        email_value: "wrong@example.com",
        error_message: "Invalid email or password"
      )

      rendered = form.render
      rendered.should contain("Invalid email or password")
      rendered.should contain("value=\"wrong@example.com\"") # Email preserved
    end

    it "simulates failed login with non-existent user" do
      form = Components::Forms::LoginFormComponent.new(
        csrf_token: "test-token",
        email_value: "nonexistent@example.com",
        error_message: "User not found"
      )

      rendered = form.render
      rendered.should contain("User not found")
      rendered.should contain("bg-red-50")
    end

    it "simulates validation errors before submission" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")

      # User enters invalid email
      form.set_email("bad-email")
      form.valid?.should eq(false)

      # Render shows validation error
      rendered = form.render
      rendered.should contain("Invalid email format")

      # User corrects email
      form.set_email("good@example.com")

      # User enters short password
      form.set_password("123")
      form.valid?.should eq(false)

      # Render shows password error
      rendered = form.render
      rendered.should contain("Password must be at least 6 characters")

      # User corrects password
      form.set_password("password123")
      form.valid?.should eq(true)
    end
  end

  describe "css_selector" do
    it "returns correct selector" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")

      form.css_selector.should eq(".min-h-full.flex.items-center.justify-center")
    end
  end

  describe "not cacheable" do
    it "is not cacheable (stateful component)" do
      form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")

      form.cacheable?.should eq(false)
    end
  end
end
