require "mcprotocol"

module McpTools
  # Base class for MCP tools with metadata
  abstract class BaseTool
    abstract def metadata : JSON::Any
    abstract def execute(params : JSON::Any) : JSON::Any
  end

  class Registry
    @@tools = {} of String => BaseTool.class

    # Register a tool
    def self.register(tool_class : BaseTool.class)
      tool = tool_class.new
      metadata = tool.metadata
      name = metadata["name"].as_s
      @@tools[name] = tool_class
    end

    # List all registered tools
    def self.list_tools
      @@tools.map do |name, tool_class|
        tool_class.new.metadata
      end
    end

    # List tools available for a specific user
    def self.list_tools_for_user(user : User)
      all_tools = list_tools
      
      # Filter based on user permissions
      # You can implement more sophisticated filtering here
      if user.is_a?(Admin)
        all_tools
      else
        all_tools.select do |tool|
          # Filter out admin-only tools for non-admin users
          !tool["name"].as_s.includes?("admin")
        end
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
      
      tool_class.new.metadata
    end

    # Check if a tool exists
    def self.tool_exists?(name : String) : Bool
      @@tools.has_key?(name)
    end

    # Get list of tool names
    def self.tool_names : Array(String)
      @@tools.keys
    end
  end
end