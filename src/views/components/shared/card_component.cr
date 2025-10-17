require "../../../../lib/asset_pipeline/src/components/base/stateless_component"
require "../../../../lib/asset_pipeline/src/components/elements/grouping/div"
require "../../../../lib/asset_pipeline/src/components/elements/text/a"
require "../../../../lib/asset_pipeline/src/components/elements/grouping/p"
require "./icon_component"

module Components
  module Shared
    # Reusable content card component with icon, title, and description
    #
    # Usage:
    #   card = CardComponent.new(
    #     title: "Lightning Fast",
    #     description: "Built with performance in mind",
    #     icon_path: "M13 10V3L4 14h7v7l9-11h-7z",
    #     link_href: "https://example.com",
    #     link_text: "Learn more",
    #     link_target: "_blank"
    #   )
    #   card.render
    #
    # Attributes:
    #   - title: Card title (required)
    #   - description: Card description (required)
    #   - icon_path: SVG path data for the icon (optional)
    #   - icon_color: Icon color class (default: "text-indigo-600")
    #   - icon_bg_color: Icon background color (default: "bg-indigo-100")
    #   - link_href: URL for the card link (optional)
    #   - link_text: Text for the link (default: "Learn more →")
    #   - link_target: Link target attribute (default: nil)
    #   - card_class: Additional CSS classes for the card container (optional)
    class CardComponent < StatelessComponent
      def render_content : String
        # Extract attributes
        title = @attributes["title"]? || ""
        description = @attributes["description"]? || ""
        icon_path = @attributes["icon_path"]?
        icon_color = @attributes["icon_color"]? || "text-indigo-600"
        icon_bg_color = @attributes["icon_bg_color"]? || "bg-indigo-100"
        link_href = @attributes["link_href"]?
        link_text = @attributes["link_text"]? || "Learn more →"
        link_target = @attributes["link_target"]?
        card_class = @attributes["card_class"]?

        # Build card classes
        card_classes = ["bg-white", "rounded-lg", "shadow-md", "p-6", "hover:shadow-lg", "transition-shadow", "duration-300"]
        card_classes << card_class if card_class

        # Build card content as string
        content = String.build do |html|
          # Add icon if provided
          if icon_path
            icon = IconComponent.new(
              path: icon_path,
              size: "h-6 w-6",
              color: icon_color
            )
            html << "<div class=\"#{icon_bg_color} rounded-lg p-3 inline-block mb-4\">"
            html << icon.render
            html << "</div>"
          end

          # Add title
          html << "<div class=\"text-xl font-semibold text-gray-900 mb-2\">#{title}</div>"

          # Add description
          html << "<p class=\"text-gray-600 mb-4\">#{description}</p>"

          # Add link if provided
          if link_href
            target_attr = link_target ? " target=\"#{link_target}\"" : ""
            rel_attr = link_target == "_blank" ? " rel=\"noopener noreferrer\"" : ""
            html << "<a href=\"#{link_href}\" class=\"text-indigo-600 hover:text-indigo-700 font-medium inline-flex items-center\"#{target_attr}#{rel_attr}>#{link_text}</a>"
          end
        end

        # Wrap in card div with data attributes
        "<div data-component=\"card\" class=\"#{card_classes.join(" ")}\">#{content}</div>"
      end

      def css_selector : String
        ".bg-white.rounded-lg.shadow-md"
      end
    end
  end
end
