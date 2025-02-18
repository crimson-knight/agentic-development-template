# Non-RESTful Controller Template & Instructions

Non-RESTful controllers are used for actions that do not fit the standard CRUD operations, such as login, logout, user profiles, etc.

- Always validate the presence of a param before trying to fetch from the database for any records that rely on the param.
- Your controller should always be namespaced to `Authenticated` or `Public` depending on the route grouping or the action needing to be taken.
- Your controller should inherit from `ApplicationController` if it is public and `BaseAuthenticatedController` if it is authenticated.

Remind yourself of the controller information that you need from the notes file.

The file contents should follow the template, where everything in the `{{}}` should be replaced with the appropriate values as they are described:

```crystal
class {{controller_name}}Controller < {{namespace}}Controller

  def your_action_name
    # All controllers have access to `get_current_user`. This method returns User or Nil, so you _must_ assign it to a variable to drop the nil type.
    # Assignment must happen as part of the conditional statement
    if current_user = get_current_user
      # The current_user is not `Nil`, we can safely use it, write any code requiring the current user within this block.

      # Do your business logic here

      # All variables assigned within this action will be available in the view.
      my_example_variable = "this variable will be usable in the view by default"

      respond_with do
        html do 
          flash[:success] = "a success message."
          # The #render method signature is `render("file_name.ecr") where the file name is relative to the `src/views/{{namespace}}/{{controller_name}}/` directory.
          # example:
          # src/views/authenticated/my_controller_name/my_action_name.ecr
          render("my_action_name.ecr")
        end
        json { %({"status": "success", "message": "a success message."}) }
      end
    else
      respond_with do
        html do 
          flash[:danger] = "a danger message."
          render("view_name_for_this_action.ecr")
        end
        json { %({"status": "error", "message": "a danger message."}) }
      end
    end

    # Always rescue any errors, log them, and respond with an error message to the user.
    rescue e
      Log.error(e)
      respond_with do
        html do
          flash[:danger] = "a danger message."
          render("view_name_for_this_action.ecr")
        end
        json { %({"status": "error", "message": "a danger message."}) }
      end
    end
  end
end
```