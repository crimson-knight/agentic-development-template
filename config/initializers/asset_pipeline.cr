require "asset_pipeline"

module AssetConfig
  class_property front_loader : AssetPipeline::FrontLoader?

  def self.initialize_assets
    @@front_loader = AssetPipeline::FrontLoader.new(
      js_source_path: Path["src/javascript"],
      js_output_path: Path["public/javascript"],
      # Enable cache clearing in development, disable in production
      clear_cache_upon_change: Amber.env.development?
    ) do |import_maps|
      # Application JavaScript import map
      app_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])

      # Stimulus JS for interactive components
      app_map.add_import(
        "@hotwired/stimulus",
        "https://unpkg.com/@hotwired/stimulus@3.2.2/dist/stimulus.js"
      )

      # Turbo for seamless page updates (optional)
      app_map.add_import(
        "@hotwired/turbo",
        "https://unpkg.com/@hotwired/turbo@7.3.0/dist/turbo.es2017-esm.js"
      )

      # Default login controller
      app_map.add_import("login_controller", "src/javascript/login_controller.js")

      # --- Add your custom JavaScript modules here ---
      # Example:
      # app_map.add_import("my-module", "/javascript/my_module.js")

      import_maps << app_map
    end
  end

  # Get import map HTML for views
  def self.import_map_html
    front_loader.try(&.render_import_map_tag) || ""
  end
end

# Initialize assets on application startup
AssetConfig.initialize_assets
