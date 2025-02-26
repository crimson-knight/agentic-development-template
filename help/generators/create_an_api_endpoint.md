# Create An API Endpoint

## Prerequisites

Required:
- The name of the API resource
- The attributes of the resource with their types

Optional:
- Any relationships with other models
- Any specific validation requirements
- Any custom response formats

Review the information that you have been provided to ensure it includes all of the required information.
If there is any missing information or vague information, prompt the user for the missing information before proceeding.

## Steps

1. Create the model file using the process detailed in `help/generators/create_a_model.md`
   - Follow all the steps for creating a model as described in that document
   - Ensure the model includes all required attributes for the API endpoint

2. Create the API controller:
   - Use the controller creation process detailed in `help/generators/create_a_controller_default.md`
   - When creating the controller, specify that it should return JSON responses
   - Include all standard CRUD actions: index, show, create, update, and destroy

3. Update the routes in `config/routes.cr`:
   - Add the API resource to the appropriate route group (usually under the `:api` pipeline)
   - Use the `resources` macro to create all standard RESTful routes
   - For reference on routes, consult `help/generators/templates/routes.md`

## API-Specific Considerations

1. Response Format
   - API endpoints should return JSON responses
   - Use appropriate HTTP status codes for different situations
   - Include helpful error messages in responses

2. Authentication
   - Determine if authentication is required for the API endpoints
   - If required, add appropriate authentication middleware
   - For authenticated APIs, ensure proper error responses for unauthorized requests

3. API Documentation
   - Consider adding API documentation using tools like Swagger/OpenAPI
   - Document expected request and response formats
   - Include examples of successful and error responses 