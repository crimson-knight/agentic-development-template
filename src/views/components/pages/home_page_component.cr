require "../../../../lib/asset_pipeline/src/components/base/stateless_component"

module Components
  module Pages
    # Home page component with hero, features, and resources sections
    #
    # Usage:
    #   home = HomePageComponent.new(
    #     logged_in: "false"
    #   )
    #   home.render
    #
    # Attributes:
    #   - logged_in: Whether user is authenticated - "true" or "false" (default: "false")
    class HomePageComponent < StatelessComponent
      def render_content : String
        # Extract attributes
        logged_in = @attributes["logged_in"]? == "true"

        # Determine CTA button based on login status
        cta_href = logged_in ? "/dashboard" : "/login"
        cta_text = logged_in ? "Go to Dashboard" : "Get started"

        # Build HTML
        String.build do |html|
          # Hero Section
          html << "<div data-component=\"home-page\" class=\"relative bg-white overflow-hidden\">"
          html << "<div class=\"max-w-7xl mx-auto\">"
          html << "<div class=\"relative z-10 pb-8 bg-white sm:pb-16 md:pb-20 lg:max-w-2xl lg:w-full lg:pb-28 xl:pb-32\">"

          # Decorative SVG
          html << "<svg class=\"hidden lg:block absolute right-0 inset-y-0 h-full w-48 text-white transform translate-x-1/2\" fill=\"currentColor\" viewBox=\"0 0 100 100\" preserveAspectRatio=\"none\" aria-hidden=\"true\">"
          html << "<polygon points=\"50,0 100,0 50,100 0,100\" />"
          html << "</svg>"

          # Hero content
          html << "<main class=\"mt-10 mx-auto max-w-7xl px-4 sm:mt-12 sm:px-6 md:mt-16 lg:mt-20 lg:px-8 xl:mt-28\">"
          html << "<div class=\"sm:text-center lg:text-left\">"

          # Title
          html << "<h1 class=\"text-4xl tracking-tight font-extrabold text-gray-900 sm:text-5xl md:text-6xl\">"
          html << "<span class=\"block xl:inline\">Build amazing</span> "
          html << "<span class=\"block text-indigo-600 xl:inline\">applications faster</span>"
          html << "</h1>"

          # Description
          html << "<p class=\"mt-3 text-base text-gray-500 sm:mt-5 sm:text-lg sm:max-w-xl sm:mx-auto md:mt-5 md:text-xl lg:mx-0\">"
          html << "AgentC provides a powerful foundation for building modern web applications with Crystal and Amber. Get started quickly with our comprehensive template and best practices."
          html << "</p>"

          # CTA Buttons
          html << "<div class=\"mt-5 sm:mt-8 sm:flex sm:justify-center lg:justify-start\">"
          html << "<div class=\"rounded-md shadow\">"
          html << "<a href=\"#{cta_href}\" class=\"w-full flex items-center justify-center px-8 py-3 border border-transparent text-base font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 md:py-4 md:text-lg md:px-10 transition-colors duration-200\">"
          html << cta_text
          html << "</a>"
          html << "</div>"
          html << "<div class=\"mt-3 sm:mt-0 sm:ml-3\">"
          html << "<a href=\"https://docs.amberframework.org\" target=\"_blank\" class=\"w-full flex items-center justify-center px-8 py-3 border border-transparent text-base font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 md:py-4 md:text-lg md:px-10 transition-colors duration-200\">"
          html << "Documentation"
          html << "</a>"
          html << "</div>"
          html << "</div>"

          html << "</div>"
          html << "</main>"
          html << "</div>"
          html << "</div>"

          # Hero image/gradient section
          html << "<div class=\"lg:absolute lg:inset-y-0 lg:right-0 lg:w-1/2\">"
          html << "<div class=\"h-56 w-full bg-gradient-to-r from-purple-400 via-pink-500 to-red-500 sm:h-72 md:h-96 lg:w-full lg:h-full flex items-center justify-center\">"
          html << "<div class=\"text-white text-center\">"
          html << "<svg class=\"mx-auto h-24 w-24 mb-4\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">"
          html << "<path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M13 10V3L4 14h7v7l9-11h-7z\"></path>"
          html << "</svg>"
          html << "<p class=\"text-xl font-semibold\">Powered by Crystal & Amber</p>"
          html << "</div>"
          html << "</div>"
          html << "</div>"
          html << "</div>"

          # Features Section
          html << "<div class=\"py-12 bg-white\">"
          html << "<div class=\"max-w-7xl mx-auto px-4 sm:px-6 lg:px-8\">"

          # Features header
          html << "<div class=\"lg:text-center\">"
          html << "<h2 class=\"text-base text-indigo-600 font-semibold tracking-wide uppercase\">Features</h2>"
          html << "<p class=\"mt-2 text-3xl leading-8 font-extrabold tracking-tight text-gray-900 sm:text-4xl\">Everything you need to build great apps</p>"
          html << "<p class=\"mt-4 max-w-2xl text-xl text-gray-500 lg:mx-auto\">Built with modern technologies and best practices to help you ship faster.</p>"
          html << "</div>"

          # Features grid
          html << "<div class=\"mt-10\">"
          html << "<dl class=\"space-y-10 md:space-y-0 md:grid md:grid-cols-2 md:gap-x-8 md:gap-y-10\">"

          # Feature 1: Lightning Fast
          html << "<div class=\"relative\">"
          html << "<dt>"
          html << "<div class=\"absolute flex items-center justify-center h-12 w-12 rounded-md bg-indigo-500 text-white\">"
          html << "<svg class=\"h-6 w-6\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">"
          html << "<path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M13 10V3L4 14h7v7l9-11h-7z\"></path>"
          html << "</svg>"
          html << "</div>"
          html << "<p class=\"ml-16 text-lg leading-6 font-medium text-gray-900\">Lightning Fast</p>"
          html << "</dt>"
          html << "<dd class=\"mt-2 ml-16 text-base text-gray-500\">Built with Crystal language for exceptional performance and speed.</dd>"
          html << "</div>"

          # Feature 2: Type Safe
          html << "<div class=\"relative\">"
          html << "<dt>"
          html << "<div class=\"absolute flex items-center justify-center h-12 w-12 rounded-md bg-indigo-500 text-white\">"
          html << "<svg class=\"h-6 w-6\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">"
          html << "<path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z\"></path>"
          html << "</svg>"
          html << "</div>"
          html << "<p class=\"ml-16 text-lg leading-6 font-medium text-gray-900\">Type Safe</p>"
          html << "</dt>"
          html << "<dd class=\"mt-2 ml-16 text-base text-gray-500\">Compile-time type checking helps catch errors before they reach production.</dd>"
          html << "</div>"

          # Feature 3: Developer Friendly
          html << "<div class=\"relative\">"
          html << "<dt>"
          html << "<div class=\"absolute flex items-center justify-center h-12 w-12 rounded-md bg-indigo-500 text-white\">"
          html << "<svg class=\"h-6 w-6\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">"
          html << "<path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z\"></path>"
          html << "</svg>"
          html << "</div>"
          html << "<p class=\"ml-16 text-lg leading-6 font-medium text-gray-900\">Developer Friendly</p>"
          html << "</dt>"
          html << "<dd class=\"mt-2 ml-16 text-base text-gray-500\">Familiar syntax and powerful features make development a joy.</dd>"
          html << "</div>"

          # Feature 4: Production Ready
          html << "<div class=\"relative\">"
          html << "<dt>"
          html << "<div class=\"absolute flex items-center justify-center h-12 w-12 rounded-md bg-indigo-500 text-white\">"
          html << "<svg class=\"h-6 w-6\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">"
          html << "<path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10\"></path>"
          html << "</svg>"
          html << "</div>"
          html << "<p class=\"ml-16 text-lg leading-6 font-medium text-gray-900\">Production Ready</p>"
          html << "</dt>"
          html << "<dd class=\"mt-2 ml-16 text-base text-gray-500\">Built-in security, testing, and deployment tools for enterprise applications.</dd>"
          html << "</div>"

          html << "</dl>"
          html << "</div>"
          html << "</div>"
          html << "</div>"

          # Resources Section
          html << "<div class=\"bg-gray-50\">"
          html << "<div class=\"max-w-7xl mx-auto py-12 px-4 sm:px-6 lg:py-16 lg:px-8\">"

          # Resources header
          html << "<div class=\"lg:text-center\">"
          html << "<h2 class=\"text-3xl font-extrabold text-gray-900\">Learn More</h2>"
          html << "<p class=\"mt-4 text-lg text-gray-500\">Explore these resources to get the most out of your development experience.</p>"
          html << "</div>"

          # Resources grid
          html << "<div class=\"mt-10 grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3\">"

          # Resource 1: Amber Documentation
          html << "<div class=\"bg-white overflow-hidden shadow rounded-lg\">"
          html << "<div class=\"p-6\">"
          html << "<div class=\"flex items-center\">"
          html << "<div class=\"flex-shrink-0\">"
          html << "<svg class=\"h-8 w-8 text-indigo-600\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">"
          html << "<path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253\"></path>"
          html << "</svg>"
          html << "</div>"
          html << "<div class=\"ml-4\">"
          html << "<h3 class=\"text-lg font-medium text-gray-900\">"
          html << "<a href=\"https://docs.amberframework.org\" target=\"_blank\" class=\"hover:text-indigo-600\">Amber Documentation</a>"
          html << "</h3>"
          html << "<p class=\"mt-2 text-sm text-gray-500\">Complete guide to building applications with the Amber framework.</p>"
          html << "</div>"
          html << "</div>"
          html << "</div>"
          html << "</div>"

          # Resource 2: Awesome Crystal
          html << "<div class=\"bg-white overflow-hidden shadow rounded-lg\">"
          html << "<div class=\"p-6\">"
          html << "<div class=\"flex items-center\">"
          html << "<div class=\"flex-shrink-0\">"
          html << "<svg class=\"h-8 w-8 text-indigo-600\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">"
          html << "<path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10\"></path>"
          html << "</svg>"
          html << "</div>"
          html << "<div class=\"ml-4\">"
          html << "<h3 class=\"text-lg font-medium text-gray-900\">"
          html << "<a href=\"https://github.com/veelenga/awesome-crystal\" target=\"_blank\" class=\"hover:text-indigo-600\">Awesome Crystal</a>"
          html << "</h3>"
          html << "<p class=\"mt-2 text-sm text-gray-500\">Curated list of awesome Crystal projects, libraries, and resources.</p>"
          html << "</div>"
          html << "</div>"
          html << "</div>"
          html << "</div>"

          # Resource 3: Discord
          html << "<div class=\"bg-white overflow-hidden shadow rounded-lg\">"
          html << "<div class=\"p-6\">"
          html << "<div class=\"flex items-center\">"
          html << "<div class=\"flex-shrink-0\">"
          html << "<svg class=\"h-8 w-8 text-indigo-600\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">"
          html << "<path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z\"></path>"
          html << "</svg>"
          html << "</div>"
          html << "<div class=\"ml-4\">"
          html << "<h3 class=\"text-lg font-medium text-gray-900\">"
          html << "<a href=\"https://discord.gg/vwvP5zakSn\" target=\"_blank\" class=\"hover:text-indigo-600\">Join Discord</a>"
          html << "</h3>"
          html << "<p class=\"mt-2 text-sm text-gray-500\">Connect with the Amber community and get help from other developers.</p>"
          html << "</div>"
          html << "</div>"
          html << "</div>"
          html << "</div>"

          html << "</div>"
          html << "</div>"
          html << "</div>"
        end
      end

      def css_selector : String
        ".relative.bg-white.overflow-hidden"
      end
    end
  end
end
