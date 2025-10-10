require "./application_mailer"
require "../views/components/layouts/mailer_layout"

# Example mailer demonstrating component-based email rendering
#
# Usage:
#   UserMailer.new.welcome_email(user)
#   UserMailer.new.password_reset_email(user, token)
#
# Note: This uses the MailerLayout component instead of ECR templates
# for type-safe, testable email rendering.
class UserMailer < ApplicationMailer
  # Welcome email sent to new users
  def welcome_email(user_email : String, user_name : String)
    # Build email content using components or HTML
    email_content = String.build do |html|
      html << "<h2 style=\"color: #1f2937; margin-bottom: 16px;\">Welcome to AgentC, #{user_name}!</h2>"
      html << "<p style=\"margin-bottom: 12px;\">Thanks for signing up. We're excited to have you on board.</p>"
      html << "<p style=\"margin-bottom: 20px;\">Get started by exploring our features and setting up your account.</p>"
      html << "<p style=\"margin-top: 20px;\">"
      html << "<a href=\"https://example.com/get-started\" style=\"background-color: #4f46e5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block; font-weight: 500;\">Get Started</a>"
      html << "</p>"
    end

    # Wrap content in MailerLayout component
    mailer_layout = Components::Layouts::MailerLayout.new(
      title: "Welcome to AgentC",
      content: email_content,
      preheader: "Welcome! Let's get you started."
    )

    # Send email with component-rendered HTML
    email do
      to address(email: user_email, name: user_name)
      subject "Welcome to AgentC!"
      html mailer_layout.render
    end
  end

  # Password reset email with token link
  def password_reset_email(user_email : String, user_name : String, reset_token : String)
    # Build reset URL
    reset_url = "https://example.com/reset-password?token=#{reset_token}"

    # Build email content
    email_content = String.build do |html|
      html << "<h2 style=\"color: #1f2937; margin-bottom: 16px;\">Reset Your Password</h2>"
      html << "<p style=\"margin-bottom: 12px;\">Hi #{user_name},</p>"
      html << "<p style=\"margin-bottom: 12px;\">We received a request to reset your password.</p>"
      html << "<p style=\"margin-bottom: 20px;\">Click the button below to reset it:</p>"
      html << "<p style=\"margin: 20px 0;\">"
      html << "<a href=\"#{reset_url}\" style=\"background-color: #4f46e5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block; font-weight: 500;\">Reset Password</a>"
      html << "</p>"
      html << "<p style=\"margin-top: 24px; padding-top: 20px; border-top: 1px solid #e5e7eb; font-size: 13px; color: #6b7280;\">"
      html << "If you didn't request this, you can safely ignore this email. Your password won't be changed."
      html << "</p>"
      html << "<p style=\"font-size: 13px; color: #6b7280; margin-top: 12px;\">"
      html << "This link will expire in 2 hours for security reasons."
      html << "</p>"
    end

    # Wrap content in MailerLayout component
    mailer_layout = Components::Layouts::MailerLayout.new(
      title: "Reset Your Password",
      content: email_content,
      preheader: "Click to reset your password"
    )

    # Send email
    email do
      to address(email: user_email, name: user_name)
      subject "Reset Your Password - AgentC"
      html mailer_layout.render
    end
  end

  # Account verification email
  def verification_email(user_email : String, user_name : String, verification_token : String)
    # Build verification URL
    verification_url = "https://example.com/verify?token=#{verification_token}"

    # Build email content
    email_content = String.build do |html|
      html << "<h2 style=\"color: #1f2937; margin-bottom: 16px;\">Verify Your Email Address</h2>"
      html << "<p style=\"margin-bottom: 12px;\">Hi #{user_name},</p>"
      html << "<p style=\"margin-bottom: 12px;\">Thanks for signing up! Please verify your email address to activate your account.</p>"
      html << "<p style=\"margin: 20px 0;\">"
      html << "<a href=\"#{verification_url}\" style=\"background-color: #10b981; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block; font-weight: 500;\">Verify Email Address</a>"
      html << "</p>"
      html << "<p style=\"margin-top: 24px; font-size: 13px; color: #6b7280;\">"
      html << "Or copy and paste this link into your browser:"
      html << "</p>"
      html << "<p style=\"font-size: 13px; color: #4f46e5; word-break: break-all;\">"
      html << verification_url
      html << "</p>"
    end

    # Wrap content in MailerLayout component
    mailer_layout = Components::Layouts::MailerLayout.new(
      title: "Verify Your Email",
      content: email_content,
      preheader: "Please verify your email address"
    )

    # Send email
    email do
      to address(email: user_email, name: user_name)
      subject "Verify Your Email - AgentC"
      html mailer_layout.render
    end
  end
end
