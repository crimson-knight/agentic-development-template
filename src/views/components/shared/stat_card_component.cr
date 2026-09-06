require "asset_pipeline/components/base/stateless_component"
require "./icon_component"

module Components
  module Shared
    # Dashboard statistics card component with icon, value, and trend
    #
    # Usage:
    #   stat = StatCardComponent.new(
    #     title: "Total Users",
    #     value: "1,247",
    #     icon_path: "M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z",
    #     trend_direction: "up",
    #     trend_value: "12%",
    #     bg_color: "indigo"
    #   )
    #   stat.render
    #
    # Attributes:
    #   - title: Stat label (required)
    #   - value: Main value to display (required)
    #   - icon_path: SVG path data for the icon (optional)
    #   - trend_direction: "up", "down", or nil (default: nil)
    #   - trend_value: Trend percentage text (default: nil)
    #   - bg_color: Icon background color name (default: "indigo")
    #                Available: indigo, green, yellow, red, blue, purple, pink
    class StatCardComponent < StatelessComponent
      def render_content : String
        # Extract attributes
        title = @attributes["title"]? || ""
        value = @attributes["value"]? || "0"
        icon_path = @attributes["icon_path"]?
        trend_direction = @attributes["trend_direction"]?
        trend_value = @attributes["trend_value"]?
        bg_color = @attributes["bg_color"]? || "indigo"

        # Determine trend colors and icon
        trend_color = case trend_direction
                      when "up"   then "text-green-600"
                      when "down" then "text-red-600"
                      else             "text-gray-600"
                      end

        trend_arrow = case trend_direction
                      when "up"   then "↑"
                      when "down" then "↓"
                      else             ""
                      end

        # Build HTML
        String.build do |html|
          html << "<div data-component=\"stat-card\" data-variant=\"#{bg_color}\" class=\"bg-white rounded-lg shadow-md p-6\">"

          # Top section: icon and value
          html << "<div class=\"flex items-center justify-between mb-4\">"

          # Icon container
          if icon_path
            icon = IconComponent.new(
              path: icon_path,
              size: "h-8 w-8",
              color: "text-#{bg_color}-600"
            )
            html << "<div class=\"bg-#{bg_color}-100 rounded-lg p-3\">"
            html << icon.render
            html << "</div>"
          end

          # Value
          html << "<div class=\"text-3xl font-bold text-gray-900\">#{value}</div>"
          html << "</div>"

          # Bottom section: title and trend
          html << "<div class=\"flex items-center justify-between\">"

          # Title
          html << "<div class=\"text-sm font-medium text-gray-600\">#{title}</div>"

          # Trend
          if trend_value
            html << "<div class=\"flex items-center #{trend_color} text-sm font-medium\">"
            html << "<span>#{trend_arrow} #{trend_value}</span>"
            html << "</div>"
          end

          html << "</div>"
          html << "</div>"
        end
      end

      def css_selector : String
        ".bg-white.rounded-lg.shadow-md"
      end
    end
  end
end
