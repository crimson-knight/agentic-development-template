FRONT_LOADER = AssetPipeline::FrontLoader.new(js_source_path: Path["src/javascript"], js_output_path: Path["public/javascript"]) do |import_maps|
  import_map = AssetPipeline::ImportMap.new

  import_map.add_import("@hotwired/stimulus", "https://unpkg.com/@hotwired/stimulus/dist/stimulus.js")

  ## Add new controllers below here

  import_maps << import_map
end