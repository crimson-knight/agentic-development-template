require "../../../lib/asset_pipeline/src/components/base/stateless_component"
require "./icon_component"

module Components
  module Shared
    # Flash message component with auto-styling based on type
    #
    # Usage:
    #   flash = FlashMessageComponent.new(
    #     type: "success",
    #     message: "Login successful!"
    #   )
    #   flash.render
    #
    # Attributes:
    #   - type: Message type - "success", "error", "info", "warning" (required)
    #   - message: Message text to display (required)
    #
    # Auto-styling by type:
    #   - success: Green background, checkmark icon
    #   - error: Red background, X icon
    #   - info: Blue background, info icon
    #   - warning: Yellow background, exclamation icon
    class FlashMessageComponent < StatelessComponent
      def render_content : String
        # Extract attributes
        type = @attributes["type"]? || "info"
        message = @attributes["message"]? || ""

        # Return empty string if no message
        return "" if message.empty?

        # Define styling based on type
        config = case type
                 when "success"
                   {
                     bg_color:      "bg-green-50",
                     border_color:  "border-green-200",
                     text_color:    "text-green-800",
                     icon_color:    "text-green-400",
                     icon_bg_color: "bg-green-100",
                     icon_path:     "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z", # Checkmark circle
                   }
                 when "error"
                   {
                     bg_color:      "bg-red-50",
                     border_color:  "border-red-200",
                     text_color:    "text-red-800",
                     icon_color:    "text-red-400",
                     icon_bg_color: "bg-red-100",
                     icon_path:     "M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z", # X circle
                   }
                 when "warning"
                   {
                     bg_color:      "bg-yellow-50",
                     border_color:  "border-yellow-200",
                     text_color:    "text-yellow-800",
                     icon_color:    "text-yellow-400",
                     icon_bg_color: "bg-yellow-100",
                     icon_path:     "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z", # Exclamation triangle
                   }
                 else # info
                   {
                     bg_color:      "bg-blue-50",
                     border_color:  "border-blue-200",
                     text_color:    "text-blue-800",
                     icon_color:    "text-blue-400",
                     icon_bg_color: "bg-blue-100",
                     icon_path:     "M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z", # Info circle
                   }
                 end

        # Build icon
        icon = IconComponent.new(
          path: config[:icon_path],
          size: "h-5 w-5",
          color: config[:icon_color]
        )

        # Build HTML
        String.build do |html|
          html << "<div class=\"#{config[:bg_color]} border #{config[:border_color]} rounded-lg p-4 mb-4 flex items-start\" role=\"alert\">"

          # Icon container
          html << "<div class=\"#{config[:icon_bg_color]} rounded-lg p-2 mr-3 flex-shrink-0\">"
          html << icon.render
          html << "</div>"

          # Message
          html << "<div class=\"#{config[:text_color]} text-sm font-medium flex-1\">#{message}</div>"

          html << "</div>"
        end
      end

      def css_selector : String
        type = @attributes["type"]? || "info"
        case type
        when "success"
          ".bg-green-50.border-green-200"
        when "error"
          ".bg-red-50.border-red-200"
        when "warning"
          ".bg-yellow-50.border-yellow-200"
        else
          ".bg-blue-50.border-blue-200"
        end
      end
    end
  end
end
