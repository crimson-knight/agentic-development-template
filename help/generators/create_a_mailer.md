# Create A Mailer

## Prerequisites

Required:
- The name of the mailer
- The purpose of the email (welcome, notification, etc.)

Optional:
- Email template content for HTML and text versions
- Subject line template
- Default recipient information
- Any dynamic content requirements

Review the information that you have been provided to ensure it includes all of the required information.
If there is any missing information or vague information, prompt the user for the missing information before proceeding.

## Steps

1. Create the mailer file in `src/mailers` directory
   - The file should be named with the pattern `{mailer_name}_mailer.cr`
   - Define a class that inherits from `ApplicationMailer`
   - Include an initialize method with default email settings
   - Add any specific email methods needed (welcome_email, notification_email, etc.)

2. Create the email template views in `src/views/mailers` directory
   - Create an HTML template with the `.html.ecr` extension
   - Create a plain text template with the `.txt.ecr` extension
   - Both templates should have the same base filename as the mailer

3. Test the mailer by creating a simple controller action that sends an email
   - Ensure the mailer can be initialized
   - Ensure the templates are properly rendered
   - Verify email delivery settings are properly configured

For specific implementation details, see the template examples in `help/generators/templates/create_a_mailer/`.

## Email Configuration

1. Configure the email delivery settings in `config/environments/{environment}.yml`
   - Set SMTP server details
   - Set default sender address
   - Configure delivery method

2. If using environment variables for sensitive information:
   - Add placeholder values in configuration files
   - Document required environment variables
   - Use proper secrets management for production

## Important Notes

1. Email HTML content should be designed for email client compatibility
   - Use inline CSS where possible
   - Test with major email clients
   - Include a plain text alternative for all emails

2. For development environments, consider using a tool like Mailhog or Mailtrap
   - Prevents accidental email sending to real addresses
   - Provides a UI for inspecting sent emails
   - Easy to set up with Docker 