require "../component_spec_helper"
require "../../../src/components/shared/button_component"

describe Components::Shared::ButtonComponent do
  describe "rendering" do
    it "renders a basic button" do
      button = Components::Shared::ButtonComponent.new(label: "Click Me")
      rendered = button.render

      rendered.should contain("<button")
      rendered.should contain("Click Me")
      rendered.should contain("btn btn-primary btn-medium")
    end

    it "applies variant classes correctly" do
      button = Components::Shared::ButtonComponent.new(
        label: "Delete",
        variant: "danger"
      )

      button.render.should contain("btn-danger")
    end

    it "applies size classes correctly" do
      button = Components::Shared::ButtonComponent.new(
        label: "Small Button",
        size: "small"
      )

      button.render.should contain("btn-small")

      button_large = Components::Shared::ButtonComponent.new(
        label: "Large Button",
        size: "large"
      )

      button_large.render.should contain("btn-large")
    end

    it "renders icon when provided" do
      button = Components::Shared::ButtonComponent.new(
        label: "Save",
        icon: "💾"
      )

      rendered = button.render
      rendered.should contain("<span class=\"btn-icon\">💾</span>")
      rendered.should contain("Save")
    end

    it "renders as link when href provided" do
      button = Components::Shared::ButtonComponent.new(
        label: "Go",
        href: "/dashboard"
      )

      rendered = button.render
      rendered.should contain("<a")
      rendered.should contain("href=\"/dashboard\"")
      rendered.should contain("btn btn-primary btn-medium")
      rendered.should_not contain("<button")
    end

    it "applies disabled state" do
      button = Components::Shared::ButtonComponent.new(
        label: "Disabled",
        disabled: "true"
      )

      rendered = button.render
      rendered.should contain("disabled=\"true\"")
      rendered.should contain("class=\"btn btn-primary btn-medium disabled\"")
    end

    it "supports additional CSS classes" do
      button = Components::Shared::ButtonComponent.new(
        label: "Custom",
        class: "custom-class another-class"
      )

      button.render.should contain("custom-class another-class")
    end

    it "supports submit type" do
      button = Components::Shared::ButtonComponent.new(
        label: "Submit",
        type: "submit"
      )

      button.render.should contain("type=\"submit\"")
    end
  end

  describe "css_selector" do
    it "returns correct selector for primary button" do
      button = Components::Shared::ButtonComponent.new(label: "Test")
      button.css_selector.should eq(".btn.btn-primary.btn-medium")
    end

    it "returns correct selector for danger button" do
      button = Components::Shared::ButtonComponent.new(label: "Test", variant: "danger")
      button.css_selector.should eq(".btn.btn-danger.btn-medium")
    end

    it "returns correct selector for large button" do
      button = Components::Shared::ButtonComponent.new(label: "Test", size: "large")
      button.css_selector.should eq(".btn.btn-primary.btn-large")
    end
  end

  describe "caching" do
    it "generates same cache key for same attributes" do
      btn1 = Components::Shared::ButtonComponent.new(label: "Test", variant: "primary")
      btn2 = Components::Shared::ButtonComponent.new(label: "Test", variant: "primary")

      btn1.cache_key.should eq(btn2.cache_key)
    end

    it "generates different cache keys for different attributes" do
      btn1 = Components::Shared::ButtonComponent.new(label: "Test", variant: "primary")
      btn2 = Components::Shared::ButtonComponent.new(label: "Test", variant: "danger")

      btn1.cache_key.should_not eq(btn2.cache_key)
    end

    it "is cacheable by default" do
      button = Components::Shared::ButtonComponent.new(label: "Test")
      button.cacheable?.should be_true
    end
  end
end
