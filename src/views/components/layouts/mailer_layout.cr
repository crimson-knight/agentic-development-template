require "../../../../lib/asset_pipeline/src/components/base/stateless_component"

module Components
  module Layouts
    # Email layout component with inline styles for email client compatibility
    #
    # Usage:
    #   mailer = MailerLayout.new(
    #     title: "Welcome Email",
    #     content: email_body_html,
    #     preheader: "Welcome to AgentC!"
    #   )
    #   mailer.render
    #
    # Attributes:
    #   - title: Email title (default: "AgentC")
    #   - content: HTML content for email body (required)
    #   - preheader: Preview text shown in email clients (optional)
    #   - brand_name: Brand name in header (default: "AgentC")
    #   - brand_color: Header background color (default: "#4f46e5")
    #   - year: Copyright year (default: current year)
    class MailerLayout < StatelessComponent
      def render_content : String
        # Extract attributes
        title = @attributes["title"]? || "AgentC"
        content = @attributes["content"]? || ""
        preheader = @attributes["preheader"]? || "AgentC - Your SaaS Application"
        brand_name = @attributes["brand_name"]? || "AgentC"
        brand_color = @attributes["brand_color"]? || "#4f46e5"
        year = @attributes["year"]? || Time.local.year.to_s

        # Build email HTML with inline styles for email client compatibility
        String.build do |html|
          # DOCTYPE and HTML opening with email-specific namespaces
          html << "<!DOCTYPE html>\n"
          html << "<html lang=\"en\" xmlns=\"http://www.w3.org/1999/xhtml\" xmlns:v=\"urn:schemas-microsoft-com:vml\" xmlns:o=\"urn:schemas-microsoft-com:office:office\">\n"
          html << "<head>\n"
          html << "  <meta charset=\"utf-8\">\n"
          html << "  <meta name=\"viewport\" content=\"width=device-width\">\n"
          html << "  <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">\n"
          html << "  <meta name=\"x-apple-disable-message-reformatting\">\n"
          html << "  <title>#{title}</title>\n"
          html << "  \n"

          # Inline styles for email compatibility
          html << "  <style>\n"
          html << "    html, body {\n"
          html << "      margin: 0 auto !important;\n"
          html << "      padding: 0 !important;\n"
          html << "      height: 100% !important;\n"
          html << "      width: 100% !important;\n"
          html << "      background: #f1f1f1;\n"
          html << "    }\n"
          html << "    \n"
          html << "    * {\n"
          html << "      -ms-text-size-adjust: 100%;\n"
          html << "      -webkit-text-size-adjust: 100%;\n"
          html << "    }\n"
          html << "    \n"
          html << "    table, td {\n"
          html << "      mso-table-lspace: 0pt !important;\n"
          html << "      mso-table-rspace: 0pt !important;\n"
          html << "    }\n"
          html << "    \n"
          html << "    table {\n"
          html << "      border-spacing: 0 !important;\n"
          html << "      border-collapse: collapse !important;\n"
          html << "      table-layout: fixed !important;\n"
          html << "      margin: 0 auto !important;\n"
          html << "    }\n"
          html << "    \n"
          html << "    .email-container {\n"
          html << "      max-width: 600px;\n"
          html << "      margin: 0 auto;\n"
          html << "      background: #ffffff;\n"
          html << "    }\n"
          html << "    \n"
          html << "    .email-header {\n"
          html << "      background: #{brand_color};\n"
          html << "      padding: 20px;\n"
          html << "      text-align: center;\n"
          html << "    }\n"
          html << "    \n"
          html << "    .email-content {\n"
          html << "      padding: 40px 20px;\n"
          html << "    }\n"
          html << "    \n"
          html << "    .email-footer {\n"
          html << "      background: #f9fafb;\n"
          html << "      padding: 20px;\n"
          html << "      text-align: center;\n"
          html << "      border-top: 1px solid #e5e7eb;\n"
          html << "    }\n"
          html << "  </style>\n"
          html << "</head>\n"
          html << "<body>\n"

          # Center wrapper with background
          html << "  <center style=\"width: 100%; background-color: #f1f1f1;\">\n"

          # Preheader (hidden text for email preview)
          html << "    <div style=\"display: none; font-size: 1px; max-height: 0px; max-width: 0px; opacity: 0; overflow: hidden; mso-hide: all; font-family: sans-serif;\">\n"
          html << "      #{preheader}\n"
          html << "    </div>\n"
          html << "    \n"

          # Email container
          html << "    <div style=\"max-width: 600px; margin: 0 auto;\" class=\"email-container\">\n"

          # Header table
          html << "      <!-- Header -->\n"
          html << "      <table align=\"center\" role=\"presentation\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\" width=\"100%\" style=\"margin: auto;\">\n"
          html << "        <tr>\n"
          html << "          <td style=\"padding: 20px 0; text-align: center; background-color: #{brand_color};\">\n"
          html << "            <h1 style=\"margin: 0; font-family: sans-serif; font-size: 24px; line-height: 30px; color: #ffffff; font-weight: bold;\">\n"
          html << "              #{brand_name}\n"
          html << "            </h1>\n"
          html << "          </td>\n"
          html << "        </tr>\n"
          html << "      </table>\n"
          html << "      \n"

          # Main content table
          html << "      <!-- Main Content -->\n"
          html << "      <table align=\"center\" role=\"presentation\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\" width=\"100%\" style=\"margin: auto;\">\n"
          html << "        <tr>\n"
          html << "          <td style=\"padding: 40px 20px; font-family: sans-serif; font-size: 15px; line-height: 20px; color: #555555; background-color: #ffffff;\">\n"
          html << "            #{content}\n"
          html << "          </td>\n"
          html << "        </tr>\n"
          html << "      </table>\n"
          html << "      \n"

          # Footer table
          html << "      <!-- Footer -->\n"
          html << "      <table align=\"center\" role=\"presentation\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\" width=\"100%\" style=\"margin: auto;\">\n"
          html << "        <tr>\n"
          html << "          <td style=\"padding: 20px; font-family: sans-serif; font-size: 12px; line-height: 15px; text-align: center; color: #888888; background-color: #f9fafb; border-top: 1px solid #e5e7eb;\">\n"
          html << "            <p style=\"margin: 0;\">\n"
          html << "              © #{year} #{brand_name}. All rights reserved.<br>\n"
          html << "              You're receiving this email because you have an account with us.\n"
          html << "            </p>\n"
          html << "          </td>\n"
          html << "        </tr>\n"
          html << "      </table>\n"
          html << "    </div>\n"
          html << "  </center>\n"
          html << "</body>\n"
          html << "</html>\n"
        end
      end

      def css_selector : String
        ".email-container"
      end
    end
  end
end
