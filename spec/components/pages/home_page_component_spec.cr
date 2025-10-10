require "../component_spec_helper"
require "../../../src/views/components/pages/home_page_component"

describe Components::Pages::HomePageComponent do
  describe "rendering" do
    it "renders hero section" do
      home = Components::Pages::HomePageComponent.new
      rendered = home.render

      rendered.should contain("Build amazing")
      rendered.should contain("applications faster")
      rendered.should contain("AgentC provides a powerful foundation")
    end

    it "shows Get started button when not logged in" do
      home = Components::Pages::HomePageComponent.new(
        logged_in: "false"
      )
      rendered = home.render

      rendered.should contain("Get started")
      rendered.should contain("href=\"/login\"")
    end

    it "shows Go to Dashboard button when logged in" do
      home = Components::Pages::HomePageComponent.new(
        logged_in: "true"
      )
      rendered = home.render

      rendered.should contain("Go to Dashboard")
      rendered.should contain("href=\"/dashboard\"")
    end

    it "renders Documentation link" do
      home = Components::Pages::HomePageComponent.new
      rendered = home.render

      rendered.should contain("Documentation")
      rendered.should contain("https://docs.amberframework.org")
      rendered.should contain("target=\"_blank\"")
    end

    it "renders hero decorative SVG" do
      home = Components::Pages::HomePageComponent.new
      rendered = home.render

      rendered.should contain("<polygon points=\"50,0 100,0 50,100 0,100\"")
    end

    it "renders hero gradient section" do
      home = Components::Pages::HomePageComponent.new
      rendered = home.render

      rendered.should contain("bg-gradient-to-r from-purple-400 via-pink-500 to-red-500")
      rendered.should contain("Powered by Crystal & Amber")
    end

    it "renders Features section header" do
      home = Components::Pages::HomePageComponent.new
      rendered = home.render

      rendered.should contain("Features")
      rendered.should contain("Everything you need to build great apps")
      rendered.should contain("Built with modern technologies")
    end

    it "renders Lightning Fast feature" do
      home = Components::Pages::HomePageComponent.new
      rendered = home.render

      rendered.should contain("Lightning Fast")
      rendered.should contain("Built with Crystal language for exceptional performance")
    end

    it "renders Type Safe feature" do
      home = Components::Pages::HomePageComponent.new
      rendered = home.render

      rendered.should contain("Type Safe")
      rendered.should contain("Compile-time type checking")
    end

    it "renders Developer Friendly feature" do
      home = Components::Pages::HomePageComponent.new
      rendered = home.render

      rendered.should contain("Developer Friendly")
      rendered.should contain("Familiar syntax and powerful features")
    end

    it "renders Production Ready feature" do
      home = Components::Pages::HomePageComponent.new
      rendered = home.render

      rendered.should contain("Production Ready")
      rendered.should contain("Built-in security, testing, and deployment tools")
    end

    it "renders Resources section header" do
      home = Components::Pages::HomePageComponent.new
      rendered = home.render

      rendered.should contain("Learn More")
      rendered.should contain("Explore these resources")
    end

    it "renders Amber Documentation resource" do
      home = Components::Pages::HomePageComponent.new
      rendered = home.render

      rendered.should contain("Amber Documentation")
      rendered.should contain("https://docs.amberframework.org")
      rendered.should contain("Complete guide to building applications")
    end

    it "renders Awesome Crystal resource" do
      home = Components::Pages::HomePageComponent.new
      rendered = home.render

      rendered.should contain("Awesome Crystal")
      rendered.should contain("https://github.com/veelenga/awesome-crystal")
      rendered.should contain("Curated list of awesome Crystal projects")
    end

    it "renders Discord resource" do
      home = Components::Pages::HomePageComponent.new
      rendered = home.render

      rendered.should contain("Join Discord")
      rendered.should contain("https://discord.gg/vwvP5zakSn")
      rendered.should contain("Connect with the Amber community")
    end

    it "uses proper layout structure" do
      home = Components::Pages::HomePageComponent.new
      rendered = home.render

      rendered.should contain("max-w-7xl")
      rendered.should contain("mx-auto")
    end

    it "uses responsive classes" do
      home = Components::Pages::HomePageComponent.new
      rendered = home.render

      rendered.should contain("sm:")
      rendered.should contain("md:")
      rendered.should contain("lg:")
      rendered.should contain("xl:")
    end
  end

  describe "css_selector" do
    it "returns correct selector" do
      home = Components::Pages::HomePageComponent.new

      home.css_selector.should eq(".relative.bg-white.overflow-hidden")
    end
  end

  describe "caching" do
    it "generates cache keys" do
      home = Components::Pages::HomePageComponent.new

      home.cache_key.should be_a(String)
      home.cache_key.should_not be_empty
    end

    it "generates same cache key for identical pages" do
      home1 = Components::Pages::HomePageComponent.new(logged_in: "false")
      home2 = Components::Pages::HomePageComponent.new(logged_in: "false")

      home1.cache_key.should eq(home2.cache_key)
    end

    it "generates different cache keys for different login states" do
      home1 = Components::Pages::HomePageComponent.new(logged_in: "false")
      home2 = Components::Pages::HomePageComponent.new(logged_in: "true")

      home1.cache_key.should_not eq(home2.cache_key)
    end

    it "is cacheable" do
      home = Components::Pages::HomePageComponent.new

      home.cacheable?.should be_true
    end
  end
end
