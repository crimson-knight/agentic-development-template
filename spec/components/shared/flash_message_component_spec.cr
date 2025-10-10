require "../component_spec_helper"
require "../../../src/components/shared/flash_message_component"

describe Components::Shared::FlashMessageComponent do
  describe "rendering" do
    it "renders a success message" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "success",
        message: "Operation completed successfully!"
      )
      rendered = flash.render

      rendered.should contain("Operation completed successfully!")
      rendered.should contain("bg-green-50")
      rendered.should contain("border-green-200")
      rendered.should contain("text-green-800")
      rendered.should contain("<svg")
    end

    it "renders an error message" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "error",
        message: "Something went wrong!"
      )
      rendered = flash.render

      rendered.should contain("Something went wrong!")
      rendered.should contain("bg-red-50")
      rendered.should contain("border-red-200")
      rendered.should contain("text-red-800")
      rendered.should contain("<svg")
    end

    it "renders an info message" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "info",
        message: "Please note this information"
      )
      rendered = flash.render

      rendered.should contain("Please note this information")
      rendered.should contain("bg-blue-50")
      rendered.should contain("border-blue-200")
      rendered.should contain("text-blue-800")
      rendered.should contain("<svg")
    end

    it "renders a warning message" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "warning",
        message: "This action cannot be undone"
      )
      rendered = flash.render

      rendered.should contain("This action cannot be undone")
      rendered.should contain("bg-yellow-50")
      rendered.should contain("border-yellow-200")
      rendered.should contain("text-yellow-800")
      rendered.should contain("<svg")
    end

    it "defaults to info type when type is not specified" do
      flash = Components::Shared::FlashMessageComponent.new(
        message: "Default message"
      )
      rendered = flash.render

      rendered.should contain("bg-blue-50")
      rendered.should contain("border-blue-200")
    end

    it "uses correct icon for success" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "success",
        message: "Success!"
      )
      rendered = flash.render

      # Checkmark circle icon path
      rendered.should contain("M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z")
    end

    it "uses correct icon for error" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "error",
        message: "Error!"
      )
      rendered = flash.render

      # X circle icon path
      rendered.should contain("M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z")
    end

    it "uses correct icon for warning" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "warning",
        message: "Warning!"
      )
      rendered = flash.render

      # Exclamation triangle icon path
      rendered.should contain("M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z")
    end

    it "uses correct icon for info" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "info",
        message: "Info!"
      )
      rendered = flash.render

      # Info circle icon path
      rendered.should contain("M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z")
    end

    it "returns empty string when message is empty" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "success",
        message: ""
      )
      rendered = flash.render

      rendered.should eq("")
    end

    it "returns empty string when message is not provided" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "success"
      )
      rendered = flash.render

      rendered.should eq("")
    end

    it "includes accessibility role" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "info",
        message: "Test message"
      )
      rendered = flash.render

      rendered.should contain("role=\"alert\"")
    end

    it "uses proper layout classes" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "success",
        message: "Test"
      )
      rendered = flash.render

      rendered.should contain("flex")
      rendered.should contain("items-start")
      rendered.should contain("rounded-lg")
      rendered.should contain("p-4")
    end

    it "includes icon background styling" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "success",
        message: "Test"
      )
      rendered = flash.render

      rendered.should contain("bg-green-100")
      rendered.should contain("text-green-400")
    end

    it "handles long messages" do
      long_message = "This is a very long message that should still render properly with all the styling and layout intact even though it contains a lot of text content."
      flash = Components::Shared::FlashMessageComponent.new(
        type: "info",
        message: long_message
      )
      rendered = flash.render

      rendered.should contain(long_message)
      rendered.should contain("flex-1")
    end
  end

  describe "css_selector" do
    it "returns correct selector for success" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "success",
        message: "Test"
      )

      flash.css_selector.should eq(".bg-green-50.border-green-200")
    end

    it "returns correct selector for error" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "error",
        message: "Test"
      )

      flash.css_selector.should eq(".bg-red-50.border-red-200")
    end

    it "returns correct selector for warning" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "warning",
        message: "Test"
      )

      flash.css_selector.should eq(".bg-yellow-50.border-yellow-200")
    end

    it "returns correct selector for info" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "info",
        message: "Test"
      )

      flash.css_selector.should eq(".bg-blue-50.border-blue-200")
    end
  end

  describe "caching" do
    it "generates cache keys" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "success",
        message: "Test message"
      )

      flash.cache_key.should be_a(String)
      flash.cache_key.should_not be_empty
    end

    it "generates same cache key for identical messages" do
      flash1 = Components::Shared::FlashMessageComponent.new(
        type: "success",
        message: "Test"
      )
      flash2 = Components::Shared::FlashMessageComponent.new(
        type: "success",
        message: "Test"
      )

      flash1.cache_key.should eq(flash2.cache_key)
    end

    it "generates different cache keys for different messages" do
      flash1 = Components::Shared::FlashMessageComponent.new(
        type: "success",
        message: "Message 1"
      )
      flash2 = Components::Shared::FlashMessageComponent.new(
        type: "success",
        message: "Message 2"
      )

      flash1.cache_key.should_not eq(flash2.cache_key)
    end

    it "generates different cache keys for different types" do
      flash1 = Components::Shared::FlashMessageComponent.new(
        type: "success",
        message: "Test"
      )
      flash2 = Components::Shared::FlashMessageComponent.new(
        type: "error",
        message: "Test"
      )

      flash1.cache_key.should_not eq(flash2.cache_key)
    end

    it "is cacheable" do
      flash = Components::Shared::FlashMessageComponent.new(
        type: "info",
        message: "Test"
      )

      flash.cacheable?.should be_true
    end
  end
end
