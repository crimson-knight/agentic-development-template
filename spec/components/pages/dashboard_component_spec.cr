require "../component_spec_helper"
require "../../../src/views/components/pages/dashboard_component"

describe Components::Pages::DashboardComponent do
  describe "rendering" do
    it "renders dashboard header" do
      dashboard = Components::Pages::DashboardComponent.new
      rendered = dashboard.render

      rendered.should contain("Dashboard")
      rendered.should contain("Welcome back!")
    end

    it "renders New Project button" do
      dashboard = Components::Pages::DashboardComponent.new
      rendered = dashboard.render

      rendered.should contain("New Project")
    end

    it "renders Total Users stat card" do
      dashboard = Components::Pages::DashboardComponent.new
      rendered = dashboard.render

      rendered.should contain("Total Users")
      rendered.should contain("1,247")
      rendered.should contain("12%")
    end

    it "renders Revenue stat card" do
      dashboard = Components::Pages::DashboardComponent.new
      rendered = dashboard.render

      rendered.should contain("Revenue")
      rendered.should contain("$24,780")
      rendered.should contain("8%")
    end

    it "renders Growth Rate stat card" do
      dashboard = Components::Pages::DashboardComponent.new
      rendered = dashboard.render

      rendered.should contain("Growth Rate")
      rendered.should contain("24.7%")
      rendered.should contain("3.2%")
    end

    it "renders Conversion stat card" do
      dashboard = Components::Pages::DashboardComponent.new
      rendered = dashboard.render

      rendered.should contain("Conversion")
      rendered.should contain("3.24%")
      rendered.should contain("1.2%")
    end

    it "renders Recent Activity section" do
      dashboard = Components::Pages::DashboardComponent.new
      rendered = dashboard.render

      rendered.should contain("Recent Activity")
    end

    it "renders activity items" do
      dashboard = Components::Pages::DashboardComponent.new
      rendered = dashboard.render

      rendered.should contain("New user registration")
      rendered.should contain("Payment processed")
      rendered.should contain("System maintenance")
    end

    it "renders Quick Actions section" do
      dashboard = Components::Pages::DashboardComponent.new
      rendered = dashboard.render

      rendered.should contain("Quick Actions")
    end

    it "renders quick action buttons" do
      dashboard = Components::Pages::DashboardComponent.new
      rendered = dashboard.render

      rendered.should contain("Create New Project")
      rendered.should contain("Invite Team Members")
      rendered.should contain("View Analytics")
    end

    it "uses proper grid layout" do
      dashboard = Components::Pages::DashboardComponent.new
      rendered = dashboard.render

      rendered.should contain("grid grid-cols-1")
      rendered.should contain("lg:grid-cols-4")
      rendered.should contain("lg:grid-cols-2")
    end
  end

  describe "css_selector" do
    it "returns correct selector" do
      dashboard = Components::Pages::DashboardComponent.new

      dashboard.css_selector.should eq(".px-4.sm\\:px-6.lg\\:px-8")
    end
  end

  describe "caching" do
    it "generates cache keys" do
      dashboard = Components::Pages::DashboardComponent.new

      dashboard.cache_key.should be_a(String)
      dashboard.cache_key.should_not be_empty
    end

    it "is cacheable" do
      dashboard = Components::Pages::DashboardComponent.new

      dashboard.cacheable?.should be_true
    end
  end
end
