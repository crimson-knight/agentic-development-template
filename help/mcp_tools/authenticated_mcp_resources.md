# Authenticated MCP Resources Guide

## Overview

This guide explains how to create MCP tools and resources that are tied to authenticated users, ensuring that each user can only access their own data and execute tools they have permission to use.

## Table of Contents

1. [Authentication Architecture](#authentication-architecture)
2. [Creating Authenticated MCP Endpoints](#creating-authenticated-mcp-endpoints)
3. [User-Specific MCP Tools](#user-specific-mcp-tools)
4. [Permission Management](#permission-management)
5. [Audit Logging](#audit-logging)
6. [API Authentication](#api-authentication)
7. [Testing Authenticated Endpoints](#testing-authenticated-endpoints)

## Authentication Architecture

The application uses a session-based authentication system with the following components:

- **User Model**: Based on the `Persona` class with STI (Single Table Inheritance)
- **CurrentUserPipe**: Sets the current user from session data
- **AuthenticateUser**: Ensures requests are from authenticated users
- **BaseAuthenticatedController**: Base class for authenticated controllers

## Creating Authenticated MCP Endpoints

### Step 1: Create an Authenticated Controller

Create your MCP controller in the `Authenticated` namespace:

```crystal
# src/controllers/authenticated/mcp_tools_controller.cr
class Authenticated::McpToolsController < Authenticated::BaseAuthenticatedController
  # The current_user property is automatically available
  
  def list
    # List tools available to the current user
    tools = McpTools::Registry.list_tools_for_user(current_user)
    
    respond_with do
      json({
        user_id: current_user.id,
        tools: tools
      }.to_json)
    end
  end
  
  def execute
    tool_name = params[:name]
    tool_params = JSON.parse(request.body.to_s)
    
    # Add user context to parameters
    enriched_params = tool_params.as_h.merge({
      "_user_id" => JSON::Any.new(current_user.id.to_i64),
      "_user_email" => JSON::Any.new(current_user.email)
    })
    
    result = McpTools::Registry.execute_tool(
      tool_name, 
      JSON::Any.new(enriched_params)
    )
    
    respond_with do
      json result.to_json
    end
  end
end
```

### Step 2: Add Routes to the Auth Pipeline

Update your routes to use the authenticated pipeline:

```crystal
# config/routes.cr
routes :auth do
  # Authenticated MCP endpoints
  get "/mcp/tools", Authenticated::McpToolsController, :list
  post "/mcp/tools/:name/execute", Authenticated::McpToolsController, :execute
  get "/mcp/tools/history", Authenticated::McpToolsController, :history
  get "/mcp/tools/configurations", Authenticated::McpToolsController, :configurations
end
```

## User-Specific MCP Tools

### Creating Tools with User Context

Here's an example of a tool that operates on user-specific data:

```crystal
# src/mcp_tools/user_data_tool.cr
module McpTools
  class UserDataTool < MCProtocol::Tool
    def self.metadata
      {
        name: "user_data",
        description: "Access and manage user-specific data",
        parameters: {
          type: "object",
          properties: {
            action: {
              type: "string",
              enum: ["list", "get", "update", "delete"]
            },
            resource: {
              type: "string",
              enum: ["profile", "settings", "preferences"]
            },
            data: {
              type: "object",
              description: "Data for update operations"
            }
          },
          required: ["action", "resource"]
        }
      }
    end
    
    def execute(params : JSON::Any) : JSON::Any
      # Extract user context (injected by the controller)
      user_id = params["_user_id"]?.try(&.as_i64)
      unless user_id
        return error_response("User context not provided")
      end
      
      action = params["action"].as_s
      resource = params["resource"].as_s
      
      result = case action
      when "list"
        list_user_resource(user_id, resource)
      when "get"
        get_user_resource(user_id, resource)
      when "update"
        update_user_resource(user_id, resource, params["data"]?)
      when "delete"
        delete_user_resource(user_id, resource)
      else
        error_response("Unknown action: #{action}")
      end
      
      result
    end
    
    private def list_user_resource(user_id : Int64, resource : String)
      # Query only the current user's data
      case resource
      when "profile"
        user = User.find!(user_id)
        success_response({
          id: user.id,
          email: user.email,
          created_at: user.created_at
        })
      when "settings"
        # Fetch user settings (example)
        success_response({settings: "user_settings_here"})
      else
        error_response("Unknown resource: #{resource}")
      end
    end
    
    private def get_user_resource(user_id : Int64, resource : String)
      # Implementation for getting specific resource
      success_response({resource: resource, user_id: user_id})
    end
    
    private def update_user_resource(user_id : Int64, resource : String, data : JSON::Any?)
      return error_response("No data provided for update") unless data
      
      # Update only the current user's data
      case resource
      when "profile"
        user = User.find!(user_id)
        # Update user profile with provided data
        # user.update(data)
        success_response({updated: true, user_id: user_id})
      else
        error_response("Cannot update resource: #{resource}")
      end
    end
    
    private def delete_user_resource(user_id : Int64, resource : String)
      # Implementation for deleting resource
      error_response("Delete not implemented for safety")
    end
    
    private def success_response(data)
      JSON.parse({success: true, data: data}.to_json)
    end
    
    private def error_response(message : String)
      JSON.parse({success: false, error: message}.to_json)
    end
  end
end
```

### Database Query Tool with User Scope

```crystal
# src/mcp_tools/user_query_tool.cr
module McpTools
  class UserQueryTool < MCProtocol::Tool
    def self.metadata
      {
        name: "user_query",
        description: "Query user's own data",
        parameters: {
          type: "object",
          properties: {
            table: {
              type: "string",
              enum: ["posts", "comments", "activities"]
            },
            filters: {
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
      user_id = params["_user_id"]?.try(&.as_i64)
      return error_response("User context required") unless user_id
      
      table = params["table"].as_s
      limit = params["limit"]?.try(&.as_i) || 10
      
      # Always scope queries to the current user
      results = case table
      when "posts"
        Post.where { _user_id == user_id }.limit(limit).to_a
      when "comments"
        Comment.where { _user_id == user_id }.limit(limit).to_a
      when "activities"
        Activity.where { _user_id == user_id }.limit(limit).to_a
      else
        [] of Jennifer::Model::Base
      end
      
      JSON.parse({
        success: true,
        user_id: user_id,
        table: table,
        count: results.size,
        data: results.map(&.to_h)
      }.to_json)
    end
  end
end
```

## Permission Management

### Role-Based Tool Access

Create a permission system for tools:

```crystal
# src/mcp_tools/permissions.cr
module McpTools
  class Permissions
    # Define tool permissions by role
    TOOL_PERMISSIONS = {
      "admin" => ["*"], # Admins can access all tools
      "user" => [
        "user_data",
        "user_query",
        "weather",
        "calculator"
      ],
      "guest" => [
        "weather",
        "calculator"
      ]
    }
    
    def self.user_can_execute?(user : User, tool_name : String) : Bool
      role = user_role(user)
      permissions = TOOL_PERMISSIONS[role]? || [] of String
      
      # Check if user has wildcard permission or specific tool permission
      permissions.includes?("*") || permissions.includes?(tool_name)
    end
    
    def self.filter_tools_for_user(user : User, tools : Array)
      role = user_role(user)
      permissions = TOOL_PERMISSIONS[role]? || [] of String
      
      return tools if permissions.includes?("*")
      
      tools.select do |tool|
        permissions.includes?(tool[:name].to_s)
      end
    end
    
    private def self.user_role(user : User) : String
      case user
      when Admin
        "admin"
      when User
        "user"
      else
        "guest"
      end
    end
  end
end
```

### Enhanced Controller with Permissions

```crystal
# src/controllers/authenticated/mcp_tools_controller.cr
class Authenticated::McpToolsController < Authenticated::BaseAuthenticatedController
  before_action do
    only [:execute] { check_tool_permission }
  end
  
  private def check_tool_permission
    tool_name = params[:name]
    
    unless McpTools::Permissions.user_can_execute?(current_user, tool_name)
      respond_with(403) do
        json({
          error: "You don't have permission to execute this tool",
          tool: tool_name,
          user_id: current_user.id
        }.to_json)
      end
    end
  end
  
  def list
    all_tools = McpTools::Registry.list_tools
    user_tools = McpTools::Permissions.filter_tools_for_user(current_user, all_tools)
    
    respond_with do
      json({
        user_id: current_user.id,
        role: current_user.class.name,
        available_tools: user_tools
      }.to_json)
    end
  end
end
```

## Audit Logging

### Creating an Audit Trail

Track all MCP tool executions:

```crystal
# src/models/tool_execution.cr
class ToolExecution < BaseModel
  with_timestamps
  
  mapping(
    id: Primary64,
    user_id: Int64,
    tool_name: String,
    parameters: JSON::Any,
    result: JSON::Any?,
    success: Bool,
    error_message: String?,
    execution_time_ms: Int32?,
    ip_address: String?,
    user_agent: String?,
    created_at: Time?,
    updated_at: Time?
  )
  
  belongs_to :user, User
  
  # Scopes for querying
  scope :successful { where { _success == true } }
  scope :failed { where { _success == false } }
  scope :by_tool { |name| where { _tool_name == name } }
  scope :by_user { |user_id| where { _user_id == user_id } }
  scope :recent { order(created_at: :desc) }
end
```

### Migration for Audit Table

```crystal
# db/migrations/create_tool_executions.cr
class CreateToolExecutions < Jennifer::Migration::Base
  def up
    create_table :tool_executions do |t|
      t.bigint :user_id, null: false
      t.string :tool_name, null: false
      t.json :parameters
      t.json :result
      t.bool :success, default: false
      t.string :error_message
      t.integer :execution_time_ms
      t.string :ip_address
      t.string :user_agent
      t.timestamps
      
      t.index :user_id
      t.index :tool_name
      t.index :created_at
      t.index [:user_id, :tool_name]
    end
    
    add_foreign_key :tool_executions, :personas, column: :user_id
  end
  
  def down
    drop_table :tool_executions
  end
end
```

### Logging Tool Executions

```crystal
# src/controllers/authenticated/mcp_tools_controller.cr
private def execute_and_log_tool(tool_name : String, params : JSON::Any)
  start_time = Time.utc
  
  execution = ToolExecution.new(
    user_id: current_user.id,
    tool_name: tool_name,
    parameters: params,
    ip_address: request.remote_address.to_s,
    user_agent: request.headers["User-Agent"]?
  )
  
  begin
    result = McpTools::Registry.execute_tool(tool_name, params)
    execution.result = result
    execution.success = result["success"]?.try(&.as_bool) || false
    execution.execution_time_ms = (Time.utc - start_time).total_milliseconds.to_i
  rescue ex
    execution.success = false
    execution.error_message = ex.message
    result = JSON.parse({success: false, error: ex.message}.to_json)
  ensure
    execution.save!
  end
  
  result
end
```

## API Authentication

### Token-Based Authentication for API Access

For API clients that can't use session cookies:

```crystal
# src/pipes/api_token_authenticate.cr
class ApiTokenAuthenticate < Amber::Pipe::Base
  def call(context)
    # Check for API token in header
    token = extract_token(context.request.headers)
    
    if user = authenticate_by_token(token)
      context.current_user = user
      call_next(context)
    else
      context.response.status_code = 401
      context.response.headers["Content-Type"] = "application/json"
      context.response.print({
        error: "Invalid or missing API token"
      }.to_json)
    end
  end
  
  private def extract_token(headers : HTTP::Headers) : String?
    # Support both Authorization Bearer and X-API-Token headers
    if auth_header = headers["Authorization"]?
      auth_header.gsub("Bearer ", "")
    else
      headers["X-API-Token"]?
    end
  end
  
  private def authenticate_by_token(token : String?) : User?
    return nil unless token
    
    # You could store API tokens in the database
    # For now, we'll use a simple example
    if user = User.where { _api_token == token }.first
      user
    else
      nil
    end
  end
end
```

### API Routes with Token Authentication

```crystal
# config/routes.cr
pipeline :api_auth do
  plug Amber::Pipe::Logger.new
  plug Amber::Pipe::CORS.new
  plug ApiTokenAuthenticate.new
end

routes :api_auth do
  # API endpoints with token authentication
  get "/api/v1/mcp/tools", Authenticated::McpToolsController, :list
  post "/api/v1/mcp/tools/:name/execute", Authenticated::McpToolsController, :execute
  get "/api/v1/mcp/executions", Authenticated::McpToolsController, :history
end
```

## Testing Authenticated Endpoints

### Testing with Session Authentication

```crystal
# spec/controllers/authenticated/mcp_tools_controller_spec.cr
require "../../spec_helper"

describe Authenticated::McpToolsController do
  describe "authenticated requests" do
    # Create a test user
    let(:user) { User.create!(email: "test@example.com", password: "password123") }
    
    # Helper to make authenticated requests
    def authenticated_request(method, path, body = nil)
      # Simulate login
      session = {} of String => String
      session["user_id"] = user.id.to_s
      
      # Make request with session
      request = HTTP::Request.new(
        method,
        path,
        headers: HTTP::Headers{"Content-Type" => "application/json"},
        body: body
      )
      request.session = session
      
      response = Authenticated::McpToolsController.new(request).call
      response
    end
    
    describe "GET /mcp/tools" do
      it "returns tools for authenticated user" do
        response = authenticated_request("GET", "/mcp/tools")
        
        response.status_code.should eq(200)
        json = JSON.parse(response.body)
        json["user_id"].should eq(user.id)
        json["tools"].should be_a(Array)
      end
    end
    
    describe "POST /mcp/tools/:name/execute" do
      it "executes tool with user context" do
        body = {input: "test data"}.to_json
        response = authenticated_request(
          "POST", 
          "/mcp/tools/user_data/execute",
          body
        )
        
        response.status_code.should eq(200)
        json = JSON.parse(response.body)
        json["success"].should be_true
      end
      
      it "rejects unauthorized tools" do
        body = {input: "test"}.to_json
        response = authenticated_request(
          "POST",
          "/mcp/tools/admin_only_tool/execute",
          body
        )
        
        response.status_code.should eq(403)
        json = JSON.parse(response.body)
        json["error"].should contain("permission")
      end
    end
  end
  
  describe "unauthenticated requests" do
    describe "GET /mcp/tools" do
      it "redirects to login" do
        get "/mcp/tools"
        
        response.status_code.should eq(302)
        response.headers["Location"].should eq("/login")
      end
    end
  end
end
```

### Testing with API Token

```bash
# Generate an API token for testing
crystal eval "require \"./src/models/*\"; user = User.find(1); puts user.generate_api_token!"

# Test with curl
TOKEN="your-api-token-here"

# List available tools
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/mcp/tools

# Execute a tool
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action":"list","resource":"profile"}' \
  http://localhost:3000/api/v1/mcp/tools/user_data/execute

# Get execution history
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/mcp/executions
```

## Security Best Practices

1. **Always validate user context**: Never trust client-provided user IDs
2. **Scope all queries**: Always filter data by the current user
3. **Log all executions**: Maintain an audit trail for security
4. **Rate limit endpoints**: Prevent abuse of resource-intensive tools
5. **Validate permissions**: Check user permissions before tool execution
6. **Sanitize inputs**: Validate and sanitize all tool parameters
7. **Use HTTPS**: Always use encrypted connections in production
8. **Rotate tokens**: Implement token expiration and rotation

## Example: Complete User-Tied MCP Tool

Here's a complete example of a user-specific note-taking tool:

```crystal
# src/mcp_tools/user_notes_tool.cr
module McpTools
  class UserNotesTool < MCProtocol::Tool
    def self.metadata
      {
        name: "user_notes",
        description: "Manage personal notes",
        parameters: {
          type: "object",
          properties: {
            action: {
              type: "string",
              enum: ["create", "list", "get", "update", "delete", "search"]
            },
            title: {type: "string"},
            content: {type: "string"},
            note_id: {type: "integer"},
            query: {type: "string"},
            tags: {
              type: "array",
              items: {type: "string"}
            }
          },
          required: ["action"]
        }
      }
    end
    
    def execute(params : JSON::Any) : JSON::Any
      user_id = params["_user_id"]?.try(&.as_i64)
      return error_response("Authentication required") unless user_id
      
      action = params["action"].as_s
      
      case action
      when "create"
        create_note(user_id, params)
      when "list"
        list_notes(user_id)
      when "get"
        get_note(user_id, params["note_id"].as_i64)
      when "update"
        update_note(user_id, params["note_id"].as_i64, params)
      when "delete"
        delete_note(user_id, params["note_id"].as_i64)
      when "search"
        search_notes(user_id, params["query"].as_s)
      else
        error_response("Unknown action: #{action}")
      end
    end
    
    private def create_note(user_id : Int64, params : JSON::Any)
      note = Note.create!(
        user_id: user_id,
        title: params["title"]?.try(&.as_s) || "Untitled",
        content: params["content"].as_s,
        tags: params["tags"]?.try(&.as_a.map(&.as_s))
      )
      
      success_response({
        id: note.id,
        title: note.title,
        created_at: note.created_at
      })
    end
    
    private def list_notes(user_id : Int64)
      notes = Note.where { _user_id == user_id }
                  .order(created_at: :desc)
                  .limit(20)
                  .to_a
      
      success_response({
        count: notes.size,
        notes: notes.map { |n| {
          id: n.id,
          title: n.title,
          preview: n.content[0..100]?,
          created_at: n.created_at
        }}
      })
    end
    
    private def get_note(user_id : Int64, note_id : Int64)
      note = Note.where { (_user_id == user_id) & (_id == note_id) }.first
      
      return error_response("Note not found") unless note
      
      success_response({
        id: note.id,
        title: note.title,
        content: note.content,
        tags: note.tags,
        created_at: note.created_at,
        updated_at: note.updated_at
      })
    end
    
    private def update_note(user_id : Int64, note_id : Int64, params : JSON::Any)
      note = Note.where { (_user_id == user_id) & (_id == note_id) }.first
      
      return error_response("Note not found") unless note
      
      note.title = params["title"].as_s if params["title"]?
      note.content = params["content"].as_s if params["content"]?
      note.tags = params["tags"].as_a.map(&.as_s) if params["tags"]?
      note.save!
      
      success_response({updated: true, id: note.id})
    end
    
    private def delete_note(user_id : Int64, note_id : Int64)
      note = Note.where { (_user_id == user_id) & (_id == note_id) }.first
      
      return error_response("Note not found") unless note
      
      note.destroy
      success_response({deleted: true, id: note_id})
    end
    
    private def search_notes(user_id : Int64, query : String)
      notes = Note.where { 
        (_user_id == user_id) & 
        (_title.ilike("%#{query}%") | _content.ilike("%#{query}%"))
      }.limit(10).to_a
      
      success_response({
        query: query,
        count: notes.size,
        results: notes.map { |n| {
          id: n.id,
          title: n.title,
          preview: n.content[0..100]?
        }}
      })
    end
    
    private def success_response(data)
      JSON.parse({success: true, data: data}.to_json)
    end
    
    private def error_response(message : String)
      JSON.parse({success: false, error: message}.to_json)
    end
  end
end
```

## Summary

By following this guide, you can create MCP tools and resources that are:

1. **Authenticated**: Only accessible to logged-in users
2. **User-scoped**: Data is automatically filtered by user
3. **Permission-controlled**: Tools are restricted based on user roles
4. **Audited**: All executions are logged for security
5. **Secure**: Multiple layers of authentication and validation

The key principle is that user context should always be injected server-side, never trusted from client input, ensuring that users can only access and modify their own data.