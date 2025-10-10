require "../component_spec_helper"
require "../../../src/views/components/shared/icon_component"

describe Components::Shared::IconComponent do
  describe "rendering" do
    it "renders a basic SVG icon" do
      icon = Components::Shared::IconComponent.new(
        path: "M13 10V3L4 14h7v7l9-11h-7z"
      )
      rendered = icon.render

      rendered.should contain("<svg")
      rendered.should contain("M13 10V3L4 14h7v7l9-11h-7z")
      rendered.should contain("</svg>")
    end

    it "applies default size classes" do
      icon = Components::Shared::IconComponent.new(
        path: "M12 2L2 7l10 5 10-5-10-5z"
      )
      rendered = icon.render

      rendered.should contain("h-6 w-6")
    end

    it "applies custom size classes" do
      icon = Components::Shared::IconComponent.new(
        path: "M12 2L2 7l10 5 10-5-10-5z",
        size: "h-8 w-8"
      )
      rendered = icon.render

      rendered.should contain("h-8 w-8")
    end

    it "applies color classes" do
      icon = Components::Shared::IconComponent.new(
        path: "M12 2L2 7l10 5 10-5-10-5z",
        color: "text-red-500"
      )
      rendered = icon.render

      rendered.should contain("text-red-500")
    end

    it "uses currentColor as default stroke" do
      icon = Components::Shared::IconComponent.new(
        path: "M12 2L2 7l10 5 10-5-10-5z"
      )
      rendered = icon.render

      rendered.should contain("stroke=\"currentColor\"")
    end

    it "applies custom viewBox" do
      icon = Components::Shared::IconComponent.new(
        path: "M0 0 L10 10",
        viewBox: "0 0 10 10"
      )
      rendered = icon.render

      rendered.should contain("viewBox=\"0 0 10 10\"")
    end

    it "applies custom fill" do
      icon = Components::Shared::IconComponent.new(
        path: "M12 2L2 7l10 5 10-5-10-5z",
        fill: "red"
      )
      rendered = icon.render

      rendered.should contain("fill=\"red\"")
    end

    it "applies custom stroke" do
      icon = Components::Shared::IconComponent.new(
        path: "M12 2L2 7l10 5 10-5-10-5z",
        stroke: "#ff0000"
      )
      rendered = icon.render

      rendered.should contain("stroke=\"#ff0000\"")
    end

    it "applies custom stroke width" do
      icon = Components::Shared::IconComponent.new(
        path: "M12 2L2 7l10 5 10-5-10-5z",
        stroke_width: "4"
      )
      rendered = icon.render

      rendered.should contain("stroke-width=\"4\"")
    end

    it "includes SVG namespace" do
      icon = Components::Shared::IconComponent.new(
        path: "M12 2L2 7l10 5 10-5-10-5z"
      )
      rendered = icon.render

      rendered.should contain("xmlns=\"http://www.w3.org/2000/svg\"")
    end

    it "includes path attributes" do
      icon = Components::Shared::IconComponent.new(
        path: "M12 2L2 7l10 5 10-5-10-5z"
      )
      rendered = icon.render

      rendered.should contain("stroke-linecap=\"round\"")
      rendered.should contain("stroke-linejoin=\"round\"")
    end

    it "does not include color in class attribute when currentColor" do
      icon = Components::Shared::IconComponent.new(
        path: "M12 2L2 7l10 5 10-5-10-5z",
        color: "currentColor"
      )
      rendered = icon.render

      # Should only have size class, not color class
      rendered.should contain("class=\"h-6 w-6\"")
      # But currentColor should still be in stroke attribute
      rendered.should contain("stroke=\"currentColor\"")
    end
  end

  describe "css_selector" do
    it "returns selector based on size" do
      icon = Components::Shared::IconComponent.new(
        path: "M12 2L2 7l10 5 10-5-10-5z",
        size: "h-6 w-6"
      )

      icon.css_selector.should eq(".h-6.w-6")
    end

    it "handles custom size in selector" do
      icon = Components::Shared::IconComponent.new(
        path: "M12 2L2 7l10 5 10-5-10-5z",
        size: "h-12 w-12"
      )

      icon.css_selector.should eq(".h-12.w-12")
    end
  end

  describe "caching" do
    it "generates cache keys" do
      icon = Components::Shared::IconComponent.new(
        path: "M12 2L2 7l10 5 10-5-10-5z",
        size: "h-6 w-6"
      )

      icon.cache_key.should be_a(String)
      icon.cache_key.should_not be_empty
    end

    it "generates same cache key for identical icons" do
      icon1 = Components::Shared::IconComponent.new(
        path: "M12 2L2 7l10 5 10-5-10-5z",
        size: "h-6 w-6",
        color: "text-blue-500"
      )
      icon2 = Components::Shared::IconComponent.new(
        path: "M12 2L2 7l10 5 10-5-10-5z",
        size: "h-6 w-6",
        color: "text-blue-500"
      )

      icon1.cache_key.should eq(icon2.cache_key)
    end

    it "generates different cache keys for different icons" do
      icon1 = Components::Shared::IconComponent.new(
        path: "M12 2L2 7l10 5 10-5-10-5z",
        size: "h-6 w-6"
      )
      icon2 = Components::Shared::IconComponent.new(
        path: "M13 10V3L4 14h7v7l9-11h-7z",
        size: "h-8 w-8"
      )

      icon1.cache_key.should_not eq(icon2.cache_key)
    end

    it "is cacheable" do
      icon = Components::Shared::IconComponent.new(
        path: "M12 2L2 7l10 5 10-5-10-5z"
      )

      icon.cacheable?.should be_true
    end
  end
end
