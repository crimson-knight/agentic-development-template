require "../component_spec_helper"
require "../../../src/components/layouts/application_layout"

describe Components::Layouts::ApplicationLayout do
  describe "rendering" do
    it "renders complete HTML document" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "<h1>Test Content</h1>"
      )
      rendered = layout.render

      rendered.should contain("<!doctype html>")
      rendered.should contain("<html")
      rendered.should contain("<head>")
      rendered.should contain("<body")
      rendered.should contain("</html>")
    end

    it "renders default page title" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test"
      )
      rendered = layout.render

      rendered.should contain("<title>AgentC App Template</title>")
    end

    it "renders custom page title" do
      layout = Components::Layouts::ApplicationLayout.new(
        title: "Dashboard",
        content: "Test"
      )
      rendered = layout.render

      rendered.should contain("<title>Dashboard</title>")
    end

    it "includes meta tags" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test"
      )
      rendered = layout.render

      rendered.should contain("charset=\"utf-8\"")
      rendered.should contain("X-UA-Compatible")
      rendered.should contain("viewport")
    end

    it "includes Tailwind CSS CDN" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test"
      )
      rendered = layout.render

      rendered.should contain("@tailwindcss/browser")
    end

    it "includes favicon links" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test"
      )
      rendered = layout.render

      rendered.should contain("favicon.png")
      rendered.should contain("favicon.ico")
      rendered.should contain("apple-touch-icon")
    end

    it "includes Stimulus setup" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test"
      )
      rendered = layout.render

      rendered.should contain("@hotwired/stimulus")
      rendered.should contain("Application.start()")
      rendered.should contain("LoginController")
    end

    it "includes import map HTML when provided" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test",
        import_map_html: "<script type=\"importmap\">...</script>"
      )
      rendered = layout.render

      rendered.should contain("<script type=\"importmap\">...</script>")
    end

    it "renders navigation component" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test",
        current_path: "/"
      )
      rendered = layout.render

      rendered.should contain("<nav")
      rendered.should contain("AgentC")
      rendered.should contain(">Home</a>")
    end

    it "passes current path to navigation" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test",
        current_path: "/dashboard"
      )
      rendered = layout.render

      # Should not highlight home link when on /dashboard
      rendered.should_not contain("border-indigo-500")
    end

    it "passes logged in state to navigation" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test",
        logged_in: "true",
        user_email: "user@example.com"
      )
      rendered = layout.render

      rendered.should contain("user@example.com")
      rendered.should_not contain(">Sign In</a>")
    end

    it "renders main content" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "<h1>Test Page</h1><p>Content here</p>"
      )
      rendered = layout.render

      rendered.should contain("<h1>Test Page</h1>")
      rendered.should contain("<p>Content here</p>")
    end

    it "renders success flash message" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test",
        flash_success: "Operation successful!"
      )
      rendered = layout.render

      rendered.should contain("Operation successful!")
      rendered.should contain("bg-green-50")
    end

    it "renders error flash message" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test",
        flash_error: "Something went wrong!"
      )
      rendered = layout.render

      rendered.should contain("Something went wrong!")
      rendered.should contain("bg-red-50")
    end

    it "renders info flash message" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test",
        flash_info: "Please note this"
      )
      rendered = layout.render

      rendered.should contain("Please note this")
      rendered.should contain("bg-blue-50")
    end

    it "renders warning flash message" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test",
        flash_warning: "Be careful!"
      )
      rendered = layout.render

      rendered.should contain("Be careful!")
      rendered.should contain("bg-yellow-50")
    end

    it "renders multiple flash messages" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test",
        flash_success: "Success!",
        flash_error: "Error!",
        flash_info: "Info!"
      )
      rendered = layout.render

      rendered.should contain("Success!")
      rendered.should contain("Error!")
      rendered.should contain("Info!")
    end

    it "does not render flash container when no messages" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test"
      )
      rendered = layout.render

      # Should not have the flash messages wrapper div
      rendered.should_not contain("mt-4")
    end

    it "includes auto-reload script when enabled" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test",
        auto_reload: "true"
      )
      rendered = layout.render

      rendered.should contain("client_reload.js")
    end

    it "does not include auto-reload script when disabled" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test",
        auto_reload: "false"
      )
      rendered = layout.render

      rendered.should_not contain("client_reload.js")
    end

    it "includes Amber.js script" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test"
      )
      rendered = layout.render

      rendered.should contain("amber.js")
    end

    it "uses proper body classes" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test"
      )
      rendered = layout.render

      rendered.should contain("class=\"h-full\"")
      rendered.should contain("class=\"min-h-full\"")
    end

    it "uses proper main content container" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test"
      )
      rendered = layout.render

      rendered.should contain("<main class=\"max-w-7xl mx-auto py-6 sm:px-6 lg:px-8\">")
    end

    it "wraps flash messages in proper container" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test",
        flash_success: "Success!"
      )
      rendered = layout.render

      rendered.should contain("max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-4")
    end
  end

  describe "css_selector" do
    it "returns correct selector" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test"
      )

      layout.css_selector.should eq("html.h-full.bg-gray-50")
    end
  end

  describe "caching" do
    it "generates cache keys" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test"
      )

      layout.cache_key.should be_a(String)
      layout.cache_key.should_not be_empty
    end

    it "generates same cache key for identical layouts" do
      layout1 = Components::Layouts::ApplicationLayout.new(
        title: "Test",
        content: "Same content",
        current_path: "/"
      )
      layout2 = Components::Layouts::ApplicationLayout.new(
        title: "Test",
        content: "Same content",
        current_path: "/"
      )

      layout1.cache_key.should eq(layout2.cache_key)
    end

    it "generates different cache keys for different content" do
      layout1 = Components::Layouts::ApplicationLayout.new(
        content: "Content 1"
      )
      layout2 = Components::Layouts::ApplicationLayout.new(
        content: "Content 2"
      )

      layout1.cache_key.should_not eq(layout2.cache_key)
    end

    it "generates different cache keys for different flash messages" do
      layout1 = Components::Layouts::ApplicationLayout.new(
        content: "Test",
        flash_success: "Success 1"
      )
      layout2 = Components::Layouts::ApplicationLayout.new(
        content: "Test",
        flash_success: "Success 2"
      )

      layout1.cache_key.should_not eq(layout2.cache_key)
    end

    it "is cacheable" do
      layout = Components::Layouts::ApplicationLayout.new(
        content: "Test"
      )

      layout.cacheable?.should be_true
    end
  end
end
