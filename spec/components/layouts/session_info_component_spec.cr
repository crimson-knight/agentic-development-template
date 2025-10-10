require "../component_spec_helper"
require "../../../src/views/components/layouts/session_info_component"

describe Components::Layouts::SessionInfoComponent do
  describe "rendering" do
    it "renders user email" do
      session_info = Components::Layouts::SessionInfoComponent.new(
        user_email: "user@example.com"
      )
      rendered = session_info.render

      rendered.should contain("user@example.com")
    end

    it "renders profile link with default href" do
      session_info = Components::Layouts::SessionInfoComponent.new(
        user_email: "user@example.com"
      )
      rendered = session_info.render

      rendered.should contain("href=\"/profile\"")
      rendered.should contain("Profile")
    end

    it "renders profile link with custom href" do
      session_info = Components::Layouts::SessionInfoComponent.new(
        user_email: "user@example.com",
        profile_href: "/settings"
      )
      rendered = session_info.render

      rendered.should contain("href=\"/settings\"")
    end

    it "renders logout button with default href" do
      session_info = Components::Layouts::SessionInfoComponent.new(
        user_email: "user@example.com"
      )
      rendered = session_info.render

      rendered.should contain("Logout")
      rendered.should contain("href=\"/logout\"")
    end

    it "renders logout button with custom href" do
      session_info = Components::Layouts::SessionInfoComponent.new(
        user_email: "user@example.com",
        logout_href: "/sign-out"
      )
      rendered = session_info.render

      rendered.should contain("href=\"/sign-out\"")
    end

    it "renders logout button as secondary variant" do
      session_info = Components::Layouts::SessionInfoComponent.new(
        user_email: "user@example.com"
      )
      rendered = session_info.render

      rendered.should contain("btn-secondary")
    end

    it "renders logout button as small size" do
      session_info = Components::Layouts::SessionInfoComponent.new(
        user_email: "user@example.com"
      )
      rendered = session_info.render

      rendered.should contain("btn-small")
    end

    it "uses Guest as default email" do
      session_info = Components::Layouts::SessionInfoComponent.new
      rendered = session_info.render

      rendered.should contain("Guest")
    end

    it "includes flex layout classes" do
      session_info = Components::Layouts::SessionInfoComponent.new(
        user_email: "user@example.com"
      )
      rendered = session_info.render

      rendered.should contain("flex")
      rendered.should contain("items-center")
      rendered.should contain("space-x-4")
    end

    it "styles profile link" do
      session_info = Components::Layouts::SessionInfoComponent.new(
        user_email: "user@example.com"
      )
      rendered = session_info.render

      rendered.should contain("text-indigo-600")
      rendered.should contain("hover:text-indigo-700")
    end

    it "styles user email text" do
      session_info = Components::Layouts::SessionInfoComponent.new(
        user_email: "user@example.com"
      )
      rendered = session_info.render

      rendered.should contain("text-sm")
      rendered.should contain("text-gray-700")
    end

    it "renders all components together" do
      session_info = Components::Layouts::SessionInfoComponent.new(
        user_email: "admin@example.com",
        profile_href: "/admin/profile",
        logout_href: "/admin/logout"
      )
      rendered = session_info.render

      rendered.should contain("admin@example.com")
      rendered.should contain("href=\"/admin/profile\"")
      rendered.should contain("href=\"/admin/logout\"")
      rendered.should contain("Profile")
      rendered.should contain("Logout")
    end
  end

  describe "css_selector" do
    it "returns correct selector" do
      session_info = Components::Layouts::SessionInfoComponent.new(
        user_email: "user@example.com"
      )

      session_info.css_selector.should eq(".flex.items-center.space-x-4")
    end
  end

  describe "caching" do
    it "generates cache keys" do
      session_info = Components::Layouts::SessionInfoComponent.new(
        user_email: "user@example.com"
      )

      session_info.cache_key.should be_a(String)
      session_info.cache_key.should_not be_empty
    end

    it "generates same cache key for identical session info" do
      session_info1 = Components::Layouts::SessionInfoComponent.new(
        user_email: "user@example.com",
        profile_href: "/profile"
      )
      session_info2 = Components::Layouts::SessionInfoComponent.new(
        user_email: "user@example.com",
        profile_href: "/profile"
      )

      session_info1.cache_key.should eq(session_info2.cache_key)
    end

    it "generates different cache keys for different users" do
      session_info1 = Components::Layouts::SessionInfoComponent.new(
        user_email: "user1@example.com"
      )
      session_info2 = Components::Layouts::SessionInfoComponent.new(
        user_email: "user2@example.com"
      )

      session_info1.cache_key.should_not eq(session_info2.cache_key)
    end

    it "is cacheable" do
      session_info = Components::Layouts::SessionInfoComponent.new(
        user_email: "user@example.com"
      )

      session_info.cacheable?.should be_true
    end
  end
end
