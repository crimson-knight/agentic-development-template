# MCP Tools Integration Guide

## Overview

The Model Context Protocol (MCP) is a standardized protocol for integrating AI tools and services into applications. This guide explains how to add MCP tools to this Amber application template using the `mcprotocol` Crystal shard.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Creating MCP Tools](#creating-mcp-tools)
3. [Tool Registration](#tool-registration)
4. [Handling Tool Requests](#handling-tool-requests)
5. [Authentication & Security](#authentication--security)
6. [Testing MCP Tools](#testing-mcp-tools)
7. [Best Practices](#best-practices)

## Getting Started

The application already includes the `mcprotocol` dependency in `shard.yml`:

```yaml
dependencies:
  mcprotocol:
    github: crimson-knight/mcprotocol
    branch: main
```

A basic handshake endpoint has been configured at `/api/mcp/handshake` to verify MCP connectivity.

## Creating MCP Tools

### Step 1: Define Your Tool

Create a new tool class in `src/mcp_tools/` directory:

```crystal
# src/mcp_tools/example_tool.cr
require "mcprotocol"

module McpTools
  class ExampleTool < MCProtocol::Tool
    # Define the tool metadata
    def self.metadata
      {
        name: "example_tool",
        description: "An example MCP tool that demonstrates basic functionality",
        parameters: {
          type: "object",
          properties: {
            input: {
              type: "string",
              description: "The input to process"
            },
            options: {
              type: "object",
              properties: {
                format: {
                  type: "string",
                  enum: ["json", "text", "xml"],
                  default: "json"
                }
              }
            }
          },
          required: ["input"]
        }
      }
    end

    # Implement the tool execution
    def execute(params : JSON::Any) : JSON::Any
      input = params["input"].as_s
      format = params.dig?("options", "format").try(&.as_s) || "json"
      
      # Your tool logic here
      result = process_input(input, format)
      
      JSON.parse({
        success: true,
        result: result
      }.to_json)
    end

    private def process_input(input : String, format : String) : String
      # Implement your tool's core functionality
      case format
      when "json"
        {processed: input.upcase}.to_json
      when "text"
        "Processed: #{input.upcase}"
      when "xml"
        "<result>#{input.upcase}</result>"
      else
        input.upcase
      end
    end
  end
end
```

### Step 2: Create a Tool Controller

Add tool handling to the MCP controller:

```crystal
# src/controllers/api/mcp_tools_controller.cr
require "mcprotocol"

module ApiControllers
  class McpToolsController < ApplicationController
    # List available tools
    def list
      tools = McpTools::Registry.list_tools
      
      respond_with do
        json tools.to_json
      end
    end

    # Execute a specific tool
    def execute
      tool_name = params[:name]
      tool_params = JSON.parse(request.body.to_s)
      
      result = McpTools::Registry.execute_tool(tool_name, tool_params)
      
      respond_with do
        json result.to_json
      end
    rescue ex
      respond_with(422) do
        json({error: ex.message}.to_json)
      end
    end
  end
end
```

## Tool Registration

### Creating a Tool Registry

Create a registry to manage all MCP tools:

```crystal
# src/mcp_tools/registry.cr
module McpTools
  class Registry
    @@tools = {} of String => MCProtocol::Tool.class

    # Register a tool
    def self.register(tool_class : MCProtocol::Tool.class)
      metadata = tool_class.metadata
      @@tools[metadata[:name].to_s] = tool_class
    end

    # List all registered tools
    def self.list_tools
      @@tools.map do |name, tool_class|
        tool_class.metadata
      end
    end

    # Execute a tool by name
    def self.execute_tool(name : String, params : JSON::Any)
      tool_class = @@tools[name]?
      raise "Tool '#{name}' not found" unless tool_class
      
      tool = tool_class.new
      tool.execute(params)
    end

    # Get tool metadata
    def self.get_tool_metadata(name : String)
      tool_class = @@tools[name]?
      return nil unless tool_class
      
      tool_class.metadata
    end
  end
end
```

### Registering Tools at Startup

Add tool registration to your application initialization:

```crystal
# config/initializers/mcp_tools.cr
require "../src/mcp_tools/**"

# Register all MCP tools
McpTools::Registry.register(McpTools::ExampleTool)
# Add more tools as needed
# McpTools::Registry.register(McpTools::DatabaseQueryTool)
# McpTools::Registry.register(McpTools::FileProcessorTool)
```

## Handling Tool Requests

### Update Routes

Add routes for MCP tool operations:

```crystal
# config/routes.cr
routes :api do
  # MCP endpoints
  get "/mcp/handshake", ApiControllers::McpController, :handshake
  get "/mcp/tools", ApiControllers::McpToolsController, :list
  post "/mcp/tools/:name/execute", ApiControllers::McpToolsController, :execute
end
```

### Request/Response Format

#### List Tools Request
```http
GET /api/mcp/tools
```

#### List Tools Response
```json
[
  {
    "name": "example_tool",
    "description": "An example MCP tool",
    "parameters": {
      "type": "object",
      "properties": {
        "input": {
          "type": "string",
          "description": "The input to process"
        }
      },
      "required": ["input"]
    }
  }
]
```

#### Execute Tool Request
```http
POST /api/mcp/tools/example_tool/execute
Content-Type: application/json

{
  "input": "hello world",
  "options": {
    "format": "json"
  }
}
```

#### Execute Tool Response
```json
{
  "success": true,
  "result": {
    "processed": "HELLO WORLD"
  }
}
```

## Authentication & Security

### Securing MCP Endpoints

For authenticated MCP tools, move routes to the `:auth` pipeline:

```crystal
routes :auth do
  # Secured MCP endpoints
  get "/mcp/secure/tools", ApiControllers::SecureMcpToolsController, :list
  post "/mcp/secure/tools/:name/execute", ApiControllers::SecureMcpToolsController, :execute
end
```

### API Key Authentication

For API-based authentication, create a custom pipe:

```crystal
# src/pipes/api_authenticate.cr
class ApiAuthenticate < Amber::Pipe::Base
  def call(context)
    api_key = context.request.headers["X-API-Key"]?
    
    unless valid_api_key?(api_key)
      context.response.status_code = 401
      context.response.print({error: "Invalid API key"}.to_json)
      return
    end
    
    call_next(context)
  end

  private def valid_api_key?(key : String?)
    return false unless key
    # Implement your API key validation logic
    # Example: check against database or environment variable
    key == ENV["MCP_API_KEY"]
  end
end
```

## Testing MCP Tools

### Unit Testing Tools

Create tests for your MCP tools:

```crystal
# spec/mcp_tools/example_tool_spec.cr
require "../spec_helper"
require "../../src/mcp_tools/example_tool"

describe McpTools::ExampleTool do
  describe "#execute" do
    it "processes input in JSON format" do
      tool = McpTools::ExampleTool.new
      params = JSON.parse({
        input: "hello",
        options: {format: "json"}
      }.to_json)
      
      result = tool.execute(params)
      result["success"].should eq(true)
      result["result"]["processed"].should eq("HELLO")
    end

    it "processes input in text format" do
      tool = McpTools::ExampleTool.new
      params = JSON.parse({
        input: "world",
        options: {format: "text"}
      }.to_json)
      
      result = tool.execute(params)
      result["success"].should eq(true)
      result["result"].should eq("Processed: WORLD")
    end
  end

  describe ".metadata" do
    it "returns correct tool metadata" do
      metadata = McpTools::ExampleTool.metadata
      metadata[:name].should eq("example_tool")
      metadata[:parameters][:required].should contain("input")
    end
  end
end
```

### Integration Testing

Test the full MCP endpoint flow:

```crystal
# spec/controllers/mcp_tools_controller_spec.cr
require "../spec_helper"

describe ApiControllers::McpToolsController do
  describe "GET /api/mcp/tools" do
    it "returns list of available tools" do
      get "/api/mcp/tools"
      
      response.status_code.should eq(200)
      json = JSON.parse(response.body)
      json.as_a.size.should be > 0
    end
  end

  describe "POST /api/mcp/tools/:name/execute" do
    it "executes a tool successfully" do
      post "/api/mcp/tools/example_tool/execute", 
        body: {input: "test"}.to_json,
        headers: HTTP::Headers{"Content-Type" => "application/json"}
      
      response.status_code.should eq(200)
      json = JSON.parse(response.body)
      json["success"].should eq(true)
    end

    it "returns error for unknown tool" do
      post "/api/mcp/tools/unknown_tool/execute",
        body: {}.to_json,
        headers: HTTP::Headers{"Content-Type" => "application/json"}
      
      response.status_code.should eq(422)
      json = JSON.parse(response.body)
      json["error"].should_not be_nil
    end
  end
end
```

## Best Practices

### 1. Tool Naming Conventions

- Use descriptive, lowercase names with underscores
- Prefix with domain area (e.g., `db_query_tool`, `file_processor_tool`)
- Avoid generic names like `tool1` or `helper`

### 2. Error Handling

Always implement proper error handling in your tools:

```crystal
def execute(params : JSON::Any) : JSON::Any
  # Validate required parameters
  unless params["required_field"]?
    return error_response("Missing required field: required_field")
  end
  
  begin
    # Tool logic
    result = perform_operation(params)
    success_response(result)
  rescue ex : SpecificError
    error_response("Operation failed: #{ex.message}")
  rescue ex
    error_response("Unexpected error: #{ex.message}")
  end
end

private def success_response(data)
  JSON.parse({success: true, data: data}.to_json)
end

private def error_response(message : String)
  JSON.parse({success: false, error: message}.to_json)
end
```

### 3. Parameter Validation

Use JSON Schema validation for complex parameters:

```crystal
def validate_params(params : JSON::Any)
  schema = {
    type: "object",
    properties: {
      query: {type: "string", minLength: 1},
      limit: {type: "integer", minimum: 1, maximum: 100}
    },
    required: ["query"]
  }
  
  # Implement or use a JSON Schema validator
  # Raise validation errors if params don't match schema
end
```

### 4. Async Operations

For long-running tools, implement async execution:

```crystal
class AsyncTool < MCProtocol::Tool
  def execute(params : JSON::Any) : JSON::Any
    job_id = UUID.random.to_s
    
    # Queue the job for background processing
    spawn do
      perform_async_operation(job_id, params)
    end
    
    JSON.parse({
      success: true,
      job_id: job_id,
      status: "processing"
    }.to_json)
  end
end
```

### 5. Rate Limiting

Implement rate limiting for resource-intensive tools:

```crystal
class RateLimitedTool < MCProtocol::Tool
  @@rate_limiter = RateLimiter.new(
    max_requests: 10,
    window: 60.seconds
  )
  
  def execute(params : JSON::Any) : JSON::Any
    client_id = params["client_id"]?.try(&.as_s) || "anonymous"
    
    unless @@rate_limiter.allow?(client_id)
      return error_response("Rate limit exceeded")
    end
    
    # Tool logic here
  end
end
```

### 6. Logging and Monitoring

Add comprehensive logging to track tool usage:

```crystal
def execute(params : JSON::Any) : JSON::Any
  start_time = Time.utc
  tool_name = self.class.metadata[:name]
  
  Log.info { "Executing tool: #{tool_name}" }
  Log.debug { "Parameters: #{params}" }
  
  begin
    result = perform_operation(params)
    duration = Time.utc - start_time
    
    Log.info { "Tool #{tool_name} completed in #{duration.total_milliseconds}ms" }
    success_response(result)
  rescue ex
    Log.error(exception: ex) { "Tool #{tool_name} failed" }
    error_response(ex.message)
  end
end
```

## Advanced Topics

### Creating Database Query Tools

Example of a tool that queries the database:

```crystal
class DatabaseQueryTool < MCProtocol::Tool
  def self.metadata
    {
      name: "database_query",
      description: "Execute safe database queries",
      parameters: {
        type: "object",
        properties: {
          table: {
            type: "string",
            enum: ["users", "posts", "comments"] # Whitelist tables
          },
          conditions: {
            type: "object"
          },
          limit: {
            type: "integer",
            default: 10,
            maximum: 100
          }
        },
        required: ["table"]
      }
    }
  end
  
  def execute(params : JSON::Any) : JSON::Any
    table = params["table"].as_s
    limit = params["limit"]?.try(&.as_i) || 10
    
    # Use Jennifer ORM for safe querying
    results = case table
    when "users"
      User.all.limit(limit).to_a
    when "posts"
      Post.all.limit(limit).to_a
    else
      [] of Jennifer::Model::Base
    end
    
    JSON.parse({
      success: true,
      data: results.map(&.to_h)
    }.to_json)
  end
end
```

### Creating File Processing Tools

Example of a tool that processes files:

```crystal
class FileProcessorTool < MCProtocol::Tool
  ALLOWED_EXTENSIONS = [".txt", ".csv", ".json"]
  MAX_FILE_SIZE = 10.megabytes
  
  def execute(params : JSON::Any) : JSON::Any
    file_path = params["file_path"].as_s
    operation = params["operation"].as_s
    
    # Validate file
    validate_file!(file_path)
    
    result = case operation
    when "word_count"
      count_words(file_path)
    when "line_count"
      count_lines(file_path)
    else
      raise "Unknown operation: #{operation}"
    end
    
    success_response(result)
  end
  
  private def validate_file!(path : String)
    raise "File not found" unless File.exists?(path)
    raise "File too large" if File.size(path) > MAX_FILE_SIZE
    
    extension = File.extname(path)
    unless ALLOWED_EXTENSIONS.includes?(extension)
      raise "Unsupported file type: #{extension}"
    end
  end
end
```

## Troubleshooting

### Common Issues

1. **Tool not found error**
   - Ensure the tool is registered in `config/initializers/mcp_tools.cr`
   - Check that the tool name matches exactly

2. **Parameter validation failures**
   - Verify JSON schema matches expected parameters
   - Check for required fields
   - Validate data types

3. **Authentication errors**
   - Confirm API key is set correctly
   - Check that routes are in the correct pipeline

4. **Performance issues**
   - Implement caching for expensive operations
   - Use background jobs for long-running tasks
   - Add rate limiting to prevent abuse

## Next Steps

1. Create your first custom MCP tool following the examples above
2. Add authentication if needed for secure tools
3. Write tests for your tools
4. Monitor tool usage and performance
5. Document your custom tools for other developers

For more information about the Model Context Protocol, visit the official documentation.