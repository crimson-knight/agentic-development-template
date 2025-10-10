require "mcprotocol"

class Authenticated::McpToolsController < Authenticated::BaseAuthenticatedController
  # List available tools for the authenticated user
  def list
    # current_user is guaranteed to be set by BaseAuthenticatedController
    user = current_user.not_nil!

    # Filter tools based on user permissions
    all_tools = McpTools::Registry.list_tools

    # You can filter tools based on user role/permissions
    user_tools = filter_tools_for_user(all_tools)

    respond_with do
      json({
        user_id: user.id,
        username: user.email,
        tools: user_tools
      }.to_json)
    end
  end

  # Execute a tool with user context
  def execute
    tool_name = params[:name]
    
    # Verify user has permission to use this tool
    unless user_can_execute_tool?(tool_name)
      respond_with(403) do
        json({error: "You don't have permission to execute this tool"}.to_json)
      end
      return
    end
    
    # Parse request body
    tool_params = JSON.parse(request.body.to_s)
    
    # Add user context to the tool parameters
    enriched_params = add_user_context(tool_params)
    
    # Execute the tool
    result = McpTools::Registry.execute_tool(tool_name, enriched_params)
    
    # Log the tool execution for audit purposes
    log_tool_execution(tool_name, enriched_params, result)
    
    respond_with do
      json result.to_json
    end
  rescue ex
    respond_with(422) do
      json({error: ex.message}.to_json)
    end
  end

  # Get user-specific tool history
  def history
    user = current_user.not_nil!
    # This would typically query a database table that tracks tool executions
    # For now, return a placeholder response
    respond_with do
      json({
        user_id: user.id,
        executions: [] of String,
        message: "Tool history tracking not yet implemented"
      }.to_json)
    end
  end

  # Get user's custom tool configurations
  def configurations
    user = current_user.not_nil!
    # Users can have custom configurations for tools
    # This would typically be stored in a user_tool_configs table
    respond_with do
      json({
        user_id: user.id,
        configurations: {} of String => String,
        message: "User tool configurations not yet implemented"
      }.to_json)
    end
  end

  private def filter_tools_for_user(tools)
    # Filter tools based on user role or permissions
    # For now, return all tools for authenticated users
    # You could check user.role or user.permissions here
    
    if current_user.is_a?(Users::Admin)
      # Admins see all tools
      tools
    else
      # Regular users see only non-admin tools
      tools.select do |tool|
        # Filter out admin-only tools
        !tool["name"].as_s.includes?("admin")
      end
    end
  end

  private def user_can_execute_tool?(tool_name : String) : Bool
    # Check if user has permission to execute this specific tool
    # This could check against a permissions table or user role

    # For demonstration, block admin tools for non-admin users
    if tool_name.includes?("admin") && !current_user.is_a?(Users::Admin)
      return false
    end
    
    true
  end

  private def add_user_context(params : JSON::Any) : JSON::Any
    user = current_user.not_nil!
    # Add user context to the tool parameters
    # This ensures tools always know which user is executing them

    user_context = {} of String => JSON::Any
    user_context["user_id"] = JSON::Any.new(user.id.not_nil!)
    user_context["user_email"] = JSON::Any.new(user.email)
    user_context["user_type"] = JSON::Any.new(user.class.name)
    user_context["execution_time"] = JSON::Any.new(Time.utc.to_s)

    # Merge user context with original params
    original = params.as_h? || {} of String => JSON::Any
    enriched = original.merge({"_context" => JSON::Any.new(user_context)})

    JSON::Any.new(enriched)
  end

  private def log_tool_execution(tool_name : String, params : JSON::Any, result : JSON::Any)
    user = current_user.not_nil!
    # Log tool execution for audit purposes
    Log.info { "User #{user.id} executed tool '#{tool_name}'" }
    Log.debug { "Parameters: #{params.to_json}" }
    Log.debug { "Result: #{result.to_json}" }

    # In production, you might want to save this to a database table:
    # ToolExecution.create(
    #   user_id: user.id,
    #   tool_name: tool_name,
    #   parameters: params.to_json,
    #   result: result.to_json,
    #   executed_at: Time.utc
    # )
  end
end