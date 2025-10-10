require "../component_spec_helper"
require "../../../src/views/components/layouts/mailer_layout"

describe Components::Layouts::MailerLayout do
  describe "rendering" do
    it "renders email layout with default attributes" do
      mailer = Components::Layouts::MailerLayout.new(
        content: "<p>Test email content</p>"
      )
      rendered = mailer.render

      rendered.should contain("<!DOCTYPE html>")
      rendered.should contain("<html lang=\"en\"")
      rendered.should contain("Test email content")
    end

    it "includes email-specific DOCTYPE and namespaces" do
      mailer = Components::Layouts::MailerLayout.new(content: "Content")
      rendered = mailer.render

      rendered.should contain("xmlns=\"http://www.w3.org/1999/xhtml\"")
      rendered.should contain("xmlns:v=\"urn:schemas-microsoft-com:vml\"")
      rendered.should contain("xmlns:o=\"urn:schemas-microsoft-com:office:office\"")
    end

    it "includes required meta tags for email clients" do
      mailer = Components::Layouts::MailerLayout.new(content: "Content")
      rendered = mailer.render

      rendered.should contain("<meta charset=\"utf-8\">")
      rendered.should contain("<meta name=\"viewport\" content=\"width=device-width\">")
      rendered.should contain("<meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">")
      rendered.should contain("<meta name=\"x-apple-disable-message-reformatting\">")
    end

    it "renders with custom title" do
      mailer = Components::Layouts::MailerLayout.new(
        title: "Welcome Email",
        content: "Content"
      )
      rendered = mailer.render

      rendered.should contain("<title>Welcome Email</title>")
    end

    it "renders with default title" do
      mailer = Components::Layouts::MailerLayout.new(content: "Content")
      rendered = mailer.render

      rendered.should contain("<title>AgentC</title>")
    end

    it "includes preheader text" do
      mailer = Components::Layouts::MailerLayout.new(
        content: "Content",
        preheader: "This is preview text"
      )
      rendered = mailer.render

      rendered.should contain("This is preview text")
      rendered.should contain("display: none")
      rendered.should contain("mso-hide: all")
    end

    it "uses default preheader" do
      mailer = Components::Layouts::MailerLayout.new(content: "Content")
      rendered = mailer.render

      rendered.should contain("AgentC - Your SaaS Application")
    end

    it "renders brand name in header" do
      mailer = Components::Layouts::MailerLayout.new(
        content: "Content",
        brand_name: "MyBrand"
      )
      rendered = mailer.render

      rendered.should contain("<h1")
      rendered.should contain("MyBrand")
    end

    it "uses default brand name" do
      mailer = Components::Layouts::MailerLayout.new(content: "Content")
      rendered = mailer.render

      rendered.should contain("AgentC")
    end

    it "applies custom brand color" do
      mailer = Components::Layouts::MailerLayout.new(
        content: "Content",
        brand_color: "#ff0000"
      )
      rendered = mailer.render

      rendered.should contain("background-color: #ff0000")
      rendered.should contain("background: #ff0000")
    end

    it "uses default brand color" do
      mailer = Components::Layouts::MailerLayout.new(content: "Content")
      rendered = mailer.render

      rendered.should contain("background: #4f46e5")
    end

    it "includes copyright year in footer" do
      mailer = Components::Layouts::MailerLayout.new(
        content: "Content",
        year: "2025"
      )
      rendered = mailer.render

      rendered.should contain("© 2025")
    end

    it "uses current year by default" do
      mailer = Components::Layouts::MailerLayout.new(content: "Content")
      rendered = mailer.render
      current_year = Time.local.year.to_s

      rendered.should contain("© #{current_year}")
    end

    it "includes email content in main section" do
      mailer = Components::Layouts::MailerLayout.new(
        content: "<h2>Welcome!</h2><p>Thanks for signing up.</p>"
      )
      rendered = mailer.render

      rendered.should contain("<h2>Welcome!</h2>")
      rendered.should contain("<p>Thanks for signing up.</p>")
    end
  end

  describe "email compatibility" do
    it "includes inline styles for email clients" do
      mailer = Components::Layouts::MailerLayout.new(content: "Content")
      rendered = mailer.render

      rendered.should contain("<style>")
      rendered.should contain("margin: 0 auto !important")
      rendered.should contain("-ms-text-size-adjust")
      rendered.should contain("-webkit-text-size-adjust")
    end

    it "uses table-based layout" do
      mailer = Components::Layouts::MailerLayout.new(content: "Content")
      rendered = mailer.render

      rendered.should contain("<table")
      rendered.should contain("role=\"presentation\"")
      rendered.should contain("cellspacing=\"0\"")
      rendered.should contain("cellpadding=\"0\"")
      rendered.should contain("border=\"0\"")
    end

    it "includes MSO-specific styles" do
      mailer = Components::Layouts::MailerLayout.new(content: "Content")
      rendered = mailer.render

      rendered.should contain("mso-table-lspace")
      rendered.should contain("mso-table-rspace")
      rendered.should contain("mso-hide: all")
    end

    it "centers content for email clients" do
      mailer = Components::Layouts::MailerLayout.new(content: "Content")
      rendered = mailer.render

      rendered.should contain("<center")
      rendered.should contain("width: 100%")
      rendered.should contain("max-width: 600px")
    end

    it "includes email-specific CSS classes" do
      mailer = Components::Layouts::MailerLayout.new(content: "Content")
      rendered = mailer.render

      rendered.should contain("email-container")
      rendered.should contain("email-header")
      rendered.should contain("email-content")
      rendered.should contain("email-footer")
    end
  end

  describe "structure" do
    it "has proper HTML structure" do
      mailer = Components::Layouts::MailerLayout.new(content: "Content")
      rendered = mailer.render

      rendered.should contain("<!DOCTYPE html>")
      rendered.should contain("<html")
      rendered.should contain("<head>")
      rendered.should contain("<body>")
      rendered.should contain("</body>")
      rendered.should contain("</html>")
    end

    it "includes header, content, and footer sections" do
      mailer = Components::Layouts::MailerLayout.new(content: "Test Content")
      rendered = mailer.render

      rendered.should contain("<!-- Header -->")
      rendered.should contain("<!-- Main Content -->")
      rendered.should contain("<!-- Footer -->")
    end

    it "uses semantic HTML comments" do
      mailer = Components::Layouts::MailerLayout.new(content: "Content")
      rendered = mailer.render

      rendered.should contain("<!-- Header -->")
      rendered.should contain("<!-- Main Content -->")
      rendered.should contain("<!-- Footer -->")
    end
  end

  describe "css_selector" do
    it "returns correct selector" do
      mailer = Components::Layouts::MailerLayout.new(content: "Content")

      mailer.css_selector.should eq(".email-container")
    end
  end

  describe "caching" do
    it "generates cache keys" do
      mailer = Components::Layouts::MailerLayout.new(content: "Content")

      mailer.cache_key.should be_a(String)
      mailer.cache_key.should_not be_empty
    end

    it "generates different cache keys for different content" do
      mailer1 = Components::Layouts::MailerLayout.new(content: "Content 1")
      mailer2 = Components::Layouts::MailerLayout.new(content: "Content 2")

      mailer1.cache_key.should_not eq(mailer2.cache_key)
    end

    it "generates same cache key for identical attributes" do
      mailer1 = Components::Layouts::MailerLayout.new(
        content: "Same content",
        title: "Same title"
      )
      mailer2 = Components::Layouts::MailerLayout.new(
        content: "Same content",
        title: "Same title"
      )

      mailer1.cache_key.should eq(mailer2.cache_key)
    end

    it "is cacheable" do
      mailer = Components::Layouts::MailerLayout.new(content: "Content")

      mailer.cacheable?.should be_true
    end
  end

  describe "real-world usage" do
    it "renders welcome email" do
      content = String.build do |html|
        html << "<h2 style=\"color: #1f2937; margin-bottom: 16px;\">Welcome to AgentC!</h2>"
        html << "<p>Thanks for signing up. We're excited to have you on board.</p>"
        html << "<p style=\"margin-top: 20px;\">"
        html << "<a href=\"https://example.com/get-started\" style=\"background-color: #4f46e5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;\">Get Started</a>"
        html << "</p>"
      end

      mailer = Components::Layouts::MailerLayout.new(
        title: "Welcome to AgentC",
        content: content,
        preheader: "Welcome! Let's get you started."
      )
      rendered = mailer.render

      rendered.should contain("Welcome to AgentC!")
      rendered.should contain("Get Started")
      rendered.should contain("href=\"https://example.com/get-started\"")
    end

    it "renders password reset email" do
      content = String.build do |html|
        html << "<h2 style=\"color: #1f2937;\">Reset Your Password</h2>"
        html << "<p>We received a request to reset your password.</p>"
        html << "<p>Click the button below to reset it:</p>"
        html << "<p style=\"margin-top: 20px;\">"
        html << "<a href=\"https://example.com/reset?token=abc123\" style=\"background-color: #4f46e5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;\">Reset Password</a>"
        html << "</p>"
        html << "<p style=\"margin-top: 20px; font-size: 13px; color: #6b7280;\">If you didn't request this, you can safely ignore this email.</p>"
      end

      mailer = Components::Layouts::MailerLayout.new(
        title: "Reset Your Password",
        content: content,
        preheader: "Reset your password"
      )
      rendered = mailer.render

      rendered.should contain("Reset Your Password")
      rendered.should contain("Reset Password")
      rendered.should contain("token=abc123")
    end
  end
end
