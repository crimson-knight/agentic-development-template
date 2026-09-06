---
name: controllers-and-endpoints
description: Comprehensive guide for working with AssetPipeline view components in src/controllers/** and routes in config/routes.cr
---

# How Controllers & Routing Work in Amber Applications

Amber is inspired by Rails in how it handles routing and endpoints. Each route is defined using the same patterns as a Rails app and then mapped to a controller in the src/controllers/** directory, the file ends with `_controller.cr`.

## Important Differences Between Rails & Amber

- Routes have `pipelines` which differentiate the kind of pre-processing the request goes through.

```crystal
# Example config/routes.cr
Amber::Server.configure do
  # Everything in the `web` pipeline renders HTML/JS views
  routes :web do
    # RESTful routes
    resources "/users", UsersController

    # Custom routes
    get "/users/:id/profile", UsersController, :profile
    post "/users/:id/avatar", UsersController, :update_avatar
    delete "/users/:id/avatar", UsersController, :remove_avatar
  end

  # Everything in the `api
  routes :api do
    resources "/users", Api::UsersController, only: [:index, :show, :create]
  end
end
```

## Schema's & Responses

Amber has a new built-in feature that lets us build schema's to validate the incoming requests and also build our OpenAPI specification for the application.

- Schema definitions should go in the same folder as the controller they belong to.

```crystal
# Users Controller demonstrating Schema API integration
require "../schemas/user_schemas"
require "../models/user"

class UsersController < Amber::Controller::Base
  include Amber::Schema::ControllerIntegration
  
  # POST /users
  # Create a new user with schema validation
  def create
    # Parse request body
    create_schema = Schemas::CreateUserSchema.new(request_body_hash)
    result = create_schema.validate
    
    if result.failure?
      return respond_with_errors(result.errors, 422)
    end
    
    # Create user (password would be hashed in real app)
    user_params = result.data.not_nil!.dup
    user_params.delete("password")
    user_params.delete("password_confirmation")
    
    user = Models::User.create(user_params)
    
    respond_with({"user" => user.to_h}, 201)
  end
```

# Schema definitions for user-related operations
# Demonstrates various Schema API features


```crystal
module Schemas
  # Schema for creating a new user
  class CreateUserSchema < Amber::Schema::Definition
    # Basic fields with validation
    field :email, String, required: true, format: "email"
    field :first_name, String, required: true, min_length: 2, max_length: 50
    field :last_name, String, required: true, min_length: 2, max_length: 50
    field :username, String, required: true, min_length: 3, max_length: 20, pattern: "^[a-zA-Z0-9_]+$"
    field :password, String, required: true, min_length: 8, max_length: 100
    field :password_confirmation, String, required: true
    
    # Optional fields with validation
    field :age, Int32, min: 13, max: 120
    field :phone, String, pattern: "^\\+?[1-9]\\d{1,14}$"  # E.164 format
    field :role, String, enum: ["user", "moderator", "admin"], default: "user"
    field :tags, Array(String), max_length: 10  # Max 10 tags
    
    # Nested object validation
    nested :address, AddressSchema
    nested :preferences, UserPreferencesSchema
    
    # Custom validation - passwords must match
    validate do |context|
      password = context.data["password"]?.try(&.as_s)
      confirmation = context.data["password_confirmation"]?.try(&.as_s)
      
      if password && confirmation && password != confirmation
        context.add_error(Amber::Schema::CustomValidationError.new(
          "password_confirmation",
          "Password confirmation does not match",
          "passwords_mismatch"
        ))
      end
    end
  end
```