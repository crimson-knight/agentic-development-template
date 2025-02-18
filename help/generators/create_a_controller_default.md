# Create A Controller

## Verify the necessary information is provided

Required:
- You have been provided with the name of the controller.

Optional:
- You have been given a list of the methods or routes that need to be implemented.
- You have been given the name of a resource to create a controller for.

If you do not have all of the required information, please ask the user for the missing information before continuing.

## Create The Necessary Files

1. Create the controller file in the `src/controllers` directory, 
    1a. It will be named the pluralized version of the resource name if a resource was provided `src/controllers/{namespace}/#{pluralized_resource_name}_controller.cr`
    1b. It will be named the controller name if no resource was provided `src/controllers/{namespace}/#{controller name}_controller.cr`
    1c. The controller will be namespaced to either `Authenticated` or `Public` depending on the route grouping or the action needing to be taken.
    1d. Creates a notes file that contains the summary of the details for this controller based on the requirements listed so far.
    1e. Based on the action feature story that was described, decide if the controller should be RESTful or non-RESTful.
    1f. If creating a RESTful controller, use the `help/generators/templates/restful_controller.md` file instructions and template, skip this step if creating a non-RESTful controller.
    1g. If creating a non-RESTful controller, use the `help/generators/templates/non_restful_controller.md` file instructions and template.

2. Create the route in the `config/routes.cr` file
    2a. If a resource is provided, the route will be namespaced to the resource using the `resources` method, under the `web` route grouping.
    2b. If no resource is provided, the route will be added using the `namespace` method, which accepts a block that contains the route defintions. Using the `get`, `post`, `put`, `patch`, or `delete` methods, defaulting to `get` if the user does not specify in the prompt.
    2c. If a route must be restricted to authenticated users, the route will be added to the `auth` route grouping. Authentication is already handled for all controllers in this route group, do not add a `before_action` to authenticate the user.
    2d. Using the rules from these steps, create a notes file and include notes about the specific details needed to update the routes file.
    2e. Using the instructions in the `help/generators/templates/routes.md` file, create the route in the `config/routes.cr` file.


3. Create the views in the `src/views/{{namespace}}/{{controller_name}}` directory
    3a. remind yourself of the controller information that you need from the notes file.
    3b. Using the template in the `help/generators/templates/restful_controller/views/` directory, create the views in the `src/views/{{namespace}}/{{controller_name}}` directory.
    3c. If you are creating a non-RESTful controller, use the `help/generators/templates/non_restful_controller/views/` directory, create the views in the `src/views/{{namespace}}/{{controller_name}}` directory.
    3d. The current user can be accessed by the controller using the `current_user` method.


4. Update  the navigation in the `src/views/layouts/_nav_.ecr` file to include a link to the index page of the controller
    4a. If a resource was _not_ provided, then skip to step 5.
    4b. Using the template in the `help/generators/templates/_nav.md` file, create the navigation in the `src/views/layouts/_nav_.ecr` file.

5. Inform the user that you have done the best you can on your first pass at this task, next they should ask you to review the controller documentation compared to the controller file you just created.