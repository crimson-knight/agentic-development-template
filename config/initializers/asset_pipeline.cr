# This file is used to configure the asset pipeline for the Amber application.
# It sets up the import map for Stimulus controllers and other JavaScript assets.
# 
# Read more about it here: https://amberframework.github.io/asset_pipeline/AssetPipeline/FrontLoader.html
# 
JS_OUTPUT_PATH = Path["public/javascript"]

FRONT_LOADER = AssetPipeline::FrontLoader.new(js_source_path: Path["src/javascript"], js_output_path: JS_OUTPUT_PATH) do |import_maps|
  import_map = AssetPipeline::ImportMap.new("application", Path["/javascript"]) # This path must match the js_output_path above, relative to the `/public` directory

  import_map.add_import("@hotwired/stimulus", "https://unpkg.com/@hotwired/stimulus/dist/stimulus.js")

  # Default login controller for login form from `GET /login`
  import_map.add_import("login_controller", "src/javascript/login_controller.js")
  
  ## Add new controllers below here

  import_maps << import_map

  # Clear out any existing cached files from the output path
  FileUtils.rm_rf(JS_OUTPUT_PATH)
end
