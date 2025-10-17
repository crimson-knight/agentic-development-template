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

        # Build HTML with data attributes
        String.build do |html|
          # Render as link if href provided
          if href
            html << "<a href=\"#{href}\" "
            html << "class=\"#{class_string}\" "
            html << "data-component=\"button\" "
            html << "data-variant=\"#{variant}\" "
            html << "data-size=\"#{size}\">"

            # Add icon if provided
            if icon
              html << "<span class=\"btn-icon\">#{icon}</span> "
            end

            # Add label
            html << label

            # Add children
            @children.each do |child|
              html << " "
              append_child_html(html, child)
            end

            html << "</a>"
          else
            # Render as button
            html << "<button type=\"#{type}\" "
            html << "class=\"#{class_string}\" "
            html << "data-component=\"button\" "
            html << "data-variant=\"#{variant}\" "
            html << "data-size=\"#{size}\" "
            html << "#{disabled ? "disabled" : ""}>"

            # Add icon if provided
            if icon
              html << "<span class=\"btn-icon\">#{icon}</span> "
            end

            # Add label
            html << label

            # Add children
            @children.each do |child|
              html << " "
              append_child_html(html, child)
            end

            html << "</button>"
          end
        end
      end

      # CSS selector for testing
      def css_selector : String
        variant = @attributes["variant"]? || "primary"
        size = @attributes["size"]? || "medium"
        ".btn.btn-#{variant}.btn-#{size}"
      end

      private def append_child_html(html, child)
        case child
        when Component
          html << child.render
        when Elements::HTMLElement
          html << child.render
        when String
          html << child
        end
      end
    end
  end
end
