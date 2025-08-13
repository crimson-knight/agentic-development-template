require "mcprotocol"

module ApiControllers
  class McpController < ApplicationController
    # Basic MCP handshake endpoint
    # Returns the MCP protocol version and capabilities
    def handshake
      # Create a basic handshake response
      handshake_response = {
        protocol_version: "1.0.0",
        implementation: {
          name: "agentc_app_template",
          version: "0.1.0"
        },
        capabilities: {
          tools: {
            supports: true
          },
          resources: {
            supports: false
          },
          prompts: {
            supports: false
          }
        }
      }

      respond_with do
        json handshake_response.to_json
      end
    end
  end
end