# Register all MCP tools at application startup
require "../../src/mcp_tools/registry"
require "../../src/mcp_tools/**"

# Register user-specific tools
McpTools::Registry.register(McpTools::UserProfileTool)

# Add more tools as you create them
# McpTools::Registry.register(McpTools::UserDataTool)
# McpTools::Registry.register(McpTools::UserQueryTool)
# McpTools::Registry.register(McpTools::UserNotesTool)

Log.info { "Registered #{McpTools::Registry.tool_names.size} MCP tools" }
Log.debug { "Available tools: #{McpTools::Registry.tool_names.join(", ")}" }