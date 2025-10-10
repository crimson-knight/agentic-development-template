require "../component_spec_helper"
require "../../../src/components/shared/stat_card_component"

describe Components::Shared::StatCardComponent do
  describe "rendering" do
    it "renders a basic stat card with title and value" do
      stat = Components::Shared::StatCardComponent.new(
        title: "Total Users",
        value: "1,247"
      )
      rendered = stat.render

      rendered.should contain("Total Users")
      rendered.should contain("1,247")
      rendered.should contain("bg-white")
      rendered.should contain("rounded-lg")
    end

    it "renders with an icon" do
      stat = Components::Shared::StatCardComponent.new(
        title: "Total Users",
        value: "1,247",
        icon_path: "M12 4.354a4 4 0 110 5.292"
      )
      rendered = stat.render

      rendered.should contain("<svg")
      rendered.should contain("M12 4.354a4 4 0 110 5.292")
    end

    it "uses default icon background color" do
      stat = Components::Shared::StatCardComponent.new(
        title: "Total Users",
        value: "1,247",
        icon_path: "M12 4.354a4 4 0 110 5.292"
      )
      rendered = stat.render

      rendered.should contain("bg-indigo-100")
      rendered.should contain("text-indigo-600")
    end

    it "applies custom icon background color" do
      stat = Components::Shared::StatCardComponent.new(
        title: "Revenue",
        value: "$24,780",
        icon_path: "M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2",
        bg_color: "green"
      )
      rendered = stat.render

      rendered.should contain("bg-green-100")
      rendered.should contain("text-green-600")
    end

    it "renders without an icon" do
      stat = Components::Shared::StatCardComponent.new(
        title: "Total Users",
        value: "1,247"
      )
      rendered = stat.render

      rendered.should_not contain("<svg")
      rendered.should contain("Total Users")
      rendered.should contain("1,247")
    end

    it "renders with upward trend" do
      stat = Components::Shared::StatCardComponent.new(
        title: "Total Users",
        value: "1,247",
        trend_direction: "up",
        trend_value: "12%"
      )
      rendered = stat.render

      rendered.should contain("12%")
      rendered.should contain("↑")
      rendered.should contain("text-green-600")
    end

    it "renders with downward trend" do
      stat = Components::Shared::StatCardComponent.new(
        title: "Conversion",
        value: "3.24%",
        trend_direction: "down",
        trend_value: "1.2%"
      )
      rendered = stat.render

      rendered.should contain("1.2%")
      rendered.should contain("↓")
      rendered.should contain("text-red-600")
    end

    it "renders without trend" do
      stat = Components::Shared::StatCardComponent.new(
        title: "Total Users",
        value: "1,247"
      )
      rendered = stat.render

      rendered.should_not contain("↑")
      rendered.should_not contain("↓")
      rendered.should_not contain("text-green-600")
      rendered.should_not contain("text-red-600")
    end

    it "renders trend without direction" do
      stat = Components::Shared::StatCardComponent.new(
        title: "Active Sessions",
        value: "42",
        trend_value: "stable"
      )
      rendered = stat.render

      rendered.should contain("stable")
      rendered.should_not contain("↑")
      rendered.should_not contain("↓")
    end

    it "renders with all features" do
      stat = Components::Shared::StatCardComponent.new(
        title: "Total Revenue",
        value: "$24,780",
        icon_path: "M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2",
        trend_direction: "up",
        trend_value: "8%",
        bg_color: "green"
      )
      rendered = stat.render

      rendered.should contain("Total Revenue")
      rendered.should contain("$24,780")
      rendered.should contain("<svg")
      rendered.should contain("bg-green-100")
      rendered.should contain("text-green-600")
      rendered.should contain("8%")
      rendered.should contain("↑")
    end

    it "displays value with proper formatting" do
      stat = Components::Shared::StatCardComponent.new(
        title: "Large Number",
        value: "1,234,567"
      )
      rendered = stat.render

      rendered.should contain("1,234,567")
      rendered.should contain("text-3xl")
      rendered.should contain("font-bold")
    end

    it "uses proper typography classes" do
      stat = Components::Shared::StatCardComponent.new(
        title: "Test Stat",
        value: "100"
      )
      rendered = stat.render

      # Value styling
      rendered.should contain("text-3xl")
      rendered.should contain("font-bold")
      rendered.should contain("text-gray-900")

      # Title styling
      rendered.should contain("text-sm")
      rendered.should contain("font-medium")
      rendered.should contain("text-gray-600")
    end

    it "includes proper layout classes" do
      stat = Components::Shared::StatCardComponent.new(
        title: "Test",
        value: "100"
      )
      rendered = stat.render

      rendered.should contain("flex")
      rendered.should contain("items-center")
      rendered.should contain("justify-between")
    end
  end

  describe "css_selector" do
    it "returns correct selector" do
      stat = Components::Shared::StatCardComponent.new(
        title: "Test",
        value: "100"
      )

      stat.css_selector.should eq(".bg-white.rounded-lg.shadow-md")
    end
  end

  describe "caching" do
    it "generates cache keys" do
      stat = Components::Shared::StatCardComponent.new(
        title: "Test",
        value: "100"
      )

      stat.cache_key.should be_a(String)
      stat.cache_key.should_not be_empty
    end

    it "generates same cache key for identical stats" do
      stat1 = Components::Shared::StatCardComponent.new(
        title: "Users",
        value: "1,247",
        trend_direction: "up",
        trend_value: "12%"
      )
      stat2 = Components::Shared::StatCardComponent.new(
        title: "Users",
        value: "1,247",
        trend_direction: "up",
        trend_value: "12%"
      )

      stat1.cache_key.should eq(stat2.cache_key)
    end

    it "generates different cache keys for different stats" do
      stat1 = Components::Shared::StatCardComponent.new(
        title: "Users",
        value: "1,247"
      )
      stat2 = Components::Shared::StatCardComponent.new(
        title: "Revenue",
        value: "$24,780"
      )

      stat1.cache_key.should_not eq(stat2.cache_key)
    end

    it "is cacheable" do
      stat = Components::Shared::StatCardComponent.new(
        title: "Test",
        value: "100"
      )

      stat.cacheable?.should be_true
    end
  end
end
