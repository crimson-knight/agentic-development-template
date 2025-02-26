# Mailer Template

Use this template to create a new mailer class. Replace placeholder values as needed.

```crystal
# src/mailers/{{mailer_name}}_mailer.cr
class {{mailer_name}}Mailer < ApplicationMailer
  def initialize
    # Configure default email settings
    to "recipient@example.com"  # This should be changed to the actual recipient
    subject "Example Subject"   # Can use string interpolation for dynamic subjects
    
    # Render both HTML and text versions of the email
    text render("mailers/{{mailer_name}}_mailer.txt.ecr")
    html render("mailers/{{mailer_name}}_mailer.html.ecr", "mailer.ecr")
  end

  # Add custom methods for different email types
  def welcome_email(user)
    to user.email
    subject "Welcome to Our Application"
    # You can set other email attributes here
  end

  def notification_email(user, message)
    to user.email
    subject "New Notification"
    # Pass variables to the templates
    text render("mailers/{{mailer_name}}_mailer.txt.ecr", message: message)
    html render("mailers/{{mailer_name}}_mailer.html.ecr", "mailer.ecr", message: message)
  end
end
``` 