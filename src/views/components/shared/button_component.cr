require "../../../../lib/asset_pipeline/src/components/base/stateless_component"
require "../../../../lib/asset_pipeline/src/components/elements/forms/form_controls"
require "../../../../lib/asset_pipeline/src/components/elements/text/a"
require "../../../../lib/asset_pipeline/src/components/elements/grouping/span"

module Components
  module Shared
    # A reusable button component with variants, sizes, and icon support
    #
    # Usage:
    #   button = ButtonComponent.new(
    #     label: "Click Me",
    #     variant: "primary",
    #     size: "medium"
    #   )
    #   button.render # => HTML string
    #
    # Attributes:
    #   - label: Button text
    #   - variant: "primary", "secondary", "danger" (default: "primary")
    #   - size: "small", "medium", "large" (default: "medium")
    #   - type: "button", "submit" (default: "button")
    #   - disabled: "true" or nil
    #   - icon: Optional icon/emoji
    #   - href: If provided, renders as link styled as button
    #   - class: Additional CSS classes
    class ButtonComponent < StatelessComponent
      def render_content : String
        # Extract attributes
        label = @attributes["label"]? || "Button"
        variant = @attributes["variant"]? || "primary"
        size = @attributes["size"]? || "medium"
        type = @attributes["type"]? || "button"
        disabled = @attributes["disabled"]? == "true"
        icon = @attributes["icon"]?
        href = @attributes["href"]?
        additional_classes = @attributes["class"]?

        # Build CSS classes
        classes = ["btn", "btn-#{variant}", "btn-#{size}"]
        classes << "disabled" if disabled
        classes << additional_classes if additional_classes
        class_string = classes.join(" ")

        # Render as link if href provided
        if href
          link = Elements::A.new(
            href: href,
            class: class_string
          )

          # Add icon if provided
          if icon
            span = Elements::Span.new(class: "btn-icon")
            span << icon
            link << span
            link << " "
          end

          # Add label
          link << label

          # Add children
          @children.each do |child|
            link << " "
            append_child(link, child)
          end

          return link.render
        end

        # Render as button
        button = Elements::Button.new(
          type: type,
          class: class_string,
          disabled: disabled ? "true" : nil
        )

        # Add icon if provided
        if icon
          span = Elements::Span.new(class: "btn-icon")
          span << icon
          button << span
          button << " "
        end

        # Add label
        button << label

        # Add children
        @children.each do |child|
          button << " "
          append_child(button, child)
        end

        button.render
      end

      # CSS selector for testing
      def css_selector : String
        variant = @attributes["variant"]? || "primary"
        size = @attributes["size"]? || "medium"
        ".btn.btn-#{variant}.btn-#{size}"
      end

      private def append_child(parent, child)
        case child
        when Component
          parent << child.render
        when Elements::HTMLElement
          parent << child
        when String
          parent << child
        end
      end
    end
  end
end
