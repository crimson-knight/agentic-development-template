require "./application_mailer"
require "../views/components/layouts/mailer_layout"

# Component-based emails. Build the message via Quartz::Composer's delegated
# `to`/`subject`/`html` setters, then `.deliver` to send (SMTP configured via
# config/initializers/mailer.cr + env). Each builder returns `self` so callers
# can chain `.deliver`.
#
#   UserMailer.new.welcome_email(user.email, user.email).deliver
class UserMailer < ApplicationMailer
  def welcome_email(user_email : String, user_name : String) : self
    content = String.build do |html|
      html << "<h2 style=\"color:#1f2937;margin-bottom:16px;\">Welcome, #{HTML.escape(user_name)}!</h2>"
      html << "<p style=\"margin-bottom:12px;\">Thanks for signing up. We're excited to have you on board.</p>"
      html << "<p style=\"margin-bottom:20px;\">Get started by exploring your dashboard.</p>"
    end
    layout = Components::Layouts::MailerLayout.new(
      title: "Welcome", content: content, preheader: "Welcome! Let's get you started."
    )
    to address(email: user_email, name: user_name)
    subject "Welcome!"
    html layout.render
    self
  end

  def password_reset_email(user_email : String, user_name : String, reset_token : String) : self
    reset_url = "#{base_url}/reset-password?token=#{reset_token}"
    content = String.build do |html|
      html << "<h2 style=\"color:#1f2937;margin-bottom:16px;\">Reset your password</h2>"
      html << "<p style=\"margin-bottom:12px;\">Hi #{HTML.escape(user_name)},</p>"
      html << "<p style=\"margin-bottom:20px;\">Click below to reset your password (link expires in 2 hours):</p>"
      html << "<p><a href=\"#{reset_url}\">Reset Password</a></p>"
    end
    layout = Components::Layouts::MailerLayout.new(
      title: "Reset Your Password", content: content, preheader: "Reset your password"
    )
    to address(email: user_email, name: user_name)
    subject "Reset your password"
    html layout.render
    self
  end

  def verification_email(user_email : String, user_name : String, verification_token : String) : self
    verify_url = "#{base_url}/verify?token=#{verification_token}"
    content = String.build do |html|
      html << "<h2 style=\"color:#1f2937;margin-bottom:16px;\">Verify your email</h2>"
      html << "<p style=\"margin-bottom:12px;\">Hi #{HTML.escape(user_name)},</p>"
      html << "<p style=\"margin-bottom:20px;\">Please verify your email to activate your account:</p>"
      html << "<p><a href=\"#{verify_url}\">Verify Email</a></p>"
    end
    layout = Components::Layouts::MailerLayout.new(
      title: "Verify Your Email", content: content, preheader: "Verify your email address"
    )
    to address(email: user_email, name: user_name)
    subject "Verify your email"
    html layout.render
    self
  end

  private def base_url : String
    ENV["APP_URL"]? || "http://localhost:3000"
  end
end
