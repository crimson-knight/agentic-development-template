# Creating Controllers with Grant Models

This guide helps create controllers that work with Grant ORM models and Gemma file uploads.

## Basic CRUD Controller

```crystal
class UsersController < ApplicationController
  # GET /users
  def index
    users = User.all
    render "index.ecr"
  end

  # GET /users/:id
  def show
    if user = User.find_by(id: params[:id])
      render "show.ecr"
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end

  # GET /users/new
  def new
    user = User.new
    render "new.ecr"
  end

  # POST /users
  def create
    user = User.new(user_params)

    if user.save
      redirect_to "/users/#{user.id}", flash: {"success" => "User created!"}
    else
      flash.now["error"] = user.errors.full_messages.join(", ")
      render "new.ecr"
    end
  end

  # GET /users/:id/edit
  def edit
    if user = User.find_by(id: params[:id])
      render "edit.ecr"
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end

  # PATCH /users/:id
  def update
    if user = User.find_by(id: params[:id])
      if user.update(user_params)
        redirect_to "/users/#{user.id}", flash: {"success" => "User updated!"}
      else
        flash.now["error"] = user.errors.full_messages.join(", ")
        render "edit.ecr"
      end
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end

  # DELETE /users/:id
  def destroy
    if user = User.find_by(id: params[:id])
      user.destroy
      redirect_to "/users", flash: {"success" => "User deleted!"}
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end

  private def user_params
    params.validation do
      required(:email) { |v| v.email? }
      required(:first_name) { |v| v.str? && !v.str.empty? }
      required(:last_name) { |v| v.str? && !v.str.empty? }
      optional(:bio) { |v| v.str? }
    end
  end
end
```

## Controller with File Uploads

```crystal
class UsersController < ApplicationController
  # POST /users
  def create
    user = User.new(user_params)

    # Handle single file upload
    if avatar = params.files["avatar"]?
      user.avatar = avatar.file
    end

    # Handle multiple file uploads
    if documents = params.files.get_all("documents")
      user.documents = documents.map(&.file)
    end

    if user.save
      redirect_to "/users/#{user.id}", flash: {"success" => "User created!"}
    else
      flash.now["error"] = user.errors.full_messages.join(", ")
      render "new.ecr"
    end
  end

  # PATCH /users/:id
  def update
    if user = User.find_by(id: params[:id])
      user.assign_attributes(user_params)

      # Handle file upload
      if avatar = params.files["avatar"]?
        user.avatar = avatar.file
      end

      # Remove file if checkbox is checked
      if params["remove_avatar"]? == "1"
        user.avatar.destroy if user.avatar
        user.avatar_data = nil
      end

      if user.save
        redirect_to "/users/#{user.id}", flash: {"success" => "User updated!"}
      else
        flash.now["error"] = user.errors.full_messages.join(", ")
        render "edit.ecr"
      end
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end

  private def user_params
    params.validation do
      required(:email) { |v| v.email? }
      required(:first_name) { |v| v.str? && !v.str.empty? }
      required(:last_name) { |v| v.str? && !v.str.empty? }
      optional(:bio) { |v| v.str? }
    end
  end
end
```

## Controller with Query Scopes

```crystal
class UsersController < ApplicationController
  # GET /users?status=active&role=admin
  def index
    users = User.all

    # Apply scopes based on params
    users = users.active if params["status"]? == "active"
    users = users.admins if params["role"]? == "admin"
    users = users.created_after(7.days.ago) if params["recent"]?

    # Pagination
    page = (params["page"]? || "1").to_i
    per_page = 20
    users = users.limit(per_page).offset((page - 1) * per_page)

    render "index.ecr"
  end
end
```

## API Controller with JSON Responses

```crystal
class Api::UsersController < ApplicationController
  # GET /api/users
  def index
    users = User.all.limit(100)

    render json: {
      users: users.map { |u| user_json(u) }
    }
  end

  # GET /api/users/:id
  def show
    if user = User.find_by(id: params[:id])
      render json: user_json(user)
    else
      render json: {error: "User not found"}, status: 404
    end
  end

  # POST /api/users
  def create
    user = User.new(user_params)

    if user.save
      render json: user_json(user), status: 201
    else
      render json: {errors: user.errors.messages}, status: 422
    end
  end

  private def user_json(user)
    {
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      avatar_url: user.avatar_url,
      created_at: user.created_at
    }
  end

  private def user_params
    params.validation do
      required(:email) { |v| v.email? }
      required(:first_name) { |v| v.str? && !v.str.empty? }
      required(:last_name) { |v| v.str? && !v.str.empty? }
    end
  end
end
```

## Controller with Transactions

```crystal
class OrdersController < ApplicationController
  # POST /orders
  def create
    Grant::Base.transaction do
      # Create order
      order = Order.new(order_params)
      order.user_id = current_user.id
      order.save!

      # Create line items
      params["items"].each do |item_data|
        line_item = LineItem.new(
          order_id: order.id,
          product_id: item_data["product_id"],
          quantity: item_data["quantity"]
        )
        line_item.save!
      end

      # Update inventory
      order.line_items.each do |item|
        product = Product.find(item.product_id)
        product.decrement!(:inventory_count, item.quantity)
      end

      redirect_to "/orders/#{order.id}", flash: {"success" => "Order created!"}
    end
  rescue ex
    flash["error"] = "Failed to create order: #{ex.message}"
    render "new.ecr"
  end
end
```

## Routes Configuration

```crystal
# config/routes.cr
Amber::Server.configure do
  routes :web do
    # RESTful routes
    resources "/users", UsersController

    # Custom routes
    get "/users/:id/profile", UsersController, :profile
    post "/users/:id/avatar", UsersController, :update_avatar
    delete "/users/:id/avatar", UsersController, :remove_avatar
  end

  routes :api do
    resources "/users", Api::UsersController, only: [:index, :show, :create]
  end
end
```

## Complete Example

See `src/controllers/users_controller.cr` for a comprehensive example with:
- All CRUD actions
- File upload handling
- File removal
- Error handling with flash messages
- Grant query methods
- Amber params validation

## Next Steps

1. Create views: See `src/views/` for examples
2. Add JavaScript interactivity: See `src/javascript/controllers/`
3. Test your controller
4. Add routes in `config/routes.cr`
