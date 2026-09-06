require "spec"

# Component tests don't need database access or full Amber setup
# This lighter spec helper is for testing Asset Pipeline components in isolation

# Load Asset Pipeline component system
require "asset_pipeline/components/base/component"
require "asset_pipeline/components/base/stateless_component"
require "asset_pipeline/components/base/stateful_component"
require "asset_pipeline/components/elements/base/html_element"
