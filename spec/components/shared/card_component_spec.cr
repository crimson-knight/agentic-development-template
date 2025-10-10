require "../component_spec_helper"
require "../../../src/views/components/shared/card_component"

describe Components::Shared::CardComponent do
  describe "rendering" do
    it "renders a basic card with title and description" do
      card = Components::Shared::CardComponent.new(
        title: "Test Card",
        description: "This is a test card description"
      )
      rendered = card.render

      rendered.should contain("Test Card")
      rendered.should contain("This is a test card description")
      rendered.should contain("bg-white")
      rendered.should contain("rounded-lg")
    end

    it "renders with an icon" do
      card = Components::Shared::CardComponent.new(
        title: "Feature",
        description: "Feature description",
        icon_path: "M13 10V3L4 14h7v7l9-11h-7z"
      )
      rendered = card.render

      rendered.should contain("<svg")
      rendered.should contain("M13 10V3L4 14h7v7l9-11h-7z")
    end

    it "applies custom icon colors" do
      card = Components::Shared::CardComponent.new(
        title: "Feature",
        description: "Feature description",
        icon_path: "M13 10V3L4 14h7v7l9-11h-7z",
        icon_color: "text-red-600",
        icon_bg_color: "bg-red-100"
      )
      rendered = card.render

      rendered.should contain("bg-red-100")
      rendered.should contain("text-red-600")
    end

    it "uses default icon colors" do
      card = Components::Shared::CardComponent.new(
        title: "Feature",
        description: "Feature description",
        icon_path: "M13 10V3L4 14h7v7l9-11h-7z"
      )
      rendered = card.render

      rendered.should contain("bg-indigo-100")
      rendered.should contain("text-indigo-600")
    end

    it "renders without an icon" do
      card = Components::Shared::CardComponent.new(
        title: "Feature",
        description: "Feature description"
      )
      rendered = card.render

      rendered.should_not contain("<svg")
      rendered.should contain("Feature")
      rendered.should contain("Feature description")
    end

    it "renders with a link" do
      card = Components::Shared::CardComponent.new(
        title: "Feature",
        description: "Feature description",
        link_href: "https://example.com",
        link_text: "Read more"
      )
      rendered = card.render

      rendered.should contain("href=\"https://example.com\"")
      rendered.should contain("Read more")
    end

    it "uses default link text" do
      card = Components::Shared::CardComponent.new(
        title: "Feature",
        description: "Feature description",
        link_href: "https://example.com"
      )
      rendered = card.render

      rendered.should contain("Learn more →")
    end

    it "renders link with target blank" do
      card = Components::Shared::CardComponent.new(
        title: "Feature",
        description: "Feature description",
        link_href: "https://example.com",
        link_target: "_blank"
      )
      rendered = card.render

      rendered.should contain("target=\"_blank\"")
      rendered.should contain("rel=\"noopener noreferrer\"")
    end

    it "renders link without target" do
      card = Components::Shared::CardComponent.new(
        title: "Feature",
        description: "Feature description",
        link_href: "/internal"
      )
      rendered = card.render

      rendered.should_not contain("target=")
      rendered.should_not contain("rel=\"noopener noreferrer\"")
    end

    it "renders without a link" do
      card = Components::Shared::CardComponent.new(
        title: "Feature",
        description: "Feature description"
      )
      rendered = card.render

      rendered.should_not contain("<a")
      rendered.should_not contain("href=")
    end

    it "applies custom card classes" do
      card = Components::Shared::CardComponent.new(
        title: "Feature",
        description: "Feature description",
        card_class: "border-2 border-blue-500"
      )
      rendered = card.render

      rendered.should contain("border-2 border-blue-500")
    end

    it "includes hover effects" do
      card = Components::Shared::CardComponent.new(
        title: "Feature",
        description: "Feature description"
      )
      rendered = card.render

      rendered.should contain("hover:shadow-lg")
      rendered.should contain("transition-shadow")
    end

    it "renders complete card with all features" do
      card = Components::Shared::CardComponent.new(
        title: "Complete Feature",
        description: "This card has everything",
        icon_path: "M13 10V3L4 14h7v7l9-11h-7z",
        icon_color: "text-green-600",
        icon_bg_color: "bg-green-100",
        link_href: "https://example.com",
        link_text: "Explore",
        link_target: "_blank",
        card_class: "custom-class"
      )
      rendered = card.render

      rendered.should contain("Complete Feature")
      rendered.should contain("This card has everything")
      rendered.should contain("<svg")
      rendered.should contain("bg-green-100")
      rendered.should contain("text-green-600")
      rendered.should contain("href=\"https://example.com\"")
      rendered.should contain("Explore")
      rendered.should contain("target=\"_blank\"")
      rendered.should contain("custom-class")
    end
  end

  describe "css_selector" do
    it "returns correct selector" do
      card = Components::Shared::CardComponent.new(
        title: "Test",
        description: "Test"
      )

      card.css_selector.should eq(".bg-white.rounded-lg.shadow-md")
    end
  end

  describe "caching" do
    it "generates cache keys" do
      card = Components::Shared::CardComponent.new(
        title: "Test",
        description: "Test description"
      )

      card.cache_key.should be_a(String)
      card.cache_key.should_not be_empty
    end

    it "generates same cache key for identical cards" do
      card1 = Components::Shared::CardComponent.new(
        title: "Test",
        description: "Test description",
        icon_path: "M12 2L2 7l10 5 10-5-10-5z"
      )
      card2 = Components::Shared::CardComponent.new(
        title: "Test",
        description: "Test description",
        icon_path: "M12 2L2 7l10 5 10-5-10-5z"
      )

      card1.cache_key.should eq(card2.cache_key)
    end

    it "generates different cache keys for different cards" do
      card1 = Components::Shared::CardComponent.new(
        title: "Card One",
        description: "Description one"
      )
      card2 = Components::Shared::CardComponent.new(
        title: "Card Two",
        description: "Description two"
      )

      card1.cache_key.should_not eq(card2.cache_key)
    end

    it "is cacheable" do
      card = Components::Shared::CardComponent.new(
        title: "Test",
        description: "Test"
      )

      card.cacheable?.should be_true
    end
  end
end
