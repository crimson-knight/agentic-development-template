require "../component_spec_helper"
require "../../../src/components/layouts/navigation_component"

describe Components::Layouts::NavigationComponent do
  describe "rendering" do
    it "renders navigation bar" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/"
      )
      rendered = nav.render

      rendered.should contain("<nav")
      rendered.should contain("bg-white")
      rendered.should contain("shadow-sm")
    end

    it "renders logo with default src" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/"
      )
      rendered = nav.render

      rendered.should contain("src=\"/img/logo.svg\"")
      rendered.should contain("alt=\"Logo\"")
    end

    it "renders custom logo src" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/",
        logo_src: "/custom-logo.png"
      )
      rendered = nav.render

      rendered.should contain("src=\"/custom-logo.png\"")
    end

    it "renders default app name" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/"
      )
      rendered = nav.render

      rendered.should contain("AgentC")
    end

    it "renders custom app name" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/",
        app_name: "My App"
      )
      rendered = nav.render

      rendered.should contain("My App")
    end

    it "renders Home link" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/"
      )
      rendered = nav.render

      rendered.should contain("href=\"/\"")
      rendered.should contain(">Home</a>")
    end

    it "highlights Home link when on homepage" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/"
      )
      rendered = nav.render

      rendered.should contain("border-indigo-500")
      rendered.should contain("text-gray-900")
    end

    it "does not highlight Home link when on other page" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/dashboard"
      )
      rendered = nav.render

      rendered.should contain("border-transparent")
      rendered.should_not contain("border-indigo-500")
    end

    it "renders Sign In link when not logged in" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/",
        logged_in: "false"
      )
      rendered = nav.render

      rendered.should contain("href=\"/login\"")
      rendered.should contain(">Sign In</a>")
    end

    it "does not render Sign In link when logged in" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/",
        logged_in: "true",
        user_email: "user@example.com"
      )
      rendered = nav.render

      rendered.should_not contain(">Sign In</a>")
    end

    it "renders session info when logged in" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/",
        logged_in: "true",
        user_email: "user@example.com"
      )
      rendered = nav.render

      rendered.should contain("user@example.com")
      rendered.should contain("Profile")
      rendered.should contain("Logout")
    end

    it "does not render session info when not logged in" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/",
        logged_in: "false"
      )
      rendered = nav.render

      rendered.should_not contain("Profile")
      rendered.should_not contain("Logout")
    end

    it "passes custom profile href to session info" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/",
        logged_in: "true",
        user_email: "user@example.com",
        profile_href: "/settings"
      )
      rendered = nav.render

      rendered.should contain("href=\"/settings\"")
    end

    it "passes custom logout href to session info" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/",
        logged_in: "true",
        user_email: "user@example.com",
        logout_href: "/sign-out"
      )
      rendered = nav.render

      rendered.should contain("href=\"/sign-out\"")
    end

    it "renders mobile menu button" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/"
      )
      rendered = nav.render

      rendered.should contain("Open main menu")
      rendered.should contain("aria-controls=\"mobile-menu\"")
      rendered.should contain("M4 6h16M4 12h16M4 18h16")
    end

    it "uses desktop-only classes for nav links" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/"
      )
      rendered = nav.render

      rendered.should contain("hidden sm:ml-6 sm:flex")
    end

    it "uses desktop-only classes for session info" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/",
        logged_in: "true",
        user_email: "user@example.com"
      )
      rendered = nav.render

      rendered.should contain("hidden sm:ml-6 sm:flex sm:items-center")
    end

    it "uses mobile-only classes for menu button" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/"
      )
      rendered = nav.render

      rendered.should contain("sm:hidden flex items-center")
    end

    it "includes transition classes on links" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/"
      )
      rendered = nav.render

      rendered.should contain("transition-colors")
      rendered.should contain("duration-200")
    end

    it "includes proper layout structure" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/"
      )
      rendered = nav.render

      rendered.should contain("max-w-7xl")
      rendered.should contain("mx-auto")
      rendered.should contain("justify-between")
      rendered.should contain("h-16")
    end
  end

  describe "css_selector" do
    it "returns correct selector" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/"
      )

      nav.css_selector.should eq("nav.bg-white.shadow-sm")
    end
  end

  describe "caching" do
    it "generates cache keys" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/"
      )

      nav.cache_key.should be_a(String)
      nav.cache_key.should_not be_empty
    end

    it "generates same cache key for identical navigation" do
      nav1 = Components::Layouts::NavigationComponent.new(
        current_path: "/",
        logged_in: "true",
        user_email: "user@example.com"
      )
      nav2 = Components::Layouts::NavigationComponent.new(
        current_path: "/",
        logged_in: "true",
        user_email: "user@example.com"
      )

      nav1.cache_key.should eq(nav2.cache_key)
    end

    it "generates different cache keys for different paths" do
      nav1 = Components::Layouts::NavigationComponent.new(
        current_path: "/"
      )
      nav2 = Components::Layouts::NavigationComponent.new(
        current_path: "/dashboard"
      )

      nav1.cache_key.should_not eq(nav2.cache_key)
    end

    it "generates different cache keys for different login states" do
      nav1 = Components::Layouts::NavigationComponent.new(
        current_path: "/",
        logged_in: "true",
        user_email: "user@example.com"
      )
      nav2 = Components::Layouts::NavigationComponent.new(
        current_path: "/",
        logged_in: "false"
      )

      nav1.cache_key.should_not eq(nav2.cache_key)
    end

    it "is cacheable" do
      nav = Components::Layouts::NavigationComponent.new(
        current_path: "/"
      )

      nav.cacheable?.should be_true
    end
  end
end
