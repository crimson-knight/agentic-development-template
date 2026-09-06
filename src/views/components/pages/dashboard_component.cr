require "asset_pipeline/components/base/stateless_component"
require "../shared/stat_card_component"

module Components
  module Pages
    # Dashboard page component with stats, activity, and actions
    #
    # Usage:
    #   dashboard = DashboardComponent.new(
    #     user_email: "user@example.com"
    #   )
    #   dashboard.render
    #
    # Attributes:
    #   - user_email: User's email for personalization (optional)
    class DashboardComponent < StatelessComponent
      def render_content : String
        # Extract attributes
        user_email = @attributes["user_email"]?

        # Build stat cards using StatCardComponent
        stat1 = Shared::StatCardComponent.new(
          title: "Total Users",
          value: "1,247",
          icon_path: "M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z",
          trend_direction: "up",
          trend_value: "12%",
          bg_color: "indigo"
        )

        stat2 = Shared::StatCardComponent.new(
          title: "Revenue",
          value: "$24,780",
          icon_path: "M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z",
          trend_direction: "up",
          trend_value: "8%",
          bg_color: "indigo"
        )

        stat3 = Shared::StatCardComponent.new(
          title: "Growth Rate",
          value: "24.7%",
          icon_path: "M13 7h8m0 0v8m0-8l-8 8-4-4-6 6",
          trend_direction: "up",
          trend_value: "3.2%",
          bg_color: "indigo"
        )

        stat4 = Shared::StatCardComponent.new(
          title: "Conversion",
          value: "3.24%",
          icon_path: "M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1",
          trend_direction: "down",
          trend_value: "1.2%",
          bg_color: "indigo"
        )

        # Build HTML
        String.build do |html|
          # Wrapper with data attribute
          html << "<div data-component=\"dashboard-page\">"

          # Header
          html << "<div class=\"px-4 sm:px-6 lg:px-8\">"
          html << "<div class=\"sm:flex sm:items-center\">"
          html << "<div class=\"sm:flex-auto\">"
          html << "<h1 class=\"text-2xl font-semibold text-gray-900\">Dashboard</h1>"
          html << "<p class=\"mt-2 text-sm text-gray-700\">Welcome back! Here's what's happening with your account.</p>"
          html << "</div>"
          html << "<div class=\"mt-4 sm:mt-0 sm:ml-16 sm:flex-none\">"
          html << "<button type=\"button\" class=\"inline-flex items-center justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:w-auto\">"
          html << "<svg class=\"-ml-1 mr-2 h-4 w-4\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">"
          html << "<path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M12 6v6m0 0v6m0-6h6m-6 0H6\"></path>"
          html << "</svg>"
          html << "New Project"
          html << "</button>"
          html << "</div>"
          html << "</div>"
          html << "</div>"

          # Stats Grid
          html << "<div class=\"mt-8 px-4 sm:px-6 lg:px-8\">"
          html << "<dl class=\"grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4\">"
          html << stat1.render
          html << stat2.render
          html << stat3.render
          html << stat4.render
          html << "</dl>"
          html << "</div>"

          # Main Content Grid
          html << "<div class=\"mt-8 px-4 sm:px-6 lg:px-8\">"
          html << "<div class=\"grid grid-cols-1 gap-6 lg:grid-cols-2\">"

          # Recent Activity
          html << "<div class=\"bg-white overflow-hidden shadow rounded-lg\">"
          html << "<div class=\"px-4 py-5 sm:p-6\">"
          html << "<h3 class=\"text-lg leading-6 font-medium text-gray-900\">Recent Activity</h3>"
          html << "<div class=\"mt-5\">"
          html << "<div class=\"flow-root\">"
          html << "<ul role=\"list\" class=\"-mb-8\">"

          # Activity Item 1
          html << "<li>"
          html << "<div class=\"relative pb-8\">"
          html << "<span class=\"absolute top-5 left-5 -ml-px h-full w-0.5 bg-gray-200\" aria-hidden=\"true\"></span>"
          html << "<div class=\"relative flex items-start space-x-3\">"
          html << "<div class=\"relative\">"
          html << "<div class=\"h-10 w-10 rounded-full bg-green-500 flex items-center justify-center ring-8 ring-white\">"
          html << "<svg class=\"h-5 w-5 text-white\" fill=\"currentColor\" viewBox=\"0 0 20 20\">"
          html << "<path fill-rule=\"evenodd\" d=\"M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z\" clip-rule=\"evenodd\" />"
          html << "</svg>"
          html << "</div>"
          html << "</div>"
          html << "<div class=\"min-w-0 flex-1\">"
          html << "<div>"
          html << "<div class=\"text-sm\">"
          html << "<span class=\"font-medium text-gray-900\">New user registration</span>"
          html << "</div>"
          html << "<p class=\"mt-0.5 text-sm text-gray-500\">2 minutes ago</p>"
          html << "</div>"
          html << "<div class=\"mt-2 text-sm text-gray-700\">"
          html << "<p>john.doe@example.com signed up for a new account</p>"
          html << "</div>"
          html << "</div>"
          html << "</div>"
          html << "</div>"
          html << "</li>"

          # Activity Item 2
          html << "<li>"
          html << "<div class=\"relative pb-8\">"
          html << "<span class=\"absolute top-5 left-5 -ml-px h-full w-0.5 bg-gray-200\" aria-hidden=\"true\"></span>"
          html << "<div class=\"relative flex items-start space-x-3\">"
          html << "<div class=\"relative\">"
          html << "<div class=\"h-10 w-10 rounded-full bg-blue-500 flex items-center justify-center ring-8 ring-white\">"
          html << "<svg class=\"h-5 w-5 text-white\" fill=\"currentColor\" viewBox=\"0 0 20 20\">"
          html << "<path d=\"M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z\" />"
          html << "</svg>"
          html << "</div>"
          html << "</div>"
          html << "<div class=\"min-w-0 flex-1\">"
          html << "<div>"
          html << "<div class=\"text-sm\">"
          html << "<span class=\"font-medium text-gray-900\">Payment processed</span>"
          html << "</div>"
          html << "<p class=\"mt-0.5 text-sm text-gray-500\">1 hour ago</p>"
          html << "</div>"
          html << "<div class=\"mt-2 text-sm text-gray-700\">"
          html << "<p>$299.00 payment received from Premium Plan subscription</p>"
          html << "</div>"
          html << "</div>"
          html << "</div>"
          html << "</div>"
          html << "</li>"

          # Activity Item 3
          html << "<li>"
          html << "<div class=\"relative\">"
          html << "<div class=\"relative flex items-start space-x-3\">"
          html << "<div class=\"relative\">"
          html << "<div class=\"h-10 w-10 rounded-full bg-yellow-500 flex items-center justify-center ring-8 ring-white\">"
          html << "<svg class=\"h-5 w-5 text-white\" fill=\"currentColor\" viewBox=\"0 0 20 20\">"
          html << "<path fill-rule=\"evenodd\" d=\"M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z\" clip-rule=\"evenodd\" />"
          html << "</svg>"
          html << "</div>"
          html << "</div>"
          html << "<div class=\"min-w-0 flex-1\">"
          html << "<div>"
          html << "<div class=\"text-sm\">"
          html << "<span class=\"font-medium text-gray-900\">System maintenance</span>"
          html << "</div>"
          html << "<p class=\"mt-0.5 text-sm text-gray-500\">3 hours ago</p>"
          html << "</div>"
          html << "<div class=\"mt-2 text-sm text-gray-700\">"
          html << "<p>Scheduled maintenance completed successfully</p>"
          html << "</div>"
          html << "</div>"
          html << "</div>"
          html << "</div>"
          html << "</li>"

          html << "</ul>"
          html << "</div>"
          html << "</div>"
          html << "</div>"
          html << "</div>"

          # Quick Actions
          html << "<div class=\"bg-white overflow-hidden shadow rounded-lg\">"
          html << "<div class=\"px-4 py-5 sm:p-6\">"
          html << "<h3 class=\"text-lg leading-6 font-medium text-gray-900\">Quick Actions</h3>"
          html << "<div class=\"mt-5 grid grid-cols-1 gap-4\">"

          # Action 1
          html << "<button type=\"button\" class=\"relative block w-full rounded-lg border-2 border-dashed border-gray-300 p-6 text-center hover:border-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2\">"
          html << "<svg class=\"mx-auto h-8 w-8 text-gray-400\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">"
          html << "<path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M12 6v6m0 0v6m0-6h6m-6 0H6\"></path>"
          html << "</svg>"
          html << "<span class=\"mt-2 block text-sm font-medium text-gray-900\">Create New Project</span>"
          html << "</button>"

          # Action 2
          html << "<button type=\"button\" class=\"relative block w-full rounded-lg border-2 border-dashed border-gray-300 p-6 text-center hover:border-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2\">"
          html << "<svg class=\"mx-auto h-8 w-8 text-gray-400\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">"
          html << "<path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z\"></path>"
          html << "</svg>"
          html << "<span class=\"mt-2 block text-sm font-medium text-gray-900\">Invite Team Members</span>"
          html << "</button>"

          # Action 3
          html << "<button type=\"button\" class=\"relative block w-full rounded-lg border-2 border-dashed border-gray-300 p-6 text-center hover:border-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2\">"
          html << "<svg class=\"mx-auto h-8 w-8 text-gray-400\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">"
          html << "<path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z\"></path>"
          html << "</svg>"
          html << "<span class=\"mt-2 block text-sm font-medium text-gray-900\">View Analytics</span>"
          html << "</button>"

          html << "</div>"
          html << "</div>"
          html << "</div>"

          html << "</div>"
          html << "</div>"

          # Close wrapper
          html << "</div>"
        end
      end

      def css_selector : String
        "[data-component=\"dashboard-page\"]"
      end
    end
  end
end
