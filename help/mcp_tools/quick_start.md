# MCP Tools Quick Start Guide

## Creating Your First MCP Tool in 5 Minutes

### Step 1: Create the Tool File

Create a new file `src/mcp_tools/hello_world_tool.cr`:

```crystal
require "mcprotocol"

module McpTools
  class HelloWorldTool < MCProtocol::Tool
    def self.metadata
      {
        name: "hello_world",
        description: "A simple greeting tool",
        parameters: {
          type: "object",
          properties: {
            name: {
              type: "string",
              description: "Name to greet"
            }
          },
          required: ["name"]
        }
      }
    end

    def execute(params : JSON::Any) : JSON::Any
      name = params["name"].as_s
      
      JSON.parse({
        success: true,
        message: "Hello, #{name}!"
      }.to_json)
    end
  end
end
```

### Step 2: Register the Tool

Create or update `config/initializers/mcp_tools.cr`:

```crystal
require "../src/mcp_tools/**"

# Register your tools
McpTools::Registry.register(McpTools::HelloWorldTool)
```

### Step 3: Add the Registry (if not exists)

Create `src/mcp_tools/registry.cr`:

```crystal
module McpTools
  class Registry
    @@tools = {} of String => MCProtocol::Tool.class

    def self.register(tool_class : MCProtocol::Tool.class)
      metadata = tool_class.metadata
      @@tools[metadata[:name].to_s] = tool_class
    end

    def self.execute_tool(name : String, params : JSON::Any)
      tool_class = @@tools[name]?
      raise "Tool '#{name}' not found" unless tool_class
      
      tool = tool_class.new
      tool.execute(params)
    end

    def self.list_tools
      @@tools.map { |name, tool_class| tool_class.metadata }
    end
  end
end
```

### Step 4: Test Your Tool

Run the application and test:

```bash
# Compile and run
crystal build src/agentc_app_template_oss.cr
./agentc_app_template_oss

# In another terminal, test the handshake
curl http://localhost:3000/api/mcp/handshake

# Test your tool (once controller is set up)
curl -X POST http://localhost:3000/api/mcp/tools/hello_world/execute \
  -H "Content-Type: application/json" \
  -d '{"name": "World"}'
```

## Common Tool Patterns

### 1. Database Query Tool

```crystal
class UserSearchTool < MCProtocol::Tool
  def self.metadata
    {
      name: "user_search",
      description: "Search for users by criteria",
      parameters: {
        type: "object",
        properties: {
          query: {type: "string"},
          limit: {type: "integer", default: 10}
        },
        required: ["query"]
      }
    }
  end

  def execute(params : JSON::Any) : JSON::Any
    query = params["query"].as_s
    limit = params["limit"]?.try(&.as_i) || 10
    
    users = User.where { _name.ilike("%#{query}%") }.limit(limit).to_a
    
    JSON.parse({
      success: true,
      count: users.size,
      users: users.map(&.to_h)
    }.to_json)
  end
end
```

### 2. External API Tool

```crystal
class WeatherTool < MCProtocol::Tool
  def self.metadata
    {
      name: "weather",
      description: "Get weather for a location",
      parameters: {
        type: "object",
        properties: {
          city: {type: "string"},
          units: {
            type: "string",
            enum: ["metric", "imperial"],
            default: "metric"
          }
        },
        required: ["city"]
      }
    }
  end

  def execute(params : JSON::Any) : JSON::Any
    city = params["city"].as_s
    units = params["units"]?.try(&.as_s) || "metric"
    
    # Make API call (example)
    response = HTTP::Client.get(
      "https://api.weather.com/v1/weather?city=#{city}&units=#{units}",
      headers: HTTP::Headers{"API-Key" => ENV["WEATHER_API_KEY"]}
    )
    
    JSON.parse({
      success: true,
      weather: JSON.parse(response.body)
    }.to_json)
  end
end
```

### 3. File Processing Tool

```crystal
class CsvProcessorTool < MCProtocol::Tool
  def self.metadata
    {
      name: "csv_processor",
      description: "Process CSV files",
      parameters: {
        type: "object",
        properties: {
          file_path: {type: "string"},
          operation: {
            type: "string",
            enum: ["count", "preview", "stats"]
          }
        },
        required: ["file_path", "operation"]
      }
    }
  end

  def execute(params : JSON::Any) : JSON::Any
    file_path = params["file_path"].as_s
    operation = params["operation"].as_s
    
    unless File.exists?(file_path)
      return JSON.parse({success: false, error: "File not found"}.to_json)
    end
    
    result = case operation
    when "count"
      {rows: File.read_lines(file_path).size}
    when "preview"
      {preview: File.read_lines(file_path).first(5)}
    when "stats"
      lines = File.read_lines(file_path)
      {
        rows: lines.size,
        columns: lines.first?.try(&.split(",").size) || 0
      }
    else
      {error: "Unknown operation"}
    end
    
    JSON.parse({success: true, data: result}.to_json)
  end
end
```

## Quick Tips

1. **Always validate parameters** - Check for required fields and types
2. **Handle errors gracefully** - Return structured error responses
3. **Keep tools focused** - Each tool should do one thing well
4. **Document parameters clearly** - Use descriptive names and descriptions
5. **Test thoroughly** - Write specs for edge cases
6. **Use type safety** - Leverage Crystal's type system
7. **Consider performance** - Cache expensive operations
8. **Log important events** - Track usage and errors

## Debugging Tools

### Enable Debug Logging

```crystal
class DebugTool < MCProtocol::Tool
  def execute(params : JSON::Any) : JSON::Any
    Log.debug { "Received params: #{params.to_pretty_json}" }
    
    result = perform_operation(params)
    
    Log.debug { "Returning result: #{result.to_pretty_json}" }
    result
  end
end
```

### Test in Crystal Playground

```crystal
# Quick test script
require "./src/mcp_tools/hello_world_tool"

tool = McpTools::HelloWorldTool.new
params = JSON.parse(%({"name": "Test"}))
result = tool.execute(params)
puts result.to_pretty_json
```

## Next Steps

1. Read the [full documentation](README.md) for advanced features
2. Explore example tools in `src/mcp_tools/examples/`
3. Check the [MCP Protocol specification](https://mcprotocol.ai)
4. Join the community discussions