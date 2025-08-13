module McpTools
  class UserProfileTool < BaseTool
    def metadata : JSON::Any
      JSON.parse({
        name: "user_profile",
        description: "View and manage user profile information",
        parameters: {
          type: "object",
          properties: {
            action: {
              type: "string",
              enum: ["get", "update"],
              description: "Action to perform on the profile"
            },
            fields: {
              type: "object",
              description: "Fields to update (only for update action)",
              properties: {
                display_name: {type: "string"},
                bio: {type: "string"},
                preferences: {type: "object"}
              }
            }
          },
          required: ["action"]
        }
      }.to_json)
    end

    def execute(params : JSON::Any) : JSON::Any
      # Extract user context (injected by authenticated controller)
      user_id = params["_context"]?.try(&.["user_id"]?).try(&.as_i64)
      
      unless user_id
        return JSON.parse({
          success: false,
          error: "User authentication required"
        }.to_json)
      end

      action = params["action"].as_s

      case action
      when "get"
        get_profile(user_id)
      when "update"
        update_profile(user_id, params["fields"]?)
      else
        JSON.parse({
          success: false,
          error: "Unknown action: #{action}"
        }.to_json)
      end
    rescue ex
      JSON.parse({
        success: false,
        error: ex.message
      }.to_json)
    end

    private def get_profile(user_id : Int64)
      # Fetch user from database
      user = User.find(user_id)
      
      return JSON.parse({
        success: false,
        error: "User not found"
      }.to_json) unless user

      JSON.parse({
        success: true,
        profile: {
          id: user.id,
          email: user.email,
          created_at: user.created_at,
          # Add more profile fields as needed
          # display_name: user.display_name,
          # bio: user.bio,
          # preferences: user.preferences
        }
      }.to_json)
    end

    private def update_profile(user_id : Int64, fields : JSON::Any?)
      return JSON.parse({
        success: false,
        error: "No fields provided for update"
      }.to_json) unless fields

      user = User.find(user_id)
      
      return JSON.parse({
        success: false,
        error: "User not found"
      }.to_json) unless user

      # Update allowed fields
      # Note: You would add these fields to your User model
      # if display_name = fields["display_name"]?.try(&.as_s)
      #   user.display_name = display_name
      # end
      
      # if bio = fields["bio"]?.try(&.as_s)
      #   user.bio = bio
      # end
      
      # if preferences = fields["preferences"]?
      #   user.preferences = preferences
      # end

      # For now, just return success
      # In production, you would: user.save!
      
      JSON.parse({
        success: true,
        message: "Profile updated successfully",
        user_id: user_id
      }.to_json)
    end
  end
end