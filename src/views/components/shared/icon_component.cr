require "asset_pipeline/components/base/stateless_component"
require "asset_pipeline/components/elements/grouping/span"

module Components
  module Shared
    # Reusable SVG icon component
    #
    # Usage:
    #   icon = IconComponent.new(
    #     path: "M13 10V3L4 14h7v7l9-11h-7z",
    #     size: "h-6 w-6",
    #     color: "text-indigo-600"
    #   )
    #   icon.render
    #
    # Attributes:
    #   - path: SVG path data (required)
    #   - size: Icon size classes (default: "h-6 w-6")
    #   - color: Icon color class (default: "currentColor")
    #   - viewBox: SVG viewBox (default: "0 0 24 24")
    #   - fill: SVG fill attribute (default: "none")
    #   - stroke: SVG stroke attribute (default: "currentColor")
    #   - stroke_width: Stroke width (default: "2")
    class IconComponent < StatelessComponent
      def render_content : String
        # Extract attributes
        path = @attributes["path"]? || ""
        size = @attributes["size"]? || "h-6 w-6"
        color = @attributes["color"]? || "currentColor"
        viewBox = @attributes["viewBox"]? || "0 0 24 24"
        fill = @attributes["fill"]? || "none"
        stroke = @attributes["stroke"]? || "currentColor"
        stroke_width = @attributes["stroke_width"]? || "2"

        # Build CSS classes
        classes = [size]
        classes << color unless color == "currentColor"
        class_string = classes.join(" ")

        # Build SVG element manually (no Elements::Svg yet)
        svg_attrs = String.build do |str|
          str << %( data-component="icon")
          str << %( class="#{class_string}")
          str << %( xmlns="http://www.w3.org/2000/svg")
          str << %( fill="#{fill}")
          str << %( viewBox="#{viewBox}")
          str << %( stroke="#{stroke}")
        end

        # Build path element
        path_attrs = String.build do |str|
          str << %( stroke-linecap="round")
          str << %( stroke-linejoin="round")
          str << %( stroke-width="#{stroke_width}")
          str << %( d="#{path}")
        end

        # Return complete SVG
        "<svg#{svg_attrs}><path#{path_attrs}></path></svg>"
      end

      # CSS selector for testing
      def css_selector : String
        size = @attributes["size"]? || "h-6 w-6"
        ".#{size.gsub(" ", ".")}"
      end
    end
  end
end
