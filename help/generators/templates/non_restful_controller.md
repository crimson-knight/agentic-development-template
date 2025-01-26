# Non-RESTful Controller Template & Instructions

Non-RESTful controllers are used for actions that do not fit the standard CRUD operations, such as login, logout, user profiles, or other custom business processes.

Important details:
- All controllers have access to a `get_current_user` method that returns the current `User` object, this must be used in a conditional assignment to remove the `Nil` from the type union. You must include this if you need to use the `current_user` in the controller.
```crystal
# Assignment must happen as part of the conditional statement
if current_user = get_current_user
  # The current_user is not `Nil`, we can safely use it, write any code requiring the `current_user` within this block.
end
```

- Ambers pipelines always handle user authentication and authorization, do not add any additional authentication or authorization logic to the controller.
- The `respond_with` method is used to handle the response to the user in multiple formats, supporting HTML, JSON, XML and TXT. Default to using HTML and JSON.
- Always validate the presence of a param before trying to fetch from the database for any records that rely on the param.

The file contents should follow the template, where everything in the `{{}}` should be replaced with the appropriate values as they are described:

```crystal
class {{controller_name}}Controller < ApplicationController

  def your_action_name
    if current_user = get_current_user
      # The current_user is not `Nil`, we can safely use it, write any code requiring the `current_user` within this block.
    end
  end

  def create
    {{singular_resource_name}} = {{singular_resource_name_from_app_models}}.new {{singular_resource_name}}_params
    if {{singular_resource_name}}.save
      respond_with do
        html { redirect_to action: :index, flash: {"success" => "{{singular_resource_name}} has been created."} }
        json { %({"status": "success", "message": "{{singular_resource_name}} has been created."}) }
      end
    else
      respond_with do
        html { flash[:danger] = "Could not create {{singular_resource_name}}!"; render "new.ecr" }
        json { %({"status": "error", "message": "Could not create {{singular_resource_name}}!"}) }
      end
    end

    # Always rescue any errors, log them, and respond with an error message to the user.
    rescue e
      Log.error(e)
      respond_with do
        html { flash[:danger] = "Could not create {{singular_resource_name}}!"; render "new.ecr" }
        json { %({"status": "error", "message": "Could not create {{singular_resource_name}}!"}) }
      end
    end
  end

  def update
    {{singular_resource_name}}.set_attributes {{singular_resource_name}}_params
    if {{singular_resource_name}}.save
      respond_with do
        html { redirect_to action: :index, flash: {"success" => "{{singular_resource_name}} has been updated."} }
        json { %({"status": "success", "message": "{{singular_resource_name}} has been updated."}) }
      end
    else
      raise "Could not update {{singular_resource_name}}"
    end
    rescue e
      Log.error(e)
      respond_with do
        html { flash[:danger] = "Could not update {{singular_resource_name}}!"; render "edit.ecr" }
        json { %({"status": "error", "message": "Could not update {{singular_resource_name}}!"}) }
      end
    end
  end

  # Always validate params presence using the `required` method, and return them as a hash. Any additional validation steps need to be added in this method
  private def {{singular_resource_name}}_params
    params.validation do
      # Each non-nillable attribute from the app/models/#{singular_resource_name}.cr file should be required here.
      required {{non-nillable attributes from app/models/#{singular_resource_name}.cr}}
    end.to_h
  end
end
```