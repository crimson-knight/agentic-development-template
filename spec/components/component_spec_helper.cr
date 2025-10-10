require "spec"

# Component tests don't need database access or full Amber setup
# This lighter spec helper is for testing Asset Pipeline components in isolation

# Load Asset Pipeline component system
require "../../lib/asset_pipeline/src/components/base/component"
require "../../lib/asset_pipeline/src/components/base/stateless_component"
require "../../lib/asset_pipeline/src/components/base/stateful_component"
require "../../lib/asset_pipeline/src/components/elements/base/html_element"
