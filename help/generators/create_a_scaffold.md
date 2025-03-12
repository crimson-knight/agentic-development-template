# Create A Scaffold

## Prerequisites

Required:
- The name of the resource to scaffold
- The attributes of the resource with their types

Optional:
- Any relationships with other models
- Any specific validation requirements
- Custom UI requirements
- Authorization requirements

Review the information that you have been provided to ensure it includes all of the required information.
If there is any missing information or vague information, prompt the user for the missing information before proceeding.

## Steps

1. Create the model file using the process detailed in `help/generators/create_a_model.md`
   - Follow all the steps for creating a model as described in that document
   - Ensure the model includes all required attributes for the scaffolded resource
   - Add any necessary relationships and validations

2. Create the controller using the process detailed in `help/generators/create_a_controller_default.md`
   - When creating the controller, specify that it should be a RESTful controller
   - Ensure all standard CRUD actions are included (index, show, new, create, edit, update, destroy)
   - Include appropriate error handling and flash messages

3. Create the views in the appropriate directory structure
   - Create the index, show, new, edit views, and _form partial
   - Use the templates in `help/generators/templates/create_a_scaffold/`
   - Customize the views based on the resource attributes

4. Update the navigation in `src/views/layouts/_nav.ecr`
   - Add a link to the resource index page in the navigation
   - Use the pattern in `help/generators/templates/_nav.md`

## View Templates

Scaffold generators create the following view templates:

1. **Index View** - Lists all instances of the resource with actions
2. **Show View** - Displays details of a single resource instance
3. **New View** - Provides a form to create a new resource instance
4. **Edit View** - Provides a form to update an existing resource instance
5. **Form Partial** - Shared form used by both new and edit views

For specific implementation details of these views, see the templates in `help/generators/templates/create_a_scaffold/`.

## Common Customization Points

1. Views
   - Customize form layouts based on attribute types
   - Add client-side validations
   - Enhance table displays with sorting and filtering
   - Implement pagination for large datasets

2. Controller
   - Add authentication and authorization checks
   - Customize redirect behaviors
   - Add search functionality
   - Implement more complex business logic

3. Routes
   - Add custom resource routes
   - Configure route constraints
   - Implement nested resources
``` 